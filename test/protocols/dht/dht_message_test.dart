import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_ipfs/src/protocols/dht/dht_message.dart';
import 'package:transpiled_ipfs/transpiled_ipfs.dart';
import 'package:transpiled_varint/transpiled_varint.dart';

void main() {
  test('GET_PROVIDERS and peer response preserve upstream wire fields', () {
    final cid = CID.decode(
      'bafkreibs723667mosvbz3kzygkbpaxkkg6zld7qmxrbh3ky2mreeoyjlue',
    );
    final request = encodeGetProviders(cid);
    final (_, frameLength) = readVarint(request, 0);
    final payload = request.sublist(frameLength);
    expect(payload.sublist(0, 4), [0x08, 0x03, 0x12, 0x22]);
    expect(payload.sublist(payload.length - 2), [0x50, 0x01]);

    final peerId = PeerId.decode(
      '12D3KooWCryG7Mon9orvQxcS1rYZjotPgpwoJNHHKcLLfE4Hf5mV',
    );
    final address = addrInfoFromString(
      '/ip4/127.0.0.1/tcp/4001/p2p/${peerId.toBase58()}',
    ).addrs.single;
    final peer = _message([
      _bytes(1, peerId.value),
      _bytes(2, address.toBytes()),
      _varint(3, 2),
    ]);
    final response = DhtResponse.fromBytes(_message([_bytes(9, peer)]));
    expect(response.closerPeers, isEmpty);
    expect(response.providerPeers, [
      AddrInfo(id: peerId, addrs: [address]),
    ]);
  });
}

Uint8List _message(List<Uint8List> fields) =>
    Uint8List.fromList(fields.expand((field) => field).toList());

Uint8List _bytes(int field, Uint8List value) => Uint8List.fromList([
  ...encodeVarint((field << 3) | 2),
  ...encodeVarint(value.length),
  ...value,
]);

Uint8List _varint(int field, int value) =>
    Uint8List.fromList([...encodeVarint(field << 3), ...encodeVarint(value)]);
