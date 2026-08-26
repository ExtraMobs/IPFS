import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_ipld_prime/transpiled_ipld_prime.dart';

void main() {
  test('DAG-JSON encodes and decodes ordinary nodes and bytes', () {
    final node = PlainMap({'n': newInt(3), 'b': newBytes(Uint8List.fromList([1, 2]))});
    final out = <int>[];
    encodeDagJson(node, outSink(out));
    expect(String.fromCharCodes(out), '{"n":3,"b":{"/":{"bytes":"AQI"}}}\n');
    final builder = const PrototypeAny().newBuilder();
    decodeDagJson(builder, out);
    expect(builder.build().lookupByString('n').asInt(), 3);
    expect(builder.build().lookupByString('b').asBytes(), [1, 2]);
  });
}

Sink<List<int>> outSink(List<int> out) => _Sink(out);

final class _Sink implements Sink<List<int>> {
  _Sink(this.out);
  final List<int> out;
  @override
  void add(List<int> data) => out.addAll(data);
  @override
  void close() {}
}
