import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_varint/transpiled_varint.dart';

void main() {
  group('Varint', () {
    test('encode/decode small integers', () {
      for (var i = 0; i < 128; i++) {
        final encoded = encodeVarint(i);
        expect(encoded.length, equals(1));
        expect(encoded[0], equals(i));

        final (decoded, length) = readVarint(encoded, 0);
        expect(decoded, equals(i));
        expect(length, equals(1));
      }
    });

    test('encode/decode multi-byte integers', () {
      final testValues = [128, 300, 16383, 16384, 2097151];
      for (final val in testValues) {
        final encoded = encodeVarint(val);
        final (decoded, length) = readVarint(encoded, 0);
        expect(decoded, equals(val));
        expect(length, equals(encoded.length));
      }
    });

    test('readVarint respects a non-zero offset', () {
      final prefix = Uint8List.fromList([0xFF, 0xFF]);
      final encoded = encodeVarint(16384);
      final combined = Uint8List.fromList([...prefix, ...encoded]);
      final (decoded, length) = readVarint(combined, prefix.length);
      expect(decoded, equals(16384));
      expect(length, equals(encoded.length));
    });

    test('throws FormatException on a truncated varint', () {
      final truncated = Uint8List.fromList([0x80, 0x80]); // never terminates
      expect(() => readVarint(truncated, 0), throwsFormatException);
    });

    test('throws FormatException on an overlong varint', () {
      final tooLong = Uint8List.fromList(List<int>.filled(11, 0x80));
      expect(() => readVarint(tooLong, 0), throwsFormatException);
    });

    test('rejects encoding a negative value', () {
      expect(() => encodeVarint(-1), throwsArgumentError);
    });
  });
}
