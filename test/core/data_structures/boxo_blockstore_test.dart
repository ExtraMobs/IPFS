import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_ipfs/src/core/cid.dart';
import 'package:transpiled_ipfs/src/core/data_structures/block.dart';
import 'package:transpiled_ipfs/src/core/data_structures/blockstore.dart';
import 'package:transpiled_ipfs/src/platform/platform.dart';

void main() {
  late String path;

  setUp(() async {
    path = await getPlatform().createTempDirectory('boxo_blockstore_test_');
  });

  tearDown(() async {
    if (await getPlatform().exists(path)) {
      await getPlatform().delete(path);
    }
  });

  test(
    'has/get/put validates and rereads through the existing store',
    () async {
      final store = BlockStore(path: path);
      await store.start();
      final data = Uint8List.fromList([1, 2, 3]);
      final block = Block(cid: CID.computeForDataSync(data), data: data);

      await store.put(block);
      expect(await store.has(block.cid), isTrue);
      expect((await store.get(block.cid)).data, orderedEquals(data));

      await store.stop();
      final reopened = BlockStore(path: path);
      await reopened.start();
      expect((await reopened.get(block.cid)).data, orderedEquals(data));
      await reopened.stop();
    },
  );

  test('put rejects CID-divergent bytes before persistence', () async {
    final store = BlockStore(path: path);
    await store.start();
    final data = Uint8List.fromList([4, 5, 6]);
    final block = Block(cid: CID.computeForDataSync(data), data: data);
    final divergent = Block(
      cid: block.cid,
      data: Uint8List.fromList([4, 5, 7]),
    );

    await expectLater(
      store.put(divergent),
      throwsA(isA<BlockstoreHashMismatchException>()),
    );
    expect(await store.has(block.cid), isFalse);
    await store.stop();
  });

  test(
    'get distinguishes a corrupt persisted block from a missing block',
    () async {
      final store = BlockStore(path: path);
      await store.start();
      final data = Uint8List.fromList([7, 8, 9]);
      final block = Block(cid: CID.computeForDataSync(data), data: data);
      await store.put(block);
      await store.stop();

      await getPlatform().writeBytes(
        '$path/${block.cid}',
        Uint8List.fromList([7, 8, 0]),
      );
      final reopened = BlockStore(path: path);
      await reopened.start();
      await expectLater(
        reopened.get(block.cid),
        throwsA(isA<BlockstoreHashMismatchException>()),
      );
      await reopened.stop();
    },
  );

  test('get throws not-found for an absent block', () async {
    final store = BlockStore(path: path);
    await store.start();
    final block = Block(
      cid: CID.computeForDataSync(Uint8List.fromList([10])),
      data: Uint8List.fromList([10]),
    );

    await expectLater(
      store.get(block.cid),
      throwsA(isA<BlockstoreNotFoundException>()),
    );
    await store.stop();
  });
}
