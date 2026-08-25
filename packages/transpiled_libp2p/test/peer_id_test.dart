import 'dart:typed_data';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';
import 'package:test/test.dart';

void main() {
  group('PeerId base36', () {
    test('toBase36 returns multibase-prefixed string', () {
      final pid = PeerId(value: Uint8List.fromList([0, 1, 2, 3, 255]));
      final encoded = pid.toBase36();
      expect(encoded.startsWith('k'), isTrue);
      expect(encoded.length, greaterThan(1));
    });

    test('fromBase36 round-trips', () {
      final original = PeerId(value: Uint8List.fromList([0xAB, 0xCD, 0xEF]));
      final encoded = original.toBase36();
      final decoded = PeerId.fromBase36(encoded);
      expect(decoded.value, orderedEquals(original.value));
    });

    test('fromBase36 accepts bare string without k prefix', () {
      final original = PeerId(value: Uint8List.fromList([0x01, 0x02]));
      final bare = original.toBase36().substring(1);
      final decoded = PeerId.fromBase36(bare);
      expect(decoded.value, orderedEquals(original.value));
    });

    test('fromBase36 rejects invalid characters', () {
      expect(() => PeerId.fromBase36('k!'), throwsArgumentError);
    });

    test('fromPublicKey Ed25519 derives deterministic PeerId', () {
      final publicKey = Uint8List.fromList(List.generate(32, (i) => i));
      final pid1 = PeerId.fromPublicKey(publicKey, type: 'Ed25519');
      final pid2 = PeerId.fromPublicKey(publicKey, type: 'Ed25519');
      expect(pid1, equals(pid2));
      // go-libp2p core/peer's IDFromPublicKey: the protobuf-marshaled
      // PublicKey{Type: Ed25519, Data: <32 bytes>} is 36 bytes, at or
      // under maxInlineKeyLength (42) -- so this is an `identity`
      // multihash (varint code 0x00 + varint length 36 + the 36 bytes),
      // not a bare 32-byte digest.
      expect(pid1.value[0], equals(0x00)); // identity multihash code
      expect(pid1.value[1], equals(36)); // marshaled PublicKey length
      expect(pid1.value.length, equals(38));
    });

    test('fromPublicKey inlines an Ed25519 key as its marshaled protobuf bytes', () {
      final publicKey = Uint8List.fromList(List.generate(32, (i) => i));
      final pid = PeerId.fromPublicKey(publicKey, type: 'Ed25519');
      // varint(0x00) + varint(36) + protobuf PublicKey{Type:1(Ed25519),
      // Data:<32 bytes>}: field tags 0x08 0x01 (Type) and 0x12 0x20 (Data,
      // length 32) framing the raw key.
      final expected = Uint8List.fromList([
        0x00, 36, // multihash: identity, length 36
        0x08, 0x01, // PublicKey.Type = Ed25519 (1)
        0x12, 32, // PublicKey.Data, length 32
        ...publicKey,
      ]);
      expect(pid.value, orderedEquals(expected));
    });

    test('fromPublicKey RSA-sized keys hash instead of inlining', () {
      // A 270-byte "key" (typical marshaled size for a 2048-bit RSA key)
      // is well over maxInlineKeyLength, so this must hash rather than
      // inline -- the multihash code byte must be sha2-256 (0x12), not
      // identity (0x00).
      final bigKey = Uint8List(270);
      final pid = PeerId.fromPublicKey(bigKey, type: 'RSA');
      expect(pid.value[0], equals(0x12)); // sha2-256 multihash code
      expect(pid.value.length, equals(2 + 32)); // code + length + digest
    });

    test('fromPublicKey rejects an unknown key type', () {
      expect(
        () => PeerId.fromPublicKey(Uint8List(32), type: 'bogus'),
        throwsUnsupportedError,
      );
    });

    test('fromPublicKey requires a 32-byte key for Ed25519', () {
      expect(
        () => PeerId.fromPublicKey(Uint8List(31), type: 'Ed25519'),
        throwsArgumentError,
      );
    });
  });

  group('PeerId PoW', () {
    test('verifyPoW should accept PeerId with enough leading zeros', () {
      // Find a PeerId that satisfies a 4-bit difficulty
      PeerId? found;
      for (int i = 0; i < 1000; i++) {
        final pid = PeerId(
          value: Uint8List.fromList([i & 0xFF, (i >> 8) & 0xFF]),
        );
        if (pid.verifyPoW(difficulty: 4)) {
          found = pid;
          break;
        }
      }

      expect(found, isNotNull);
      expect(found!.verifyPoW(difficulty: 4), isTrue);
    });

    test('verifyPoW should reject PeerId with insufficient leading zeros', () {
      // Find a PeerId that DOES NOT satisfy a 16-bit difficulty (statistically likely)
      final pid = PeerId(value: Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]));
      expect(pid.verifyPoW(difficulty: 16), isFalse);
    });

    test('difficulty 0 should always pass', () {
      final pid = PeerId(value: Uint8List.fromList([0xFF]));
      expect(pid.verifyPoW(difficulty: 0), isTrue);
    });
  });
}
