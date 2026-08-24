import 'dart:typed_data';

import 'package:dart_ipfs/dart_ipfs.dart' as umbrella;
import 'package:dart_ipfs_core/dart_ipfs_core.dart' as core;
import 'package:test/test.dart';

/// Verifies that the umbrella package re-exports the same public core APIs
/// as `dart_ipfs_core`.
void main() {
  group('Umbrella re-exports', () {
    test('CID API is available from umbrella and core', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      final coreCid = await core.CID.fromContent(data);
      final umbrellaCid = await umbrella.CID.fromContent(data);

      expect(umbrellaCid, equals(coreCid));
      expect(umbrellaCid.encode(), equals(coreCid.encode()));
    });

    test('Block API is available from umbrella and core', () async {
      final data = Uint8List.fromList([4, 5, 6]);
      final coreBlock = await core.Block.fromData(data);
      final umbrellaBlock = await umbrella.Block.fromData(data);

      expect(umbrellaBlock.cid, equals(coreBlock.cid));
      expect(umbrellaBlock.data, equals(coreBlock.data));
    });

    test('InMemoryBlockStore is available from umbrella', () async {
      final store = umbrella.InMemoryBlockStore();
      await store.start();
      final block = await umbrella.Block.fromData(
        Uint8List.fromList([7, 8, 9]),
      );
      await store.putBlock(block);
      final result = await store.getBlock(block.cid);
      expect(result.value, isNotNull);
      await store.stop();
    });

    test('CryptoUtils is available from umbrella and core', () {
      final salt = umbrella.CryptoUtils.generateSalt();
      expect(salt.length, equals(umbrella.CryptoUtils.saltSize));
      expect(
        core.CryptoUtils.generateSalt().length,
        equals(core.CryptoUtils.saltSize),
      );
    });

    test(
      'CarHeader.roots exposes the same CID type the barrel exports '
      '(Phase 2 regression: these used to be two different classes '
      'sharing a name)',
      () async {
        final data = Uint8List.fromList([10, 11, 12]);
        // Constructed via the umbrella's own CAR API -- lib/src/core/data_structures/car.dart.
        final cid = await umbrella.CID.fromContent(data);
        final header = umbrella.CarHeader(version: 1, roots: [cid]);

        // If lib/src/core/cid.dart were still its own independent class
        // (pre-shim), this line wouldn't even compile: header.roots'
        // element type and the barrel's `CID` would be unrelated types.
        final umbrella.CID rootFromHeader = header.roots.first;
        expect(rootFromHeader, equals(cid));
        expect(rootFromHeader, isA<core.CID>());
      },
    );
  });
}
