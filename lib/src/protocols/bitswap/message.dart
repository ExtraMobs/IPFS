import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dart_multihash/dart_multihash.dart';
import 'package:transpiled_ipfs/src/core/cid.dart';
import 'package:transpiled_ipfs/src/core/data_structures/block.dart' show Block;
import 'package:transpiled_ipfs/src/proto/generated/bitswap/bitswap.pb.dart'
    as pb;
import 'package:transpiled_ipfs/src/utils/logger.dart';
import 'package:transpiled_ipfs/src/utils/varint.dart';
import 'package:transpiled_multicodec/transpiled_multicodec.dart';
import 'package:transpiled_multihash/transpiled_multihash.dart';
import 'package:transpiled_varint/transpiled_varint.dart' as varint;

/// Represents a Bitswap protocol message.
///
/// A message can contain a wantlist, data blocks, and block presence
/// notifications (HAVE/DONT_HAVE).
class Message {
  /// Creates an empty message.
  Message({this.full = false});

  /// The libp2p maximum framed message size used by Bitswap.
  static const int maxMessageSize = 1 << 22;

  /// Whether this message's wantlist is an authoritative full wantlist.
  ///
  /// This is the `Message_Wantlist.full` field from the Bitswap protobuf.
  final bool full;

  /// List of blocks being sent (Payload)
  final List<Block> _blocks = [];

  /// The wantlist containing requested blocks
  final Wantlist _wantlist = Wantlist();

  /// Block presences for HAVE/DONT_HAVE responses
  final List<BlockPresence> _blockPresences = [];

  /// Logger for Message parsing errors
  static final Logger _logger = Logger('BitswapMessage');

  /// Transient field: The peer ID of the sender (not part of wire protocol)
  String? from;

  /// Transient field: Pending bytes (Bitswap 1.2)
  int pendingBytes = 0;

  /// Adds a block to the message payload.
  void addBlock(Block block) {
    final index = _blocks.indexWhere((existing) => existing.cid == block.cid);
    if (index == -1) {
      _blocks.add(block);
    } else {
      _blocks[index] = block;
    }
    _blockPresences.removeWhere(
      (presence) => presence.cid == block.cid.encode(),
    );
  }

  /// Returns an unmodifiable list of blocks.
  List<Block> getBlocks() => List.unmodifiable(_blocks);

  /// Adds a wantlist entry for a CID.
  void addWantlistEntry(
    String cid, {
    int priority = 1,
    bool cancel = false,
    WantType wantType = WantType.block,
    bool sendDontHave = false,
  }) {
    final old = _wantlist.entries[cid];
    if (old == null) {
      _wantlist.addEntry(
        WantlistEntry(
          cid: cid,
          priority: priority,
          cancel: cancel,
          wantType: wantType,
          sendDontHave: sendDontHave,
        ),
      );
      return;
    }

    _wantlist.addEntry(
      WantlistEntry(
        cid: cid,
        priority: old.wantType == wantType ? priority : old.priority,
        cancel: old.cancel || cancel,
        wantType: old.wantType == WantType.have && wantType == WantType.block
            ? WantType.block
            : old.wantType,
        sendDontHave: old.sendDontHave || sendDontHave,
      ),
    );
  }

  /// Returns the message wantlist.
  Wantlist getWantlist() => _wantlist;

  /// Adds a block presence notification.
  void addBlockPresence(String cid, BlockPresenceType type) {
    if (_blocks.any((block) => block.cid.encode() == cid)) return;
    final presence = BlockPresence(cid: cid, type: type);
    final index = _blockPresences.indexWhere((existing) => existing.cid == cid);
    if (index == -1) {
      _blockPresences.add(presence);
    } else {
      _blockPresences[index] = presence;
    }
  }

  /// Returns an unmodifiable list of block presences.
  List<BlockPresence> getBlockPresences() => List.unmodifiable(_blockPresences);

  /// Returns true if this message contains blocks.
  bool hasBlocks() => _blocks.isNotEmpty;

  /// Returns true if this message has wantlist entries.
  bool hasWantlist() => _wantlist.entries.isNotEmpty;

  /// Returns true if this message has block presence notifications.
  bool hasBlockPresences() => _blockPresences.isNotEmpty;

  /// Creates a Message from its protobuf byte representation.
  ///
  /// Throws an error if the bytes cannot be parsed as a valid Bitswap message.
  static Future<Message> fromBytes(Uint8List bytes) async {
    if (bytes.length > maxMessageSize) {
      throw const FormatException('Bitswap message exceeds 4 MiB limit');
    }
    final pbMessage = pb.Message.fromBuffer(bytes);
    final message = Message(
      full: pbMessage.hasWantlist() && pbMessage.wantlist.full,
    );

    // Parse pending bytes
    message.pendingBytes = pbMessage.pendingBytes;

    // Parse wantlist
    if (pbMessage.hasWantlist()) {
      for (var entry in pbMessage.wantlist.entries) {
        try {
          final cidObj = _decodeCid(entry.block, 'wantlist entry');
          final cidStr = cidObj.encode();

          final wantType = entry.wantType == pb.Message_Wantlist_WantType.Have
              ? WantType.have
              : WantType.block;

          message.addWantlistEntry(
            cidStr,
            priority: entry.priority,
            cancel: entry.cancel,
            wantType: wantType,
            sendDontHave: entry.sendDontHave,
          );
        } catch (e) {
          throw FormatException('Invalid wantlist entry CID: $e');
        }
      }
    }

    // Parse blocks (Payload - 1.1+)
    // Bitswap 1.1+ blocks carry a prefix: <cidVersion><codec><mhType><mhLen>
    // as unsigned varints. Use the prefix to reconstruct the original CID so
    // that CID format (v0/v1) matches what was requested.
    for (var payloadBlock in pbMessage.payload) {
      try {
        final data = Uint8List.fromList(payloadBlock.data);
        final prefix = payloadBlock.prefix;
        if (prefix.isEmpty) {
          throw const FormatException('Missing CID prefix in payload block');
        }
        final cid = _cidFromPrefixAndData(prefix, data);
        message.addBlock(
          Block(cid: cid, data: data, format: cid.codec ?? 'raw'),
        );
      } catch (e) {
        throw FormatException('Invalid payload block: $e');
      }
    }

    // Parse legacy blocks (1.0)
    for (var blockBytes in pbMessage.blocks) {
      try {
        final data = Uint8List.fromList(blockBytes);
        final digest = Uint8List.fromList(sha256.convert(data).bytes);
        final newBlock = Block(
          cid: CID.v0(digest),
          data: data,
          format: 'dag-pb',
        );
        message.addBlock(newBlock);
      } catch (e) {
        throw FormatException('Invalid legacy block: $e');
      }
    }

    // Parse block presences
    for (var pres in pbMessage.blockPresences) {
      try {
        final cidObj = _decodeCid(pres.cid, 'block presence');
        final type = pres.type == pb.Message_BlockPresence_Type.DontHave
            ? BlockPresenceType.dontHave
            : BlockPresenceType.have;
        message.addBlockPresence(cidObj.encode(), type);
      } catch (e) {
        throw FormatException('Invalid block presence CID: $e');
      }
    }

    return message;
  }

  /// Converts the message to its protobuf byte representation.
  Uint8List toBytes() {
    final pbMessage = pb.Message();

    if (pendingBytes != 0) pbMessage.pendingBytes = pendingBytes;

    // Go's ToProtoV1 always emits a wantlist, even when it is empty.
    final pbWantlist = pb.Message_Wantlist();
    if (full) pbWantlist.full = true;
    for (var entry in _wantlist.entries.values) {
      final pbEntry = pb.Message_Wantlist_Entry();
      try {
        final cidObj = CID.decode(entry.cid);
        pbEntry.block = cidObj.toBytes();
        if (entry.priority != 0) pbEntry.priority = entry.priority;
        if (entry.cancel) pbEntry.cancel = true;
        if (entry.sendDontHave) pbEntry.sendDontHave = true;
        if (entry.wantType == WantType.have) {
          pbEntry.wantType = pb.Message_Wantlist_WantType.Have;
        }

        pbWantlist.entries.add(pbEntry);
      } catch (e, st) {
        _logger.error('Skipping invalid CID in wantlist: ${entry.cid}', e, st);
      }
    }
    pbMessage.wantlist = pbWantlist;

    // Add blocks (Payload)
    for (var block in _blocks) {
      final pbBlock = pb.Message_Block();
      pbBlock.data = block.data;

      pbBlock.prefix = _prefixBytes(block.cid);

      pbMessage.payload.add(pbBlock);
    }

    // Add block presences
    for (var pres in _blockPresences) {
      try {
        final cidObj = CID.decode(pres.cid);
        final pbPres = pb.Message_BlockPresence();
        pbPres.cid = cidObj.toBytes();
        if (pres.type == BlockPresenceType.dontHave) {
          pbPres.type = pb.Message_BlockPresence_Type.DontHave;
        }
        pbMessage.blockPresences.add(pbPres);
      } catch (e, st) {
        _logger.error(
          'Skipping invalid CID in block presence: ${pres.cid}',
          e,
          st,
        );
      }
    }

    return pbMessage.writeToBuffer();
  }
}

/// Reconstructs a CID from a Bitswap block prefix and data.
///
/// Prefix format: `<cidVersion><codec><mhType><mhLen>` as unsigned varints.
CID _cidFromPrefixAndData(List<int> prefix, Uint8List data) {
  final bytes = Uint8List.fromList(prefix);
  var offset = 0;

  int next() {
    final value = varint.readVarint(bytes, offset);
    offset += value.$2;
    return value.$1;
  }

  final version = next();
  final codecCode = next();
  final mhType = next();
  final mhLength = next();
  final hashName = _multihashName(mhType);

  if (version == 0) {
    if (codecCode != 0x70 || mhType != 0x12 || mhLength != 32) {
      throw const FormatException('Invalid CIDv0 Bitswap prefix');
    }
    return CID.v0(
      Uint8List.fromList(MultihashUtils.sum(hashName, data).digest),
    );
  }
  if (version != 1) {
    throw FormatException('Unsupported CID version $version in Bitswap prefix');
  }

  final digest = MultihashUtils.sum(hashName, data).digest;
  if (mhType != 0 && mhLength > digest.length) {
    throw FormatException(
      'Invalid multihash length $mhLength in Bitswap prefix',
    );
  }
  if (!Multicodec.supportsByCode(codecCode)) {
    throw FormatException('Unsupported codec 0x${codecCode.toRadixString(16)}');
  }
  // go-cid's Prefix.Sum intentionally ignores MhLength for identity hashes;
  // go-multihash always uses the complete data as the digest in that case.
  final encodedDigest = mhType == 0
      ? Uint8List.fromList(digest)
      : Uint8List.fromList(digest.sublist(0, mhLength));
  return CID.v1(
    Multicodec.name(codecCode),
    Multihash.encode(hashName, encodedDigest),
  );
}

CID _decodeCid(List<int> bytes, String field) {
  if (bytes.isEmpty) throw FormatException('Missing CID in $field');
  final raw = Uint8List.fromList(bytes);
  final cid = CID.fromBytes(raw);

  // CID.fromBytes is permissive for historical callers and may stop after a
  // complete CID. go-cid's cid.Cast, used by Boxo, rejects trailing bytes.
  if (cid.version == 0) {
    if (raw.length != 34) {
      throw FormatException('Trailing bytes in $field CID');
    }
  } else {
    var offset = 1;
    var value = varint.readVarint(raw, offset);
    offset += value.$2;
    value = varint.readVarint(raw, offset);
    offset += value.$2;
    value = varint.readVarint(raw, offset);
    offset += value.$2;
    if (offset + value.$1 != raw.length) {
      throw FormatException('Trailing bytes in $field CID');
    }
  }
  return cid;
}

Uint8List _prefixBytes(CID cid) {
  final codec = cid.version == 0 ? 0x70 : Multicodec.code(cid.codec ?? 'raw');
  final hashCode = Multicodec.code(cid.multihash.name);
  final builder = BytesBuilder()
    ..add(encodeVarint(cid.version))
    ..add(encodeVarint(codec))
    ..add(encodeVarint(hashCode))
    ..add(encodeVarint(cid.multihash.size));
  return builder.toBytes();
}

String _multihashName(int code) {
  const names = {
    0x00: 'identity',
    0x11: 'sha1',
    0x12: 'sha2-256',
    0x13: 'sha2-512',
    0x14: 'sha3-512',
    0x15: 'sha3-384',
    0x16: 'sha3-256',
    0x17: 'sha3-224',
    0x1a: 'keccak-224',
    0x1b: 'keccak-256',
    0x1c: 'keccak-384',
    0x1d: 'keccak-512',
    0x56: 'dbl-sha2-256',
    0xd5: 'md5',
  };
  final name = names[code];
  if (name == null) {
    throw UnsupportedError(
      'Unsupported multihash type 0x${code.toRadixString(16)}',
    );
  }
  return name;
}

/// The type of block request.
enum WantType {
  /// Request the full block data.
  block,

  /// Request only whether the peer has the block.
  have,
}

/// Block presence response type.
enum BlockPresenceType {
  /// Peer has the block.
  have,

  /// Peer does not have the block.
  dontHave,
}

/// An entry in a Bitswap wantlist.
class WantlistEntry {
  /// Creates a wantlist entry.
  WantlistEntry({
    required this.cid,
    this.priority = 1,
    this.cancel = false,
    this.wantType = WantType.block,
    this.sendDontHave = false,
  });

  /// The CID being requested.
  final String cid;

  /// Priority for this request (higher = more urgent).
  final int priority;

  /// Whether this cancels a previous request.
  final bool cancel;

  /// The type of request (block or have).
  final WantType wantType;

  /// Whether to send DONT_HAVE if the peer lacks the block.
  final bool sendDontHave;
}

/// Manages a set of wantlist entries by CID.
class Wantlist {
  /// Map of CID to wantlist entry.
  final Map<String, WantlistEntry> entries = {};

  /// Adds or updates an entry.
  void addEntry(WantlistEntry entry) {
    entries[entry.cid] = entry;
  }

  /// Removes an entry by CID.
  void removeEntry(String cid) {
    entries.remove(cid);
  }

  /// Returns whether the wantlist contains a CID.
  bool contains(String cid) => entries.containsKey(cid);
}

/// A block presence notification (HAVE or DONT_HAVE).
class BlockPresence {
  /// Creates a block presence.
  BlockPresence({required this.cid, required this.type});

  /// The CID this presence is for.
  final String cid;

  /// The presence type.
  final BlockPresenceType type;
}
