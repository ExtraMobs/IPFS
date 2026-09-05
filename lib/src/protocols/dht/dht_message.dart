import 'dart:typed_data';

import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';
import 'package:transpiled_multiaddr/transpiled_multiaddr.dart';
import 'package:transpiled_varint/transpiled_varint.dart';

/// Maximum decoded DHT message size, in bytes.
const int dhtMessageSizeMax = 1 << 22;

/// Maximum encoded peer record size, in bytes.
const int dhtPeerSizeMax = 8 << 10;

/// Encodes a DHT `GET_PROVIDERS` request for [cid].
Uint8List encodeGetProviders(CID cid) {
  final payload = BytesBuilder()
    ..add(_varintField(1, 3))
    ..add(_bytesField(2, Uint8List.fromList(cid.multihash.toBytes())))
    ..add(_varintField(10, 1));
  final bytes = payload.takeBytes();
  return Uint8List.fromList([...encodeVarint(bytes.length), ...bytes]);
}

/// Decoded response returned by a DHT provider query.
final class DhtResponse {
  /// Creates a response containing closer peers and providers.
  const DhtResponse({required this.closerPeers, required this.providerPeers});

  /// Decodes a protobuf DHT response from [bytes].
  factory DhtResponse.fromBytes(Uint8List bytes) {
    final closer = <AddrInfo>[];
    final providers = <AddrInfo>[];
    final reader = _ProtoReader(bytes);
    while (!reader.isDone) {
      final (field, wire) = reader.tag();
      if ((field == 8 || field == 9) && wire == 2) {
        final peerBytes = reader.bytes();
        if (peerBytes.length > dhtPeerSizeMax) continue;
        final peer = _decodePeer(peerBytes);
        if (peer != null) (field == 8 ? closer : providers).add(peer);
      } else {
        reader.skip(wire);
      }
    }
    return DhtResponse(closerPeers: closer, providerPeers: providers);
  }

  /// Peers closer to the requested key.
  final List<AddrInfo> closerPeers;

  /// Peers advertising themselves as providers.
  final List<AddrInfo> providerPeers;
}

AddrInfo? _decodePeer(Uint8List bytes) {
  Uint8List? id;
  final addrs = <Multiaddr>[];
  final reader = _ProtoReader(bytes);
  while (!reader.isDone) {
    final (field, wire) = reader.tag();
    if (field == 1 && wire == 2) {
      id = Uint8List.fromList(reader.bytes());
    } else if (field == 2 && wire == 2) {
      try {
        addrs.add(Multiaddr.fromBytes(Uint8List.fromList(reader.bytes())));
      } on FormatException {
        // go-libp2p drops malformed addresses but retains the peer.
      }
    } else {
      reader.skip(wire);
    }
  }
  if (id == null || id.isEmpty) return null;
  try {
    return AddrInfo(id: PeerId.fromBytes(id), addrs: addrs);
  } on FormatException {
    return null;
  }
}

Uint8List _bytesField(int field, Uint8List value) => Uint8List.fromList([
  ...encodeVarint((field << 3) | 2),
  ...encodeVarint(value.length),
  ...value,
]);

Uint8List _varintField(int field, int value) =>
    Uint8List.fromList([...encodeVarint(field << 3), ...encodeVarint(value)]);

final class _ProtoReader {
  _ProtoReader(this.data);
  final Uint8List data;
  int offset = 0;
  bool get isDone => offset == data.length;

  (int, int) tag() {
    final value = varint();
    if (value >> 3 == 0) throw const FormatException('Invalid protobuf field');
    return (value >> 3, value & 7);
  }

  int varint() {
    final (value, length) = readVarint(data, offset);
    offset += length;
    return value;
  }

  Uint8List bytes() {
    final length = varint();
    final end = offset + length;
    if (end > data.length) throw const FormatException('Truncated protobuf');
    final result = Uint8List.sublistView(data, offset, end);
    offset = end;
    return result;
  }

  void skip(int wire) {
    switch (wire) {
      case 0:
        varint();
        return;
      case 1:
        _advance(8);
        return;
      case 2:
        _advance(varint());
        return;
      case 5:
        _advance(4);
        return;
      default:
        throw FormatException('Unsupported protobuf wire type $wire');
    }
  }

  void _advance(int count) {
    offset += count;
    if (offset > data.length) throw const FormatException('Truncated protobuf');
  }
}
