// Parity vectors from go-libp2p-record's own validator_test.go
// (go-ipfs-reference/go-libp2p-record/validator_test.go, TestSplitPath).
import 'package:transpiled_libp2p_record/transpiled_libp2p_record.dart';
import 'package:test/test.dart';

const _badPaths = [
  'foo/bar/baz',
  '//foo/bar/baz',
  '/ns',
  'ns',
  'ns/',
  '',
  '//',
  '/',
  '////',
];

void main() {
  group('splitKey', () {
    test('splits a three-segment path', () {
      final (ns, key) = splitKey('/foo/bar/baz');
      expect(ns, equals('foo'));
      expect(key, equals('bar/baz'));
    });

    test('splits a two-segment path', () {
      final (ns, key) = splitKey('/foo/bar');
      expect(ns, equals('foo'));
      expect(key, equals('bar'));
    });

    for (final badPath in _badPaths) {
      test('rejects bad path "$badPath"', () {
        expect(
          () => splitKey(badPath),
          throwsA(isA<InvalidRecordTypeException>()),
        );
      });
    }
  });
}
