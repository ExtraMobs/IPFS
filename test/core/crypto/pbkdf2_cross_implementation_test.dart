// Cross-checks the umbrella's CryptoUtils.deriveKey (pointycastle-backed)
// against dart_ipfs_core's independent, hand-rolled implementation
// (package:crypto-only, no pointycastle, so dart_ipfs_core stays free of
// that dependency). Both implement PBKDF2-HMAC-SHA256 (RFC 2898); this
// proves they agree before Phase 2 consolidates the umbrella onto the
// core implementation.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_ipfs/src/core/crypto/crypto_utils.dart' as umbrella;
import 'package:dart_ipfs_core/dart_ipfs_core.dart' as core;
import 'package:test/test.dart';

void main() {
  group('PBKDF2 cross-implementation agreement', () {
    Uint8List bytesOf(String s) => Uint8List.fromList(utf8.encode(s));

    final cases = <String, ({String password, String salt, int iterations, int keyLength})>{
      'default params': (
        password: 'correct horse battery staple',
        salt: 'a-16-byte-salt!!',
        iterations: umbrella.CryptoUtils.defaultIterations,
        keyLength: umbrella.CryptoUtils.keySize,
      ),
      'low iteration count': (
        password: 'p',
        salt: '01234567',
        iterations: 1,
        keyLength: 16,
      ),
      'longer key than one SHA-256 block': (
        password: 'a fairly long password used for key derivation testing',
        salt: 'another-salt-value',
        iterations: 1000,
        keyLength: 48, // > 32 bytes, forces the multi-block path
      ),
      'unicode password': (
        password: 'sénhá-com-acentos-🔒',
        salt: 'unicode-salt-test',
        iterations: 500,
        keyLength: 32,
      ),
    };

    cases.forEach((label, params) {
      test('agrees on "$label"', () {
        final salt = bytesOf(params.salt);

        final umbrellaKey = umbrella.CryptoUtils.deriveKey(
          params.password,
          salt,
          iterations: params.iterations,
          keyLength: params.keyLength,
        );
        final coreKey = core.CryptoUtils.deriveKey(
          params.password,
          salt,
          iterations: params.iterations,
          keyLength: params.keyLength,
        );

        expect(coreKey.length, equals(params.keyLength));
        expect(
          coreKey,
          equals(umbrellaKey),
          reason:
              'pointycastle-backed (umbrella) and hand-rolled (core) '
              'PBKDF2-HMAC-SHA256 must derive identical keys for the same '
              'inputs -- divergence here would mean at least one is '
              'non-compliant with RFC 2898.',
        );
      });
    });

    test('is deterministic across repeated calls (both implementations)', () {
      final salt = bytesOf('determinism-check');
      final u1 = umbrella.CryptoUtils.deriveKey('pw', salt, iterations: 200);
      final u2 = umbrella.CryptoUtils.deriveKey('pw', salt, iterations: 200);
      final c1 = core.CryptoUtils.deriveKey('pw', salt, iterations: 200);
      final c2 = core.CryptoUtils.deriveKey('pw', salt, iterations: 200);
      expect(u1, equals(u2));
      expect(c1, equals(c2));
      expect(u1, equals(c1));
    });
  });
}
