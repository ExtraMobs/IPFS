// ignore_for_file: public_member_api_docs, strict_raw_type

import 'dart:async';
import 'dart:typed_data';

import 'package:ipfs_libp2p/core/crypto/keys.dart' as libp2p_keys;
import 'package:ipfs_libp2p/core/multiaddr.dart' as libp2p_addr;
import 'package:ipfs_libp2p/core/network/common.dart' as libp2p_common;
import 'package:ipfs_libp2p/core/network/conn.dart' as libp2p_conn;
import 'package:ipfs_libp2p/core/network/context.dart' as libp2p_context;
import 'package:ipfs_libp2p/core/network/mux.dart' as core_mux;
import 'package:ipfs_libp2p/core/network/rcmgr.dart' as libp2p_rcmgr;
import 'package:ipfs_libp2p/core/network/stream.dart' as libp2p_stream;
import 'package:ipfs_libp2p/core/network/transport_conn.dart';
import 'package:ipfs_libp2p/core/peer/peer_id.dart' as libp2p_peer;
import 'package:ipfs_libp2p/p2p/transport/multiplexing/multiplexer.dart';
import 'package:transpiled_go_yamux/transpiled_go_yamux.dart' as go_yamux;

/// The libp2p Yamux protocol identifier.
const String goYamuxProtocolId = '/yamux/1.0.0';

/// Go's adapter delegates the effective stream limit to the resource manager.
const int goYamuxMaxIncomingStreams = 0xffffffff;

/// Yamux settings used by go-libp2p's adapter.
const go_yamux.YamuxConfig goYamuxConfig = go_yamux.YamuxConfig(
  maxIncomingStreams: goYamuxMaxIncomingStreams,
);

/// A `ipfs_libp2p` multiplexer backed by the audited `go-yamux` port.
final class GoYamuxMultiplexer implements Multiplexer {
  GoYamuxMultiplexer(
    libp2p_conn.Conn secureConnection,
    bool isClient, {
    go_yamux.YamuxConfig config = goYamuxConfig,
  }) : _connection = _transportOf(secureConnection),
       _isClient = isClient,
       _config = config {
    _bridge = _TransportBridge(_connection);
    _session = go_yamux.YamuxSession(
      _bridge,
      config: config,
      isClient: isClient,
    );
    _muxedConnection = _GoYamuxConn(
      _connection,
      _session,
      isClient: isClient,
      onAccepted: _onAccepted,
    );
  }

  final TransportConn _connection;
  final bool _isClient;
  final go_yamux.YamuxConfig _config;
  late final _TransportBridge _bridge;
  late final go_yamux.YamuxSession _session;
  late final _GoYamuxConn _muxedConnection;
  final _incoming = StreamController<libp2p_stream.P2PStream>.broadcast();
  Future<void> Function(libp2p_stream.P2PStream stream)? _streamHandler;

  @override
  String get protocolId => goYamuxProtocolId;

  @override
  Future<libp2p_stream.P2PStream> acceptStream() => _muxedConnection
      .acceptStream()
      .then((stream) => stream as libp2p_stream.P2PStream);

  @override
  Future<List<libp2p_stream.P2PStream>> get streams => _muxedConnection.streams;

  @override
  Stream<libp2p_stream.P2PStream> get incomingStreams => _incoming.stream;

  @override
  Future<void> close() async {
    await _muxedConnection.close();
    if (!_incoming.isClosed) await _incoming.close();
  }

  @override
  bool get isClosed => _session.isClosed;

  @override
  int get maxStreams => _config.maxIncomingStreams;

  @override
  int get numStreams => _session.numStreams;

  @override
  bool get canCreateStream => !isClosed && numStreams < maxStreams;

  @override
  void setStreamHandler(
    Future<void> Function(libp2p_stream.P2PStream stream) handler,
  ) {
    _streamHandler = handler;
  }

  @override
  void removeStreamHandler() {
    _streamHandler = null;
  }

  @override
  Future<core_mux.MuxedConn> newConnOnTransport(
    TransportConn secureConnection,
    bool isServer,
    libp2p_rcmgr.PeerScope scope,
  ) async {
    if (!identical(secureConnection, _connection)) {
      throw ArgumentError('secure connection does not belong to this muxer');
    }
    if (isServer == _isClient) {
      throw ArgumentError('isServer does not match the muxer endpoint');
    }
    return _muxedConnection;
  }

  void _onAccepted(libp2p_stream.P2PStream stream) {
    if (!_incoming.isClosed) _incoming.add(stream);
    final handler = _streamHandler;
    if (handler != null) unawaited(handler(stream));
  }

  static TransportConn _transportOf(libp2p_conn.Conn connection) {
    if (connection is! TransportConn) {
      throw ArgumentError(
        'GoYamuxMultiplexer requires a secure TransportConn, got '
        '${connection.runtimeType}',
      );
    }
    return connection;
  }
}

/// Factory suitable for `Config.muxers`.
Multiplexer goYamuxFactory(libp2p_conn.Conn secureConnection, bool isClient) =>
    GoYamuxMultiplexer(secureConnection, isClient);

final class _TransportBridge implements go_yamux.YamuxTransport {
  _TransportBridge(this._connection) {
    _pump();
  }

  final TransportConn _connection;
  final _input = StreamController<List<int>>();
  bool _closed = false;

  @override
  Stream<List<int>> get input => _input.stream;

  Future<void> _pump() async {
    try {
      while (!_closed) {
        final bytes = await _connection.read();
        if (bytes.isEmpty) break;
        if (!_input.isClosed) _input.add(bytes);
      }
    } catch (error, stack) {
      if (!_input.isClosed) _input.addError(error, stack);
    } finally {
      if (!_input.isClosed) await _input.close();
    }
  }

  @override
  Future<void> write(Uint8List bytes) => _connection.write(bytes);

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_input.isClosed) await _input.close();
    await _connection.close();
  }
}

final class _GoYamuxConn implements libp2p_conn.Conn, core_mux.MuxedConn {
  _GoYamuxConn(
    this._connection,
    this._session, {
    required this.isClient,
    required this.onAccepted,
  });

  final TransportConn _connection;
  final go_yamux.YamuxSession _session;
  final bool isClient;
  final void Function(libp2p_stream.P2PStream stream) onAccepted;
  final _streams = <int, _GoYamuxStream>{};

  @override
  Future<core_mux.MuxedStream> openStream(
    libp2p_context.Context context,
  ) async {
    final stream = _wrap(await _session.openStream());
    return stream;
  }

  @override
  Future<core_mux.MuxedStream> acceptStream() async {
    final stream = _wrap(await _session.acceptStream(), incoming: true);
    onAccepted(stream);
    return stream;
  }

  _GoYamuxStream _wrap(go_yamux.YamuxStream stream, {bool? incoming}) {
    return _streams.putIfAbsent(
      stream.id,
      () => _GoYamuxStream(
        stream,
        this,
        incoming: incoming ?? !isClient,
        onClosed: () => _streams.remove(stream.id),
      ),
    );
  }

  @override
  Future<void> close() => _session.close();

  @override
  bool get isClosed => _session.isClosed;

  @override
  String get id => _connection.id;

  @override
  Future<libp2p_stream.P2PStream> newStream(
    libp2p_context.Context context,
  ) async => await openStream(context) as libp2p_stream.P2PStream;

  @override
  Future<List<libp2p_stream.P2PStream>> get streams async =>
      List.unmodifiable(_streams.values);

  @override
  libp2p_peer.PeerId get localPeer => _connection.localPeer;

  @override
  libp2p_peer.PeerId get remotePeer => _connection.remotePeer;

  @override
  Future<libp2p_keys.PublicKey?> get remotePublicKey =>
      _connection.remotePublicKey;

  @override
  libp2p_conn.ConnState get state {
    final state = _connection.state;
    return libp2p_conn.ConnState(
      streamMultiplexer: goYamuxProtocolId,
      security: state.security,
      transport: state.transport,
      usedEarlyMuxerNegotiation: state.usedEarlyMuxerNegotiation,
    );
  }

  @override
  libp2p_addr.MultiAddr get localMultiaddr => _connection.localMultiaddr;

  @override
  libp2p_addr.MultiAddr get remoteMultiaddr => _connection.remoteMultiaddr;

  @override
  libp2p_conn.ConnStats get stat => _connection.stat;

  @override
  libp2p_rcmgr.ConnScope get scope => _connection.scope;
}

final class _GoYamuxStream
    implements libp2p_stream.P2PStream<Uint8List>, core_mux.MuxedStream {
  _GoYamuxStream(
    this._stream,
    this._connection, {
    required bool incoming,
    required this.onClosed,
  }) : _incomingSide = incoming;

  final go_yamux.YamuxStream _stream;
  final _GoYamuxConn _connection;
  final bool _incomingSide;
  final void Function() onClosed;
  String _protocol = '';
  DateTime? _deadline;
  DateTime? _readDeadline;
  DateTime? _writeDeadline;
  bool _notifiedClosed = false;

  @override
  String id() => _stream.id.toString();

  @override
  String protocol() => _protocol;

  @override
  Future<void> setProtocol(String id) async {
    _protocol = id;
  }

  @override
  libp2p_stream.StreamStats stat() => libp2p_stream.StreamStats(
    direction: _incomingSide
        ? libp2p_common.Direction.inbound
        : libp2p_common.Direction.outbound,
    opened: DateTime.now(),
  );

  @override
  libp2p_conn.Conn get conn => _connection;

  @override
  libp2p_rcmgr.StreamManagementScope scope() => libp2p_rcmgr.NullScope();

  @override
  Future<Uint8List> read([int? maxLength]) async {
    if (maxLength != null && maxLength <= 0) throw RangeError('maxLength');
    // The external multistream negotiator may otherwise consume application
    // bytes coalesced into the same Yamux DATA frame. Before setProtocol it
    // only needs a byte stream, so avoid leaving bytes in its private buffer.
    final readLength = _protocol.isEmpty ? 1 : (maxLength ?? 65536);
    final data = await _withDeadline(
      _stream.read(maxLength ?? readLength),
      _readDeadline ?? _deadline,
    );
    return data ?? Uint8List(0);
  }

  @override
  Future<void> write(List<int> data) => _withDeadline(
    _stream.write(Uint8List.fromList(data)),
    _writeDeadline ?? _deadline,
  );

  @override
  libp2p_stream.P2PStream<Uint8List> get incoming => this;

  @override
  bool get isClosed => _stream.isClosed;

  @override
  bool get isWritable => !isClosed;

  @override
  Future<void> close() async {
    await _stream.close();
    _notifyClosed();
  }

  @override
  Future<void> closeWrite() => _stream.closeWrite();

  @override
  Future<void> closeRead() => _stream.closeRead();

  @override
  Future<void> reset() async {
    await _stream.reset();
    _notifyClosed();
  }

  @override
  Future<void> setDeadline(DateTime? time) async {
    _deadline = time;
  }

  @override
  Future<void> setReadDeadline(DateTime time) async {
    _readDeadline = time;
  }

  @override
  Future<void> setWriteDeadline(DateTime time) async {
    _writeDeadline = time;
  }

  Future<T> _withDeadline<T>(Future<T> operation, DateTime? deadline) {
    if (deadline == null) return operation;
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return Future<T>.error(TimeoutException('stream deadline exceeded'));
    }
    return operation.timeout(remaining);
  }

  void _notifyClosed() {
    if (!_notifiedClosed) {
      _notifiedClosed = true;
      onClosed();
    }
  }
}
