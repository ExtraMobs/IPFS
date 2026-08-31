import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:transpiled_ipfs/src/core/cid.dart';
import 'package:transpiled_ipfs/src/core/data_structures/block.dart';
import 'package:transpiled_ipfs/src/proto/generated/bitswap/bitswap.pb.dart'
    as pb;
import 'package:transpiled_ipfs/src/protocols/bitswap/message.dart';

void main() {
  group('Message', () {
    test('constructor creates empty message', () {
      final message = Message();
      expect(message.getBlocks(), isEmpty);
      expect(message.getWantlist().entries, isEmpty);
      expect(message.getBlockPresences(), isEmpty);
      expect(message.hasBlocks(), isFalse);
      expect(message.hasWantlist(), isFalse);
      expect(message.hasBlockPresences(), isFalse);
      expect(message.pendingBytes, equals(0));
      expect(message.from, isNull);
    });

    test('addBlock and getBlocks', () async {
      final message = Message();
      final data = Uint8List.fromList([1, 2, 3]);
      final block = await Block.fromData(data);

      message.addBlock(block);
      expect(message.hasBlocks(), isTrue);
      expect(message.getBlocks(), hasLength(1));
    });

    test('addWantlistEntry and getWantlist', () {
      final message = Message();
      message.addWantlistEntry('QmTest', priority: 10);

      expect(message.hasWantlist(), isTrue);
      final wantlist = message.getWantlist();
      expect(wantlist.entries, hasLength(1));
      expect(wantlist.entries['QmTest']?.priority, equals(10));
    });

    test('addWantlistEntry with all parameters', () {
      final message = Message();
      message.addWantlistEntry(
        'QmTest',
        priority: 5,
        cancel: true,
        wantType: WantType.have,
        sendDontHave: true,
      );

      final wantlist = message.getWantlist();
      final entry = wantlist.entries['QmTest'];
      expect(entry?.cancel, isTrue);
      expect(entry?.wantType, equals(WantType.have));
      expect(entry?.sendDontHave, isTrue);
    });

    test('addBlockPresence and getBlockPresences', () {
      final message = Message();
      message.addBlockPresence('QmTest', BlockPresenceType.have);

      expect(message.hasBlockPresences(), isTrue);
      final presences = message.getBlockPresences();
      expect(presences, hasLength(1));
      expect(presences.first.cid, equals('QmTest'));
      expect(presences.first.type, equals(BlockPresenceType.have));
    });

    test('pendingBytes can be set', () {
      final message = Message();
      message.pendingBytes = 1000;
      expect(message.pendingBytes, equals(1000));
    });

    test('from can be set', () {
      final message = Message();
      message.from = 'peer1';
      expect(message.from, equals('peer1'));
    });

    test('preserves Bitswap 1.2 want, payload, and presence fields', () async {
      final block = await Block.fromData(Uint8List.fromList([1, 2, 3]));
      final have = await Block.fromData(Uint8List.fromList([4]));
      final dontHave = await Block.fromData(Uint8List.fromList([5]));
      final message = Message(full: true)
        ..pendingBytes = 7
        ..addWantlistEntry(
          have.cid.encode(),
          priority: 2,
          wantType: WantType.have,
          sendDontHave: true,
        )
        ..addWantlistEntry(dontHave.cid.encode(), priority: 3)
        ..addBlock(block)
        ..addBlockPresence(have.cid.encode(), BlockPresenceType.have)
        ..addBlockPresence(dontHave.cid.encode(), BlockPresenceType.dontHave);

      final bytes = message.toBytes();
      final wire = pb.Message.fromBuffer(bytes);
      expect(wire.wantlist.full, isTrue);
      expect(wire.wantlist.entries, hasLength(2));
      expect(wire.payload.single.prefix, equals([1, 0x55, 0x12, 32]));
      expect(wire.payload.single.data, equals(block.data));
      expect(wire.blockPresences, hasLength(2));
      expect(wire.pendingBytes, 7);

      final decoded = await Message.fromBytes(bytes);
      expect(decoded.full, isTrue);
      expect(decoded.pendingBytes, 7);
      expect(decoded.getBlocks().single, equals(block));
      expect(
        decoded.getWantlist().entries[have.cid.encode()]?.wantType,
        WantType.have,
      );
      expect(
        decoded.getBlockPresences().map((presence) => presence.type),
        containsAll([BlockPresenceType.have, BlockPresenceType.dontHave]),
      );
    });

    test(
      'uses the four-varint CIDv0 payload prefix and accepts legacy blocks',
      () async {
        final data = Uint8List.fromList([1, 2, 3]);
        final cid = CID.v0(Uint8List.fromList(sha256.convert(data).bytes));
        final message = Message()..addBlock(Block(cid: cid, data: data));

        final payload = pb.Message.fromBuffer(message.toBytes()).payload.single;
        expect(payload.prefix, equals([0, 0x70, 0x12, 32]));

        final legacy = pb.Message()..blocks.add(data);
        final decoded = await Message.fromBytes(legacy.writeToBuffer());
        expect(decoded.getBlocks().single.cid, equals(cid));
      },
    );

    test('matches the upstream block-presence CID protobuf vector', () async {
      final cid = CID.v0(
        Uint8List.fromList(sha256.convert(utf8.encode('foobar')).bytes),
      );
      final message = Message()
        ..addBlockPresence(cid.encode(), BlockPresenceType.have);

      final presence = pb.Message.fromBuffer(
        message.toBytes(),
      ).blockPresences.single;
      expect(
        presence.writeToBuffer(),
        equals(const [
          10,
          34,
          18,
          32,
          195,
          171,
          143,
          241,
          55,
          32,
          232,
          173,
          144,
          71,
          221,
          57,
          70,
          107,
          60,
          137,
          116,
          229,
          146,
          194,
          250,
          56,
          61,
          74,
          57,
          96,
          113,
          76,
          174,
          240,
          196,
          242,
        ]),
      );
    });

    test('merges repeated want entries like Boxo', () {
      final message = Message();
      message.addWantlistEntry('cid', priority: 1, wantType: WantType.have);
      message.addWantlistEntry(
        'cid',
        priority: 2,
        wantType: WantType.block,
        sendDontHave: true,
      );
      message.addWantlistEntry('cid', priority: 3, cancel: true);

      final entry = message.getWantlist().entries['cid']!;
      expect(entry.wantType, WantType.block);
      expect(entry.priority, 3);
      expect(entry.sendDontHave, isTrue);
      expect(entry.cancel, isTrue);
    });

    test('rejects CIDs with trailing bytes like cid.Cast', () async {
      final block = await Block.fromData(Uint8List.fromList([1, 2, 3]));
      final wantlist = pb.Message_Wantlist()
        ..entries.add(
          pb.Message_Wantlist_Entry()..block = [...block.cid.toBytes(), 0],
        );

      await expectLater(
        () => Message.fromBytes(
          (pb.Message()..wantlist = wantlist).writeToBuffer(),
        ),
        throwsFormatException,
      );
    });

    test('follows Go identity-prefix length semantics', () async {
      final payload = pb.Message()
        ..payload.add(
          pb.Message_Block()
            ..prefix = [1, 0x55, 0, 1]
            ..data = [1, 2],
        );

      final decoded = await Message.fromBytes(payload.writeToBuffer());
      expect(decoded.getBlocks().single.cid.multihash.name, 'identity');
      expect(decoded.getBlocks().single.cid.multihash.size, 2);
    });

    test(
      'rejects an invalid payload prefix and oversized inbound message',
      () async {
        final invalid = pb.Message()
          ..payload.add(
            pb.Message_Block()
              ..prefix = [1, 0x55, 0x12, 33]
              ..data = [1],
          );

        await expectLater(
          () => Message.fromBytes(invalid.writeToBuffer()),
          throwsFormatException,
        );
        await expectLater(
          () => Message.fromBytes(Uint8List(Message.maxMessageSize + 1)),
          throwsFormatException,
        );
      },
    );

    test('a 2 MiB block fits the 4 MiB libp2p message limit', () async {
      final block = await Block.fromData(Uint8List(2 * 1024 * 1024));
      final bytes = (Message()..addBlock(block)).toBytes();

      expect(bytes.length, lessThanOrEqualTo(Message.maxMessageSize));
      expect(
        (await Message.fromBytes(bytes)).getBlocks().single.data.length,
        block.data.length,
      );
    });
  });

  group('WantlistEntry', () {
    test('constructor with defaults', () {
      final entry = WantlistEntry(cid: 'QmTest');
      expect(entry.cid, equals('QmTest'));
      expect(entry.priority, equals(1));
      expect(entry.cancel, isFalse);
      expect(entry.wantType, equals(WantType.block));
      expect(entry.sendDontHave, isFalse);
    });

    test('constructor with all parameters', () {
      final entry = WantlistEntry(
        cid: 'QmTest',
        priority: 10,
        cancel: true,
        wantType: WantType.have,
        sendDontHave: true,
      );
      expect(entry.priority, equals(10));
      expect(entry.cancel, isTrue);
      expect(entry.wantType, equals(WantType.have));
      expect(entry.sendDontHave, isTrue);
    });
  });

  group('Wantlist', () {
    test('addEntry and contains', () {
      final wantlist = Wantlist();
      final entry = WantlistEntry(cid: 'QmTest');

      wantlist.addEntry(entry);
      expect(wantlist.contains('QmTest'), isTrue);
      expect(wantlist.entries, hasLength(1));
    });

    test('removeEntry', () {
      final wantlist = Wantlist();
      final entry = WantlistEntry(cid: 'QmTest');

      wantlist.addEntry(entry);
      expect(wantlist.contains('QmTest'), isTrue);

      wantlist.removeEntry('QmTest');
      expect(wantlist.contains('QmTest'), isFalse);
    });

    test('addEntry updates existing entry', () {
      final wantlist = Wantlist();
      final entry1 = WantlistEntry(cid: 'QmTest', priority: 1);
      final entry2 = WantlistEntry(cid: 'QmTest', priority: 10);

      wantlist.addEntry(entry1);
      wantlist.addEntry(entry2);

      expect(wantlist.entries, hasLength(1));
      expect(wantlist.entries['QmTest']?.priority, equals(10));
    });
  });

  group('BlockPresence', () {
    test('constructor', () {
      final presence = BlockPresence(
        cid: 'QmTest',
        type: BlockPresenceType.have,
      );
      expect(presence.cid, equals('QmTest'));
      expect(presence.type, equals(BlockPresenceType.have));
    });

    test('constructor with dontHave type', () {
      final presence = BlockPresence(
        cid: 'QmTest',
        type: BlockPresenceType.dontHave,
      );
      expect(presence.type, equals(BlockPresenceType.dontHave));
    });
  });

  group('WantType enum', () {
    test('enum values exist', () {
      expect(WantType.block, isNotNull);
      expect(WantType.have, isNotNull);
    });
  });

  group('BlockPresenceType enum', () {
    test('enum values exist', () {
      expect(BlockPresenceType.have, isNotNull);
      expect(BlockPresenceType.dontHave, isNotNull);
    });
  });
}
