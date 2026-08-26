// Port of go-ipld-prime's codec/raw/codec.go.
import 'dart:typed_data';

import '../../datamodel/node.dart';
import '../../datamodel/node_builder.dart';

// Go registers raw (multicodec 0x55) from init(). Registration stays omitted
// until this package has a multicodec registry dependency; callers can use
// encode/decode directly in the meantime.

/// Decodes all bytes from [reader] into [assembler].
///
/// A [Uint8List] is assigned directly, matching the Go codec's no-copy
/// shortcut for readers which expose their backing bytes.
void decode(NodeAssembler assembler, Iterable<int> reader) {
  late final Uint8List data;
  try {
    data = reader is Uint8List
        ? reader
        : Uint8List.fromList(reader.toList(growable: false));
  } catch (error) {
    throw _RawDecodeException(error);
  }
  assembler.assignBytes(data);
}

/// Encodes the bytes represented by [node] into [writer].
void encode(Node node, Sink<List<int>> writer) => writer.add(node.asBytes());

final class _RawDecodeException implements Exception {
  const _RawDecodeException(this.cause);

  final Object cause;

  @override
  String toString() => 'could not decode raw node: $cause';
}
