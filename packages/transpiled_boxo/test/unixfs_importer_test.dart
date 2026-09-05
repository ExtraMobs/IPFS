import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_boxo/transpiled_boxo.dart';

void main() {
  test('UnixFS protobuf vector and round trip', () {
    final bytes = wrapData(Uint8List.fromList([1, 2]));
    expect(bytes, [8, 0, 18, 2, 1, 2, 24, 2]);
    final decoded = UnixFsData.fromBytes(bytes);
    expect(decoded.type, UnixFsDataType.raw);
    expect(decoded.data, [1, 2]);
    expect(decoded.filesize, 2);
    expect(decoded.toBytes(), bytes);
  });

  test('DAG-PB link and node preserve wire order', () {
    final link = DagPbLink(hash: Uint8List.fromList([0x12, 0x20]), tsize: 7);
    final node = DagPbNode(data: Uint8List.fromList([9]), links: [link]);
    final decoded = DagPbNode.fromBytes(node.toBytes());
    expect(decoded.data, [9]);
    expect(decoded.links.single.hash, [0x12, 0x20]);
    expect(decoded.links.single.tsize, 7);
    expect(node.toBytes(), [18, 8, 10, 2, 18, 32, 18, 0, 24, 7, 10, 1, 9]);
  });

  test('balanced importer builds a small regular file', () async {
    final result = await BalancedUnixFsImporter(
      chunkSize: 2,
      maxLinks: 2,
      retainBlocks: true,
    ).importStream(Stream.value([1, 2, 3, 4]));
    expect(result.blocks.length, 3); // two leaves and one File parent
    expect(result.root, result.blocks.last.cid);
    final root = result.blocks.last;
    final dag = DagPbNode.fromBytes(root.data);
    final fs = UnixFsData.fromBytes(dag.data);
    expect(fs.type, UnixFsDataType.file);
    expect(fs.filesize, 4);
    expect(fs.blocksizes, [2, 2]);
    expect(dag.links.length, 2);
  });

  test('raw leaves use CIDv1/raw when requested', () async {
    final result = await BalancedUnixFsImporter(
      chunkSize: 4,
      rawLeaves: true,
      retainBlocks: true,
    ).importStream(Stream.value([1, 2, 3]));
    expect(result.blocks.single.raw, isTrue);
    expect(result.root.version, 1);
    expect(result.root.codec, 'raw');
  });
}
