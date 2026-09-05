import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:ipfs_libp2p/core/crypto/keys.dart';
import 'package:ipfs_libp2p/core/multiaddr.dart';
import 'package:ipfs_libp2p/core/network/conn.dart';
import 'package:ipfs_libp2p/core/network/context.dart';
import 'package:ipfs_libp2p/core/network/rcmgr.dart';
import 'package:ipfs_libp2p/core/network/stream.dart';
import 'package:ipfs_libp2p/core/network/transport_conn.dart';
import 'package:ipfs_libp2p/core/peer/peer_id.dart';
import 'package:test/test.dart';
import 'package:transpiled_ipfs/src/transport/go_yamux_adapter.dart';

class _MemoryConn implements TransportConn {
  _MemoryConn(Stream<Uint8List> incoming, this._outgoing)
    : _incoming = StreamQueue(incoming);

  final StreamQueue<Uint8List> _incoming;
  final StreamSink<Uint8List> _outgoing;
  bool _closed = false;

  @override
  Future<Uint8List> read([int? length]) async {
    final bytes = await _incoming.next;
    if (length == null || bytes.length <= length) return bytes;
    throw StateError('test transport only returns complete chunks');
  }

  @override
  Future<void> write(Uint8List data) async {
    if (!_closed) _outgoing.add(Uint8List.fromList(data));
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _outgoing.close();
  }

  @override
  String get id => 'memory';
  @override
  Future<P2PStream<dynamic>> newStream(Context context) =>
      throw UnimplementedError();
  @override
  Future<List<P2PStream<dynamic>>> get streams async => const [];
  @override
  bool get isClosed => _closed;
  @override
  PeerId get localPeer => throw UnimplementedError();
  @override
  PeerId get remotePeer => throw UnimplementedError();
  @override
  Future<PublicKey?> get remotePublicKey async => null;
  @override
  ConnState get state => throw UnimplementedError();
  @override
  MultiAddr get localMultiaddr => throw UnimplementedError();
  @override
  MultiAddr get remoteMultiaddr => throw UnimplementedError();
  @override
  Socket get socket => throw UnimplementedError();
  @override
  ConnStats get stat => throw UnimplementedError();
  @override
  ConnScope get scope => NullScope();
  @override
  void setReadTimeout(Duration timeout) {}
  @override
  void setWriteTimeout(Duration timeout) {}
  @override
  void notifyActivity() {}
}

(TransportConn, TransportConn) _pair() {
  final aToB = StreamController<Uint8List>();
  final bToA = StreamController<Uint8List>();
  return (
    _MemoryConn(bToA.stream, aToB.sink),
    _MemoryConn(aToB.stream, bToA.sink),
  );
}

void main() {
  test('uses the Go adapter limit and moves a stream over Yamux', () async {
    expect(goYamuxProtocolId, '/yamux/1.0.0');
    expect(goYamuxConfig.maxIncomingStreams, 0xffffffff);

    final (clientTransport, serverTransport) = _pair();
    final client = GoYamuxMultiplexer(clientTransport, true);
    final server = GoYamuxMultiplexer(serverTransport, false);
    final accepted = server.acceptStream();
    final clientConn = await client.newConnOnTransport(
      clientTransport,
      false,
      NullScope(),
    );
    final serverConn = await server.newConnOnTransport(
      serverTransport,
      true,
      NullScope(),
    );

    final outgoing = await clientConn.openStream(Context());
    final incoming = await accepted;
    expect(outgoing, isA<P2PStream<Uint8List>>());
    expect(incoming.id(), '1');
    await incoming.setProtocol('/test/1.0.0');
    await outgoing.write(Uint8List.fromList([1, 2, 3]));
    expect(await incoming.read(), [1, 2, 3]);

    await outgoing.close();
    await incoming.close();
    await client.close();
    await server.close();
    expect(serverConn.isClosed, isTrue);
  });
}
