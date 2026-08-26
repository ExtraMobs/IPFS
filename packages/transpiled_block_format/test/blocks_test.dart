import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_block_format/transpiled_block_format.dart';
import 'package:transpiled_cid/transpiled_cid.dart';

void main() {
  test('new block computes a CID and exposes block metadata', () {
    final block = newBlock(Uint8List.fromList([1, 2, 3]));
    expect(block.rawData(), orderedEquals([1, 2, 3]));
    expect(block.cid().version, 0);
    expect(block.multihash(), isNotEmpty);
    expect(block.toString(), '[Block ${block.cid()}]');
    expect(block.loggable()['block'], block.cid().toString());
  });

  test('newBlockWithCid accepts trusted CIDs when debug validation is off', () {
    final cid = CID.computeForDataSync(Uint8List.fromList([1]), codec: 'raw');
    expect(newBlockWithCid(Uint8List.fromList([2]), cid).cid(), cid);
  });
}
