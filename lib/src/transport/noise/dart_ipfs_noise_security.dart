// lib/src/transport/noise/dart_ipfs_noise_security.dart
//
// Implements ipfs_libp2p's `SecurityProtocol` (p2p/security/security_protocol.dart)
// using this repo's own, Go-vector-validated Noise implementation
// (noise_state.dart + noise_handshake_payload.dart) instead of
// ipfs_libp2p's built-in `NoiseSecurity`
// (lib/p2p/security/noise/noise_protocol.dart).
//
// Why this exists: ipfs_libp2p is a third-party pub.dev package, not
// editable in this repo. Its own NoiseSecurity hardcodes
// `Ed25519PublicKey.unmarshal()` when parsing a REMOTE peer's identity
// key out of the handshake payload (`_verifyHandshakePayload`, and
// duplicated inline in `secureOutbound`/`secureInbound`), regardless of
// the `KeyType` actually present in the payload -- so it silently
// misinterprets (and thus fails to authenticate) any real peer whose
// identity key is RSA, Secp256k1, or ECDSA, not just the local-identity
// Ed25519 check its `create()` factory also happens to enforce. That
// combination is what blocked connecting to real, non-Ed25519 peers.
//
// This class fixes that by dispatching the remote identity key through
// transpiled_libp2p's generic `key_codec.dart` (RSA/Ed25519/Secp256k1/ECDSA
// all handled uniformly), while still reusing ipfs_libp2p's own
// `SecuredConnection` for the post-handshake transport -- its internal
// AEAD framing (2-byte length prefix, ChaCha20-Poly1305, empty AAD,
// 4-zero-byte + little-endian-counter nonce) was verified byte-for-byte
// against go-libp2p's own p2p/security/noise/rw.go before choosing to
// reuse it rather than reimplement it.
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as pkg_crypto;
import 'package:ipfs_libp2p/core/crypto/keys.dart' as libp2p_keys;
import 'package:ipfs_libp2p/core/crypto/pb/crypto.pb.dart' as libp2p_crypto_pb;
import 'package:ipfs_libp2p/core/network/transport_conn.dart';
import 'package:ipfs_libp2p/core/peer/peer_id.dart' as libp2p_peer;
import 'package:ipfs_libp2p/p2p/security/secured_connection.dart';
import 'package:ipfs_libp2p/p2p/security/security_protocol.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';

/// The multistream-select protocol ID for Noise, per go-libp2p (and
/// matching ipfs_libp2p's own `NoiseSecurity.protocolIdForState`, so
/// this negotiates identically over the wire).
const String noiseProtocolId = '/noise';

/// Thrown when a Noise handshake over [TransportConn] fails -- framing,
/// crypto, or identity verification errors are all wrapped in this so
/// callers can distinguish security-layer failures from raw I/O ones.
class DartIpfsNoiseException implements Exception {
  /// Creates a [DartIpfsNoiseException] with a [message] and optional
  /// [cause].
  DartIpfsNoiseException(this.message, [this.cause]);

  /// The error message.
  final String message;

  /// The underlying error, if this wraps one.
  final Object? cause;

  @override
  String toString() =>
      'DartIpfsNoiseException: $message${cause != null ? ' ($cause)' : ''}';
}

/// A [SecurityProtocol] implementation backed by this repo's own Noise
/// handshake (see the file doc comment for why this exists instead of
/// using ipfs_libp2p's own `NoiseSecurity`).
class DartIpfsNoiseSecurity implements SecurityProtocol {
  /// Creates a Noise security transport that authenticates as
  /// [localIdentityKey] (any of transpiled_libp2p's four supported key
  /// types).
  DartIpfsNoiseSecurity(this.localIdentityKey);

  /// This node's libp2p identity private key, used to sign the Noise
  /// handshake payload.
  final PrivKey localIdentityKey;

  @override
  String get protocolId => noiseProtocolId;

  @override
  Future<SecuredConnection> secureOutbound(TransportConn connection) =>
      _runHandshake(connection, initiator: true);

  @override
  Future<SecuredConnection> secureInbound(TransportConn connection) =>
      _runHandshake(connection, initiator: false);

  Future<SecuredConnection> _runHandshake(
    TransportConn connection, {
    required bool initiator,
  }) async {
    try {
      final localStatic = await generateNoiseKeyPair();
      final hs = await HandshakeState.initialize(
        initiator: initiator,
        staticKeyPair: localStatic,
      );

      Uint8List? remotePayload;
      (CipherState, CipherState)? split;

      if (initiator) {
        // msg 0: -> e (no payload)
        final (m0, _) = await hs.writeMessage(Uint8List(0));
        await _writeFramed(connection, m0);

        // msg 1: <- e, ee, s, es + responder's identity payload
        final m1 = await _readFramed(connection);
        final (p1, _) = await hs.readMessage(m1);
        remotePayload = p1;

        // msg 2: -> s, se + our identity payload
        final ourPayload = await generateNoiseHandshakePayload(
          localIdentityKey: localIdentityKey,
          localNoiseStaticPublicKey: localStatic.publicKeyBytes,
        );
        final (m2, s) = await hs.writeMessage(ourPayload);
        await _writeFramed(connection, m2);
        split = s;
      } else {
        // msg 0: <- e (no payload)
        final m0 = await _readFramed(connection);
        await hs.readMessage(m0);

        // msg 1: -> e, ee, s, es + our identity payload
        final ourPayload = await generateNoiseHandshakePayload(
          localIdentityKey: localIdentityKey,
          localNoiseStaticPublicKey: localStatic.publicKeyBytes,
        );
        final (m1, _) = await hs.writeMessage(ourPayload);
        await _writeFramed(connection, m1);

        // msg 2: <- s, se + initiator's identity payload
        final m2 = await _readFramed(connection);
        final (p2, s) = await hs.readMessage(m2);
        remotePayload = p2;
        split = s;
      }

      if (split == null) {
        throw DartIpfsNoiseException('handshake did not complete (no split cipher states)');
      }
      final remoteStatic = hs.remoteStaticKey;
      if (remoteStatic == null) {
        throw DartIpfsNoiseException('handshake completed without a remote static key');
      }

      final remoteIdentity = await verifyNoiseHandshakePayload(remotePayload, remoteStatic);

      // Per go-libp2p's setCipherStates: the initiator's write-direction
      // cipher state is cs1 (the first Split() output) and its
      // read-direction is cs2; the responder is the mirror image.
      final (cs1, cs2) = split;
      final (encState, decState) = initiator ? (cs1, cs2) : (cs2, cs1);

      return SecuredConnection(
        connection,
        pkg_crypto.SecretKey(encState.keyBytes!),
        pkg_crypto.SecretKey(decState.keyBytes!),
        establishedRemotePeer: libp2p_peer.PeerId(remoteIdentity.peerId.value),
        establishedRemotePublicKey: _toLibp2pPublicKey(remoteIdentity.publicKey),
        securityProtocolId: noiseProtocolId,
      );
    } catch (e) {
      await connection.close();
      if (e is DartIpfsNoiseException) rethrow;
      throw DartIpfsNoiseException('Noise handshake failed', e);
    }
  }

  /// Bridges a verified `transpiled_libp2p` public key into ipfs_libp2p's
  /// own `PublicKey` type (needed for `SecuredConnection`'s
  /// `establishedRemotePublicKey`), by re-decoding the same protobuf
  /// wire bytes through ipfs_libp2p's own dispatcher -- both packages
  /// implement the same crypto.proto, so the bytes are interchangeable.
  /// Returns `null` if ipfs_libp2p doesn't support this key type at all
  /// (e.g. it has no Secp256k1 unmarshaller registered) rather than
  /// failing the whole handshake over a field `SecuredConnection` only
  /// uses as an optional convenience.
  libp2p_keys.PublicKey? _toLibp2pPublicKey(PubKey pubKey) {
    try {
      final bytes = marshalPublicKey(pubKey);
      final pmes = libp2p_crypto_pb.PublicKey.fromBuffer(bytes);
      return libp2p_keys.publicKeyFromProto(pmes);
    } catch (_) {
      return null;
    }
  }
}

Future<void> _writeFramed(TransportConn connection, Uint8List message) async {
  final framed = Uint8List(2 + message.length);
  framed[0] = (message.length >> 8) & 0xff;
  framed[1] = message.length & 0xff;
  framed.setAll(2, message);
  await connection.write(framed);
}

Future<Uint8List> _readFramed(TransportConn connection) async {
  final lengthBytes = await _readExact(connection, 2);
  final length = (lengthBytes[0] << 8) | lengthBytes[1];
  if (length == 0) return Uint8List(0);
  return _readExact(connection, length);
}

/// Reads exactly [length] bytes from [connection], looping since the
/// underlying transport isn't guaranteed to fill a single `read()` call
/// (mirrors `SecuredConnection`'s own `_readFullMessage`, and Go's
/// `io.ReadFull`).
Future<Uint8List> _readExact(TransportConn connection, int length) async {
  final buffer = BytesBuilder();
  while (buffer.length < length) {
    final chunk = await connection.read(length - buffer.length);
    if (chunk.isEmpty) {
      throw DartIpfsNoiseException(
        'connection closed mid-handshake: expected $length bytes, got ${buffer.length}',
      );
    }
    buffer.add(chunk);
  }
  return buffer.toBytes();
}
