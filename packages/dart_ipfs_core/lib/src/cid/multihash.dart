// lib/src/cid/multihash.dart
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as pkgcrypto;
import 'package:dart_multihash/dart_multihash.dart' as dm;
import 'package:pointycastle/export.dart' as pc;

/// Helpers for computing and decoding multihashes.
///
/// This class is a thin wrapper around `package:dart_multihash` that provides
/// the hash functions most commonly used by dart_ipfs_core.
class MultihashUtils {
  // Private constructor to prevent instantiation.
  MultihashUtils._();

  /// Encodes [hash] with the SHA2-256 multihash function.
  static dm.MultihashInfo sha256(Uint8List hash) {
    if (hash.length != 32) {
      throw ArgumentError('SHA2-256 digest must be 32 bytes');
    }
    return dm.Multihash.encode('sha2-256', hash);
  }

  /// Encodes raw [hash] bytes with the named multihash function.
  ///
  /// Supported names include `sha2-256`, `sha2-512`, `blake2b-256`, etc.
  static dm.MultihashInfo encode(String name, Uint8List hash) =>
      dm.Multihash.encode(name, hash);

  /// Decodes a multihash byte array.
  static dm.MultihashInfo decode(Uint8List bytes) => dm.Multihash.decode(bytes);

  /// Computes the digest of [data] using the named hash function and wraps
  /// it as a multihash -- the Dart equivalent of go-multihash's
  /// `multihash.Sum(data, code, length)`.
  ///
  /// Supported names: `identity`, `sha1`, `md5`, `sha2-256`, `sha2-512`,
  /// `dbl-sha2-256`, `sha3-224/256/384/512`, `keccak-224/256/384/512`.
  /// BLAKE2b/BLAKE2s, BLAKE3, SHAKE, and MURMUR3 are not yet implemented --
  /// low priority for content-addressing, where SHA2-256 dominates in
  /// practice (see doc/transpilation/PROGRESS.md, go-multihash row).
  static dm.MultihashInfo sum(String name, Uint8List data) {
    final digest = _digestFor(name, data);
    return dm.Multihash.encode(name, digest);
  }

  static Uint8List _digestFor(String name, Uint8List data) {
    switch (name) {
      case 'identity':
        return data;
      case 'sha1':
        return Uint8List.fromList(pkgcrypto.sha1.convert(data).bytes);
      case 'md5':
        return Uint8List.fromList(pkgcrypto.md5.convert(data).bytes);
      case 'sha2-256':
        return Uint8List.fromList(pkgcrypto.sha256.convert(data).bytes);
      case 'sha2-512':
        return Uint8List.fromList(pkgcrypto.sha512.convert(data).bytes);
      case 'dbl-sha2-256':
        final once = pkgcrypto.sha256.convert(data).bytes;
        return Uint8List.fromList(pkgcrypto.sha256.convert(once).bytes);
      case 'sha3-224':
        return pc.SHA3Digest(224).process(data);
      case 'sha3-256':
        return pc.SHA3Digest(256).process(data);
      case 'sha3-384':
        return pc.SHA3Digest(384).process(data);
      case 'sha3-512':
        return pc.SHA3Digest(512).process(data);
      case 'keccak-224':
        return pc.KeccakDigest(224).process(data);
      case 'keccak-256':
        return pc.KeccakDigest(256).process(data);
      case 'keccak-384':
        return pc.KeccakDigest(384).process(data);
      case 'keccak-512':
        return pc.KeccakDigest(512).process(data);
      default:
        throw UnsupportedError('Hash function not supported: $name');
    }
  }
}

/// Re-export of the underlying multihash info type from `dart_multihash`.
typedef MultihashInfo = dm.MultihashInfo;
