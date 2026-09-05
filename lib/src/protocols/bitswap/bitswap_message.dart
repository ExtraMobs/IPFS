import 'dart:typed_data';

import 'package:ipfs_libp2p/core/network/stream.dart';
import 'package:transpiled_block_format/transpiled_block_format.dart' as blocks;
import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_varint/transpiled_varint.dart';

/// Maximum libp2p message size, matching go-libp2p `MessageSizeMax`.
const int bitswapMessageSizeMax = 1 << 22;

/// Creates a varint-framed Bitswap `WANT_BLOCK` message.
Uint8List encodeWantBlock(CID cid, {int priority = 1}) {
  final entry = BytesBuilder()
    ..add(_bytesField(1, cid.toBytes()))
    ..add(_varintField(2, priority))
    ..add(_varintField(5, 1));
  final wantlist = _bytesField(1, entry.takeBytes());
  final message = _bytesField(1, wantlist);
  if (message.length > bitswapMessageSizeMax) {
    throw const FormatException('Bitswap message exceeds 4 MiB');
  }
  return Uint8List.fromList([...encodeVarint(message.length), ...message]);
}

/// Reads one varint-framed Bitswap protobuf message.
Future<BitswapMessage> readBitswapMessage(P2PStream<dynamic> stream) async {
  var length = 0;
  var shift = 0;
  for (var index = 0; index < 10; index++) {
    final byte = await _readExactly(stream, 1);
    length |= (byte.single & 0x7f) << shift;
    if ((byte.single & 0x80) == 0) {
      if (length > bitswapMessageSizeMax) {
        throw const FormatException('Bitswap message exceeds 4 MiB');
      }
      return BitswapMessage.fromBytes(await _readExactly(stream, length));
    }
    shift += 7;
  }
  throw const FormatException('Bitswap frame length varint is too long');
}

/// Wire fields relevant to the download side of a Bitswap message.
final class BitswapMessage {
  BitswapMessage._(this.payload, this.legacyBlocks, this.dontHaves);

  /// Decodes the Boxo protobuf message used on Bitswap streams.
  factory BitswapMessage.fromBytes(Uint8List bytes) {
    final payload = <({Uint8List prefix, Uint8List data})>[];
    final legacy = <Uint8List>[];
    final dontHaves = <CID>[];
    final reader = _ProtoReader(bytes);
    while (!reader.isDone) {
      final (field, wire) = reader.tag();
      if (field == 2 && wire == 2) {
        legacy.add(reader.bytes());
      } else if (field == 3 && wire == 2) {
        final block = _ProtoReader(reader.bytes());
        var prefix = Uint8List(0);
        var data = Uint8List(0);
        while (!block.isDone) {
          final (blockField, blockWire) = block.tag();
          if (blockField == 1 && blockWire == 2) {
            prefix = block.bytes();
          } else if (blockField == 2 && blockWire == 2) {
            data = block.bytes();
          } else {
            block.skip(blockWire);
          }
        }
        payload.add((prefix: prefix, data: data));
      } else if (field == 4 && wire == 2) {
        final presence = _ProtoReader(reader.bytes());
        Uint8List? cidBytes;
        var type = 0;
        while (!presence.isDone) {
          final (presenceField, presenceWire) = presence.tag();
          if (presenceField == 1 && presenceWire == 2) {
            cidBytes = presence.bytes();
          } else if (presenceField == 2 && presenceWire == 0) {
            type = presence.varint();
          } else {
            presence.skip(presenceWire);
          }
        }
        if (type == 1 && cidBytes != null) {
          dontHaves.add(CID.fromBytes(cidBytes));
        }
      } else {
        reader.skip(wire);
      }
    }
    return BitswapMessage._(payload, legacy, dontHaves);
  }

  /// Blocks encoded by Bitswap 1.1 and newer.
  final List<({Uint8List prefix, Uint8List data})> payload;

  /// Legacy Bitswap 1.0 block bytes.
  final List<Uint8List> legacyBlocks;

  /// CIDs explicitly reported as unavailable.
  final List<CID> dontHaves;
}

/// Extracts and validates a requested block from a decoded message.
blocks.Block? blockFromMessage(BitswapMessage message, CID requested) {
  for (final payload in message.payload) {
    final cid = Prefix.fromBytes(payload.prefix).sum(payload.data);
    if (cid == requested) return blocks.BasicBlock(payload.data, cid);
  }
  for (final data in message.legacyBlocks) {
    final block = blocks.newBlock(data);
    if (block.cid() == requested) return block;
  }
  if (message.dontHaves.contains(requested)) {
    throw StateError('Bitswap provider does not have $requested');
  }
  return null;
}

Uint8List _bytesField(int field, Uint8List value) => Uint8List.fromList([
  ...encodeVarint((field << 3) | 2),
  ...encodeVarint(value.length),
  ...value,
]);

Uint8List _varintField(int field, int value) =>
    Uint8List.fromList([...encodeVarint(field << 3), ...encodeVarint(value)]);

Future<Uint8List> _readExactly(P2PStream<dynamic> stream, int length) async {
  final output = BytesBuilder(copy: false);
  while (output.length < length) {
    final chunk = await stream.read(length - output.length);
    if (chunk.isEmpty) {
      throw const FormatException('Unexpected EOF in Bitswap frame');
    }
    output.add(chunk);
  }
  return output.takeBytes();
}

final class _ProtoReader {
  _ProtoReader(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;

  bool get isDone => _offset == _bytes.length;

  (int, int) tag() {
    final value = varint();
    final field = value >> 3;
    if (field == 0) throw const FormatException('Invalid protobuf field 0');
    return (field, value & 7);
  }

  int varint() {
    final (value, length) = readVarint(_bytes, _offset);
    _offset += length;
    return value;
  }

  Uint8List bytes() {
    final length = varint();
    final end = _offset + length;
    if (end > _bytes.length) {
      throw const FormatException('Truncated protobuf bytes field');
    }
    final value = Uint8List.sublistView(_bytes, _offset, end);
    _offset = end;
    return value;
  }

  void skip(int wire) {
    switch (wire) {
      case 0:
        varint();
        return;
      case 1:
        _advance(8);
        return;
      case 2:
        _advance(varint());
        return;
      case 5:
        _advance(4);
        return;
      default:
        throw FormatException('Unsupported protobuf wire type $wire');
    }
  }

  void _advance(int length) {
    _offset += length;
    if (_offset > _bytes.length) {
      throw const FormatException('Truncated protobuf field');
    }
  }
}
