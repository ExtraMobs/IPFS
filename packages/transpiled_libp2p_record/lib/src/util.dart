// lib/src/util.dart
//
// Port of go-libp2p-record's util.go.
import 'validator.dart';

/// Splits a key of the form `/$namespace/$path` into `($namespace,
/// $path)`. Throws [InvalidRecordTypeException] if [key] isn't of that
/// form. Equivalent to go-libp2p-record's `SplitKey`.
(String namespace, String path) splitKey(String key) {
  if (key.isEmpty || key[0] != '/') {
    throw const InvalidRecordTypeException();
  }

  final rest = key.substring(1);
  final i = rest.indexOf('/');
  if (i <= 0) {
    throw const InvalidRecordTypeException();
  }

  return (rest.substring(0, i), rest.substring(i + 1));
}
