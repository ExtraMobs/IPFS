import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dart_ipfs_core/dart_ipfs_core.dart'
    show MultibaseUtils, MultihashUtils;
import '../../utils/base58.dart';

/// go-libp2p core/crypto/pb's `KeyType` enum (crypto.proto): the wire value
/// used in the protobuf-marshaled `PublicKey`/`PrivateKey` messages that
/// peer IDs and the Noise/TLS handshakes are built from.
enum PublicKeyType {
  /// KeyType.RSA = 0.
  rsa(0),

  /// KeyType.Ed25519 = 1.
  ed25519(1),

  /// KeyType.Secp256k1 = 2.
  secp256k1(2),

  /// KeyType.ECDSA = 3.
  ecdsa(3);

  const PublicKeyType(this.protoValue);

  /// The enum's wire value in the `crypto.pb.KeyType` protobuf enum.
  final int protoValue;
}

/// A peer ID's public key is inline-hashed (multihash `identity`, i.e. the
/// hash IS the marshaled key) rather than SHA2-256-hashed when the
/// marshaled protobuf `PublicKey` message is this short or shorter -- see
/// go-libp2p core/peer's `maxInlineKeyLength`. Ed25519 keys are always
/// under this threshold (36 marshaled bytes); RSA keys never are.
const int _maxInlineKeyLength = 42;

/// Encodes `PublicKey{required KeyType Type = 1; required bytes Data = 2;}`
/// (crypto.proto) on the wire: a hand-rolled 2-field protobuf message, not
/// worth pulling in a full protobuf codegen step for.
Uint8List _marshalPublicKeyProto(PublicKeyType type, Uint8List rawKeyBytes) {
  final out = BytesBuilder();
  out.addByte(0x08); // field 1, varint wire type
  out.addByte(type.protoValue); // KeyType values all fit in one byte
  out.addByte(0x12); // field 2, length-delimited wire type
  out.add(_encodeProtoVarint(rawKeyBytes.length));
  out.add(rawKeyBytes);
  return out.toBytes();
}

Uint8List _encodeProtoVarint(int value) {
  final bytes = <int>[];
  var v = value;
  while (v >= 0x80) {
    bytes.add((v & 0x7f) | 0x80);
    v >>= 7;
  }
  bytes.add(v);
  return Uint8List.fromList(bytes);
}

/// Represents a peer identifier in the IPFS network.
class PeerId {
  /// Creates a PeerId from raw bytes.
  PeerId({required this.value});

  /// Creates a PeerId from a Base58-encoded string.
  factory PeerId.fromBase58(String base58) {
    return PeerId(value: Base58().base58Decode(base58));
  }

  /// Creates a PeerId from a base36-encoded string.
  ///
  /// Accepts both the bare base36 string and the multibase-prefixed form
  /// starting with `k` (the base36 multibase prefix).
  factory PeerId.fromBase36(String base36) {
    if (base36.isEmpty) {
      throw ArgumentError('Empty base36 string');
    }
    final prefixed = base36[0] == 'k' ? base36 : 'k$base36';
    return PeerId(value: MultibaseUtils.decode(prefixed));
  }

  /// Creates a PeerId from a raw public key, per go-libp2p core/peer's
  /// `IDFromPublicKey`: the key is wrapped in a protobuf `PublicKey{Type,
  /// Data}` message (crypto.proto), then that message is hashed as a
  /// multihash -- `identity` (the hash IS the marshaled message) when the
  /// message is [_maxInlineKeyLength] bytes or shorter, `sha2-256`
  /// otherwise. Ed25519 keys (36 marshaled bytes) always take the inline
  /// path, producing the well-known `12D3Koo...` peer ID family; RSA and
  /// other larger keys always hash, producing the `Qm...` family.
  ///
  /// [type] names the key algorithm: `'Ed25519'`, `'RSA'`, `'Secp256k1'`,
  /// or `'ECDSA'` (case-insensitive). [publicKey] must be exactly 32 bytes
  /// for Ed25519 -- the other algorithms don't have a fixed raw-key length
  /// enforced here.
  factory PeerId.fromPublicKey(Uint8List publicKey, {required String type}) {
    final keyType = switch (type.toLowerCase()) {
      'ed25519' => PublicKeyType.ed25519,
      'rsa' => PublicKeyType.rsa,
      'secp256k1' => PublicKeyType.secp256k1,
      'ecdsa' => PublicKeyType.ecdsa,
      _ => throw UnsupportedError('Unknown public key type: $type'),
    };
    if (keyType == PublicKeyType.ed25519 && publicKey.length != 32) {
      throw ArgumentError(
        'Ed25519 public key must be 32 bytes, got ${publicKey.length}',
      );
    }

    final marshaled = _marshalPublicKeyProto(keyType, publicKey);
    final alg = marshaled.length <= _maxInlineKeyLength
        ? 'identity'
        : 'sha2-256';
    return PeerId(value: MultihashUtils.sum(alg, marshaled).toBytes());
  }

  /// The raw bytes of the peer ID.
  final Uint8List value;

  /// Converts the peer ID to a Base58-encoded string.
  String toBase58() {
    return Base58().encode(value);
  }

  /// Converts the peer ID to a multibase-prefixed base36-encoded string.
  ///
  /// The returned string starts with `k`, the base36 multibase prefix, e.g.
  /// `k51qzi5uqu5...`.
  String toBase36() {
    return MultibaseUtils.encodeWithName('base36', value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerId &&
          runtimeType == other.runtimeType &&
          _listsEqual(value, other.value);

  @override
  int get hashCode => _listHashCode(value);

  @override
  String toString() => toBase58();

  /// Checks if this PeerId satisfies a static Proof-of-Work condition (SEC-005).
  ///
  /// The condition is that the SHA-256 hash of the PeerId must have at least
  /// [difficulty] leading zero bits.
  bool verifyPoW({int difficulty = 8}) {
    if (difficulty <= 0) return true;

    // Hash the PeerId bytes
    final hash = _sha256(value);

    // Check leading zero bits
    int leadingZeros = 0;
    for (final byte in hash) {
      if (byte == 0) {
        leadingZeros += 8;
      } else {
        // Count bits in the first non-zero byte
        var b = byte;
        for (int i = 7; i >= 0; i--) {
          if ((b & (1 << i)) == 0) {
            leadingZeros++;
          } else {
            break;
          }
        }
        break;
      }
      if (leadingZeros >= difficulty) break;
    }

    return leadingZeros >= difficulty;
  }

  static Uint8List _sha256(Uint8List data) {
    return Uint8List.fromList(crypto.sha256.convert(data).bytes);
  }
}

bool _listsEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _listHashCode(List<int> list) {
  return list.fold(0, (prev, element) => prev ^ element.hashCode);
}

