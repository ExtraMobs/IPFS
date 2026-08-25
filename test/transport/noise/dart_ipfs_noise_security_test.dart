// test/transport/noise/dart_ipfs_noise_security_test.dart
//
// End-to-end test for lib/src/transport/noise/dart_ipfs_noise_security.dart:
// runs a real Noise XX handshake between two DartIpfsNoiseSecurity
// instances over an in-memory duplex fake TransportConn, then exercises
// the resulting (real, ipfs_libp2p-provided) SecuredConnection's
// read/write. The individual pieces (HandshakeState, the handshake
// payload) are already validated against real Go vectors elsewhere;
// this proves THIS file's new orchestration -- message sequencing,
// framing, and the cs1/cs2 -> enc/dec direction mapping -- is wired
// correctly, and specifically that a non-Ed25519 (RSA) identity, which
// ipfs_libp2p's own built-in NoiseSecurity cannot authenticate, works
// end-to-end here.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:dart_ipfs/src/core/types/peer_id.dart';
import 'package:dart_ipfs/src/transport/noise/dart_ipfs_noise_security.dart';
import 'package:dart_ipfs_core/dart_ipfs_core.dart';
import 'package:ipfs_libp2p/core/crypto/keys.dart' as libp2p_keys;
import 'package:ipfs_libp2p/core/multiaddr.dart';
import 'package:ipfs_libp2p/core/network/conn.dart';
import 'package:ipfs_libp2p/core/network/context.dart';
import 'package:ipfs_libp2p/core/network/rcmgr.dart';
import 'package:ipfs_libp2p/core/network/stream.dart';
import 'package:ipfs_libp2p/core/network/transport_conn.dart';
import 'package:ipfs_libp2p/core/peer/peer_id.dart' as libp2p_peer;
import 'package:test/test.dart';

class _FakeTransportConn implements TransportConn {
  _FakeTransportConn(Stream<Uint8List> incoming, this._outgoing)
    : _incoming = StreamQueue(incoming);

  final StreamQueue<Uint8List> _incoming;
  final StreamSink<Uint8List> _outgoing;
  final List<int> _buffer = <int>[];
  bool _closed = false;

  @override
  Future<Uint8List> read([int? length]) async {
    if (length == null) {
      if (_buffer.isNotEmpty) {
        final out = Uint8List.fromList(_buffer);
        _buffer.clear();
        return out;
      }
      return _incoming.next;
    }
    while (_buffer.length < length) {
      final chunk = await _incoming.next;
      _buffer.addAll(chunk);
    }
    final out = Uint8List.fromList(_buffer.sublist(0, length));
    _buffer.removeRange(0, length);
    return out;
  }

  @override
  Future<void> write(Uint8List data) async {
    _outgoing.add(data);
  }

  @override
  Future<void> close() async {
    _closed = true;
  }

  @override
  String get id => 'fake-conn';

  @override
  Future<P2PStream<dynamic>> newStream(Context context) => throw UnimplementedError();

  @override
  Future<List<P2PStream<dynamic>>> get streams async => const [];

  @override
  bool get isClosed => _closed;

  @override
  libp2p_peer.PeerId get localPeer => throw UnimplementedError();

  @override
  libp2p_peer.PeerId get remotePeer => throw UnimplementedError();

  @override
  Future<libp2p_keys.PublicKey?> get remotePublicKey async => null;

  @override
  ConnState get state => throw UnimplementedError();

  @override
  MultiAddr get localMultiaddr => throw UnimplementedError();

  @override
  MultiAddr get remoteMultiaddr => throw UnimplementedError();

  @override
  Socket get socket => throw UnimplementedError();

  @override
  void setReadTimeout(Duration timeout) {}

  @override
  void setWriteTimeout(Duration timeout) {}

  @override
  void notifyActivity() {}

  @override
  ConnStats get stat => throw UnimplementedError();

  @override
  ConnScope get scope => throw UnimplementedError();
}

(TransportConn, TransportConn) _duplexPair() {
  final aToB = StreamController<Uint8List>();
  final bToA = StreamController<Uint8List>();
  final a = _FakeTransportConn(bToA.stream, aToB.sink);
  final b = _FakeTransportConn(aToB.stream, bToA.sink);
  return (a, b);
}

void main() {
  group('DartIpfsNoiseSecurity -- end-to-end handshake', () {
    test('two Ed25519 identities complete a handshake and exchange data', () async {
      final initiatorKey = await generateEd25519KeyPair();
      final responderKey = await generateEd25519KeyPair();
      final (connA, connB) = _duplexPair();

      final initiatorSecurity = DartIpfsNoiseSecurity(initiatorKey);
      final responderSecurity = DartIpfsNoiseSecurity(responderKey);

      final results = await Future.wait([
        initiatorSecurity.secureOutbound(connA),
        responderSecurity.secureInbound(connB),
      ]);
      final securedA = results[0];
      final securedB = results[1];

      // A's view of the remote peer (B) must match B's own real identity,
      // and vice versa.
      expect(
        securedA.establishedRemotePeer?.toBase58(),
        equals(PeerId.fromPublicKey(responderKey.getPublic().raw(), type: 'ed25519').toBase58()),
      );
      expect(
        securedB.establishedRemotePeer?.toBase58(),
        equals(PeerId.fromPublicKey(initiatorKey.getPublic().raw(), type: 'ed25519').toBase58()),
      );

      final message = Uint8List.fromList('hello from the initiator'.codeUnits);
      await securedA.write(message);
      final received = await securedB.read(message.length);
      expect(received, equals(message));

      final reply = Uint8List.fromList('hello back from the responder'.codeUnits);
      await securedB.write(reply);
      final receivedReply = await securedA.read(reply.length);
      expect(receivedReply, equals(reply));
    });

    test('an RSA identity (which ipfs_libp2p\'s own NoiseSecurity rejects) completes a handshake', () async {
      final initiatorKey = generateRsaKeyPair(minRsaKeyBits);
      final responderKey = await generateEd25519KeyPair();
      final (connA, connB) = _duplexPair();

      final initiatorSecurity = DartIpfsNoiseSecurity(initiatorKey);
      final responderSecurity = DartIpfsNoiseSecurity(responderKey);

      final results = await Future.wait([
        initiatorSecurity.secureOutbound(connA),
        responderSecurity.secureInbound(connB),
      ]);
      final securedA = results[0];
      final securedB = results[1];

      // The responder must have correctly recognized and authenticated
      // the initiator's key as RSA (not silently misread it as Ed25519,
      // the way ipfs_libp2p's own NoiseSecurity would) -- proven by the
      // derived PeerId matching. `establishedRemotePublicKey` itself is
      // left null here: ipfs_libp2p's own RsaPublicKey.unmarshal expects
      // a bare PKCS1 SEQUENCE{n,e}, not the PKIX SubjectPublicKeyInfo
      // dart_ipfs_core (correctly, matching x509.MarshalPKIXPublicKey)
      // produces -- a separate, pre-existing gap in ipfs_libp2p's own
      // RSA support that DartIpfsNoiseSecurity degrades past gracefully
      // rather than failing the whole handshake over an optional field.
      expect(securedB.establishedRemotePublicKey, isNull);
      expect(
        securedB.establishedRemotePeer!.toBase58(),
        equals(PeerId.fromPublicKey(initiatorKey.getPublic().raw(), type: 'rsa').toBase58()),
      );

      final message = Uint8List.fromList(List<int>.generate(500, (i) => i % 256));
      await securedA.write(message);
      final received = await securedB.read(message.length);
      expect(received, equals(message));
    });

    test('a large write spanning multiple frames round-trips correctly', () async {
      final initiatorKey = await generateEd25519KeyPair();
      final responderKey = await generateEd25519KeyPair();
      final (connA, connB) = _duplexPair();

      final results = await Future.wait([
        DartIpfsNoiseSecurity(initiatorKey).secureOutbound(connA),
        DartIpfsNoiseSecurity(responderKey).secureInbound(connB),
      ]);
      final securedA = results[0];
      final securedB = results[1];

      final message = Uint8List.fromList(List<int>.generate(150000, (i) => i % 256));
      await securedA.write(message);

      final received = BytesBuilder();
      while (received.length < message.length) {
        received.add(await securedB.read(message.length - received.length));
      }
      expect(received.toBytes(), equals(message));
    });
  });
}
