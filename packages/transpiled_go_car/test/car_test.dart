import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_go_car/transpiled_go_car.dart';

const _fixture =
    '3aa265726f6f747381d82a58250001711220151fe9e73c6267a7060c6f6c4cca943c236f4b196723489608edb42a8b8fa80b6776657273696f6e012c01711220151fe9e73c6267a7060c6f6c4cca943c236f4b196723489608edb42a8b8fa80ba165646f646779f5';

Uint8List _hex(String value) => Uint8List.fromList([
  for (var i = 0; i < value.length; i += 2)
    int.parse(value.substring(i, i + 2), radix: 16),
]);

void main() {
  test('writes the canonical go-car single-block vector', () async {
    final cid = CID.decode(
      'bafyreiavd7u6opdcm6tqmddpnrgmvfb4enxuwglhenejmchnwqvixd5ibm',
    );
    final car = await CarWriter(
      roots: [cid],
      get: (_) => _hex('a165646f646779f5'),
      links: (_) => const <CID>[],
    ).toBytes();
    expect(car, _hex(_fixture));
  });

  test('reads incrementally and validates CID/data', () {
    final reader = CarReader(_hex(_fixture));
    expect(reader.header!.roots, hasLength(1));
    final block = reader.next()!;
    expect(block.data, _hex('a165646f646779f5'));
    expect(reader.next(), isNull);
  });

  test('deduplicates depth-first traversal and loads blocks', () async {
    final a = CID.computeForDataSync(Uint8List.fromList('a'.codeUnits));
    final b = CID.computeForDataSync(Uint8List.fromList('b'.codeUnits));
    final calls = <String>[];
    final car = await CarWriter(
      roots: [a],
      get: (cid) {
        calls.add(cid.encode());
        return Uint8List.fromList((cid == a ? 'a' : 'b').codeUnits);
      },
      links: (cid) => cid == a ? [b, b] : const [],
    ).toBytes();
    final blocks = CarReader(car).blocks().toList();
    expect(await blocks, hasLength(2));
    expect(calls, hasLength(2));
  });

  test('rejects corruption, truncation and oversized sections', () {
    final bytes = _hex(_fixture);
    bytes[bytes.length - 1] ^= 1;
    expect(
      () => CarReader(bytes).next(),
      throwsA(isA<CarIntegrityException>()),
    );
    expect(
      () => CarReader(bytes.sublist(0, bytes.length - 1)).next(),
      throwsFormatException,
    );
    expect(() => readHeader(Uint8List.fromList([0x80])), throwsFormatException);
    expect(
      () => readHeader(Uint8List.fromList([0xff, 0xff, 0xff, 0xff, 0x7f])),
      throwsFormatException,
    );
  });

  test('reads fragmented streams', () async {
    final bytes = _hex(_fixture);
    final stream = Stream.fromIterable([
      for (var i = 0; i < bytes.length; i++) Uint8List.fromList([bytes[i]]),
    ]);
    final reader = CarReader(stream);
    expect((await reader.nextAsync())!.data, _hex('a165646f646779f5'));
    expect(await reader.nextAsync(), isNull);
  });

  test('loadCar accepts a block store callback', () async {
    final blocks = <CarBlock>[];
    final header = await loadCar(_hex(_fixture), blocks.add);
    expect(header.roots, hasLength(1));
    expect(blocks, hasLength(1));
  });
}
