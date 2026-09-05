import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_block_format/transpiled_block_format.dart' as blocks;
import 'package:transpiled_ipfs/transpiled_ipfs.dart';

void main() {
  test('has/get/put validates and returns a defensive byte copy', () async {
    final store = Blockstore();
    final data = Uint8List.fromList([1, 2, 3]);
    final cid = CID.computeForDataSync(data);
    await store.put(BasicBlock(data, cid));
    data[0] = 9;

    expect(await store.has(cid), isTrue);
    expect((await store.get(cid)).rawData(), orderedEquals([1, 2, 3]));
    await store.close();
  });

  test('put rejects CID-divergent bytes before persistence', () async {
    final store = Blockstore();
    final cid = CID.computeForDataSync(Uint8List.fromList([4, 5, 6]));
    await expectLater(
      store.put(BasicBlock(Uint8List.fromList([4, 5, 7]), cid)),
      throwsA(isA<BlockstoreHashMismatchException>()),
    );
    expect(await store.has(cid), isFalse);
    await store.close();
  });

  test('get throws a typed error for an absent block', () async {
    final store = Blockstore();
    final cid = CID.computeForDataSync(Uint8List.fromList([8]));
    await expectLater(
      store.get(cid),
      throwsA(isA<BlockstoreNotFoundException>()),
    );
    await store.close();
  });

  test('getSize and putMany preserve the blockstore contract', () async {
    final store = Blockstore();
    final first = blocks.newBlock(Uint8List.fromList([1, 2, 3]));
    final second = blocks.newBlock(Uint8List.fromList([4, 5]));
    await store.putMany([first, second]);
    expect(await store.getSize(first.cid()), 3);
    expect(await store.getSize(second.cid()), 2);
    await expectLater(
      store.getSize(
        CID.decode('QmYwAPJzv5CZsnAzt8auVZRnGi2C5zD2aNNw9NFpeuAbmr'),
      ),
      throwsA(isA<BlockstoreNotFoundException>()),
    );
  });
}
