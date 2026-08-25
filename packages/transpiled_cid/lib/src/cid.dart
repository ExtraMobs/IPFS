// lib/src/cid/cid.dart
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:multibase/multibase.dart' as mb;

import 'package:transpiled_multibase/transpiled_multibase.dart';
import 'package:transpiled_multicodec/transpiled_multicodec.dart';
import 'package:transpiled_multihash/transpiled_multihash.dart';
import 'package:transpiled_varint/transpiled_varint.dart';

/// A Content Identifier (CID) for content-addressed data in IPFS.
///
/// CIDs are self-describing content addresses that combine a cryptographic hash
/// of the content with metadata about the hashing algorithm and data encoding.
///
/// - **CIDv0**: legacy format, always SHA2-256 + DAG-PB, base58btc encoded.
/// - **CIDv1**: modern format with flexible codecs and multibase encoding.
///
/// Example:
/// ```dart
/// final data = Uint8List.fromList(utf8.encode('Hello IPFS'));
/// final cid = await CID.fromContent(data);
/// print(cid.encode()); // bafkrei...
/// ```
class CID {
  /// Creates a CID with the specified components.
  const CID({
    required this.version,
    required this.multihash,
    this.codec,
    this.multibaseType,
  });

  /// Creates a CIDv0 from a 32-byte SHA2-256 hash.
  factory CID.v0(Uint8List hashBytes) {
    if (hashBytes.length != 32) {
      throw ArgumentError('CIDv0 requires a 32-byte SHA2-256 hash');
    }
    return CID(
      version: 0,
      multihash: MultihashUtils.sha256(hashBytes),
      codec: 'dag-pb',
      multibaseType: mb.Multibase.base58btc,
    );
  }

  /// Creates a CIDv1 from a codec name and a multihash info.
  factory CID.v1(
    String codec,
    MultihashInfo multihash, {
    mb.Multibase base = mb.Multibase.base32,
  }) {
    return CID(
      version: 1,
      codec: codec,
      multihash: multihash,
      multibaseType: base,
    );
  }

  /// Creates a CID by hashing [data].
  ///
  /// [codec] defaults to `raw` and is ignored when [version] is 0 (always
  /// `dag-pb`, per the CIDv0 spec). [hashType] defaults to `sha2-256`; no
  /// other hash function is currently supported.
  static Future<CID> fromContent(
    Uint8List data, {
    String codec = 'raw',
    String hashType = 'sha2-256',
    int version = 1,
  }) async {
    if (hashType != 'sha2-256') {
      throw UnsupportedError('Hash type $hashType not supported');
    }
    final digest = Uint8List.fromList(sha256.convert(data).bytes);
    if (version == 0) {
      return CID.v0(digest);
    }
    final mh = MultihashUtils.sha256(digest);
    return CID.v1(codec, mh);
  }

  /// Computes a CID for [data] (async convenience wrapper over
  /// [fromContent], kept for API parity with call sites that expect this
  /// name).
  static Future<CID> computeForData(Uint8List data, {String format = 'raw'}) {
    return fromContent(data, codec: format);
  }

  /// Computes a CID for [data] synchronously (SHA2-256, CIDv1 only).
  ///
  /// Prefer [fromContent] when `hashType`/`version` flexibility or async
  /// hashing is needed; this exists for call sites that cannot await.
  static CID computeForDataSync(Uint8List data, {String codec = 'raw'}) {
    final digest = Uint8List.fromList(sha256.convert(data).bytes);
    final mh = MultihashUtils.sha256(digest);
    return CID.v1(codec, mh);
  }

  /// Reconstructs a CID from a [prefix] (version + codec + multihash
  /// function + hash length) and the raw block [data].
  ///
  /// The digest is computed from [data] using [hashType]; the codec comes
  /// from [prefix], not from [data]'s content. Used by Bitswap/GraphSync to
  /// let a receiver reconstruct a CID from [Block.toPrefixBytes] plus the
  /// block bytes.
  static Future<CID> fromPrefixBytes(
    Uint8List prefix,
    Uint8List data, {
    String hashType = 'sha2-256',
  }) async {
    final codec = _codecFromPrefixBytes(prefix);
    return fromContent(data, codec: codec, hashType: hashType);
  }

  static String _codecFromPrefixBytes(Uint8List prefix) {
    if (prefix.isEmpty) return 'raw';
    if (prefix[0] == 0x01) {
      final (codecCode, _) = readVarint(prefix, 1);
      return Multicodec.supportsByCode(codecCode)
          ? Multicodec.name(codecCode)
          : 'unknown';
    }
    // CIDv0 is always dag-pb.
    return 'dag-pb';
  }

  /// Parses a CID from its raw binary representation.
  static CID fromBytes(Uint8List bytes) {
    if (bytes.isEmpty) throw ArgumentError('Empty bytes');

    // CIDv0: 34 bytes starting with 0x12 0x20 (sha2-256, 32-byte digest)
    if (bytes.length >= 34 && bytes[0] == 0x12 && bytes[1] == 0x20) {
      return CID(
        version: 0,
        multihash: MultihashUtils.decode(bytes.sublist(0, 34)),
        codec: 'dag-pb',
        multibaseType: mb.Multibase.base58btc,
      );
    }

    // CIDv1: first byte is 0x01
    if (bytes[0] == 0x01) {
      var index = 1;
      final (codecCode, codecLen) = readVarint(bytes, index);
      index += codecLen;

      final mhStart = index;
      final (hashCode, codeLen) = readVarint(bytes, index);
      index += codeLen;
      final (digestLen, lenLen) = readVarint(bytes, index);
      index += lenLen;
      final mhEnd = index + digestLen;
      if (mhEnd > bytes.length) {
        throw const FormatException('Invalid CID bytes: multihash truncated');
      }
      final mh = MultihashUtils.decode(bytes.sublist(mhStart, mhEnd));

      final codecStr = Multicodec.supportsByCode(codecCode)
          ? Multicodec.name(codecCode)
          : 'unknown';

      return CID(
        version: 1,
        multihash: mh,
        codec: codecStr,
        multibaseType: mb.Multibase.base32,
      );
    }

    throw const FormatException('Invalid CID version');
  }

  /// Decodes a CID from its string representation.
  static CID decode(String cidStr) {
    if (cidStr.isEmpty) {
      throw ArgumentError('Empty CID string');
    }

    if (cidStr.startsWith('Qm')) {
      // CIDv0 is base58btc without the multibase prefix character.
      final decoded = MultibaseUtils.decode('z$cidStr');
      return fromBytes(decoded);
    }

    final decoded = MultibaseUtils.decode(cidStr);
    return fromBytes(decoded);
  }

  /// The CID version (0 or 1).
  final int version;

  /// The multihash containing the hash algorithm and digest.
  final MultihashInfo multihash;

  /// The content codec (e.g., 'dag-pb', 'raw', 'dag-cbor').
  final String? codec;

  /// The multibase encoding type for string representation.
  final mb.Multibase? multibaseType;

  /// Encodes the CID to its string representation.
  String encode() => encodeWithBase(multibaseType);

  /// Encodes the CID using the requested [base].
  ///
  /// CIDv0 is always returned as base58btc regardless of the requested base.
  /// CIDv1 defaults to base32 when [base] is null.
  String encodeWithBase(mb.Multibase? base) {
    if (version == 0) {
      final mhBytes = multihash.toBytes();
      final encoded = MultibaseUtils.encode(mb.Multibase.base58btc, mhBytes);
      return encoded.substring(1);
    }

    final bytes = toBytes();
    final baseType = base ?? multibaseType ?? mb.Multibase.base32;
    return MultibaseUtils.encode(baseType, bytes);
  }

  /// Encodes the CID using the base identified by [baseName].
  String encodeWithBaseName(String baseName) {
    final base = _multibaseFromName(baseName);
    return encodeWithBase(base);
  }

  /// Returns the raw binary representation of the CID.
  Uint8List toBytes() {
    if (version == 0) {
      return multihash.toBytes();
    }

    final builder = BytesBuilder();
    builder.addByte(0x01);
    int codecCode;
    try {
      codecCode = Multicodec.code(codec ?? 'raw');
    } catch (_) {
      // Multicodec.code throws ArgumentError; callers of this API expect
      // FormatException for CID-encoding-shaped failures (matches the
      // umbrella CID's pre-Phase-2 behavior).
      throw FormatException('Unsupported codec during CID encoding: $codec');
    }
    builder.add(encodeVarint(codecCode));
    builder.add(multihash.toBytes());
    return builder.toBytes();
  }

  /// Returns the CID prefix bytes (version + codec + multihash function + hash
  /// length), omitting the digest itself.
  Uint8List toPrefixBytes() {
    final bytes = toBytes();
    final digestLength = multihash.size;
    if (bytes.length <= digestLength) {
      return bytes;
    }
    return Uint8List.fromList(bytes.sublist(0, bytes.length - digestLength));
  }

  /// This CID's shape -- version, codec, hash function, and hash length --
  /// without the digest content. Equivalent to go-cid's `Cid.Prefix()`.
  Prefix get prefix => Prefix(
    version: version,
    codec: version == 0 ? 'dag-pb' : (codec ?? 'raw'),
    mhType: multihash.name,
    mhLength: multihash.size,
  );

  /// Validates the CID's structural invariants (version, codec, multihash
  /// size). Does not verify the multihash against any content -- for that,
  /// hash the content and compare, e.g. via [Block.validate] on the
  /// consuming side.
  bool validate() {
    if (version != 0 && version != 1) return false;
    if (version == 0 && codec != 'dag-pb') return false;
    if (multihash.size <= 0) return false;
    return true;
  }

  /// Returns the encoded CID string.
  @override
  String toString() => encode();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CID &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          codec == other.codec &&
          _bytesEqual(multihash.toBytes(), other.multihash.toBytes());

  @override
  int get hashCode =>
      Object.hash(version, codec, Object.hashAll(multihash.toBytes()));

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static mb.Multibase _multibaseFromName(String name) {
    switch (name.toLowerCase()) {
      case 'base16':
      case 'base16lower':
        return mb.Multibase.base16;
      case 'base16upper':
        return mb.Multibase.base16upper;
      case 'base32':
      case 'base32lower':
        return mb.Multibase.base32;
      case 'base32upper':
        return mb.Multibase.base32upper;
      case 'base58':
      case 'base58btc':
        return mb.Multibase.base58btc;
      case 'base64':
        return mb.Multibase.base64;
      case 'base64url':
        return mb.Multibase.base64url;
      case 'base64urlpad':
        return mb.Multibase.base64urlpad;
      default:
        return mb.Multibase.base32;
    }
  }
}

/// A CID's shape -- version, codec, hash function, and hash length --
/// without any digest content. Lets you describe the kind of CID to produce
/// once and reuse it to hash many different pieces of data. Equivalent to
/// go-cid's `Prefix` type.
class Prefix {
  /// Creates a prefix.
  const Prefix({
    required this.version,
    required this.codec,
    required this.mhType,
    required this.mhLength,
  });

  /// The CID version (0 or 1).
  final int version;

  /// The content codec (e.g. `dag-pb`, `raw`, `dag-cbor`).
  final String codec;

  /// The multihash function name (e.g. `sha2-256`).
  final String mhType;

  /// The digest length in bytes.
  final int mhLength;

  /// Hashes [data] with [mhType] and builds a CID with this prefix's
  /// [version] and [codec]. Equivalent to go-cid's `Prefix.Sum(data)`.
  CID sum(Uint8List data) {
    final mh = MultihashUtils.sum(mhType, data);
    if (version == 0) {
      return CID.v0(Uint8List.fromList(mh.digest));
    }
    return CID.v1(codec, mh);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Prefix &&
          version == other.version &&
          codec == other.codec &&
          mhType == other.mhType &&
          mhLength == other.mhLength;

  @override
  int get hashCode => Object.hash(version, codec, mhType, mhLength);
}
