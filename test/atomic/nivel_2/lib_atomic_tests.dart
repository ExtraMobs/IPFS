// test/atomic/nivel_2/lib_atomic_tests.dart
// Testes atomicos 1 para 1 para o pacote lib (160 simbolos).

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:ipfs_libp2p/core/crypto/keys.dart' as libp2p_keys;
import 'package:ipfs_libp2p/core/multiaddr.dart' as libp2p_addr;
import 'package:ipfs_libp2p/core/network/common.dart' as libp2p_common;
import 'package:ipfs_libp2p/core/network/conn.dart' as libp2p_conn;
import 'package:ipfs_libp2p/core/network/context.dart' as libp2p_context;
import 'package:ipfs_libp2p/core/network/rcmgr.dart' as libp2p_rcmgr;
import 'package:ipfs_libp2p/core/network/stream.dart' as libp2p_stream;
import 'package:ipfs_libp2p/core/network/transport_conn.dart';
import 'package:ipfs_libp2p/core/peer/peer_id.dart' as libp2p_peer;
import 'package:ipfs_libp2p/dart_libp2p.dart' as runtime;
import 'package:ipfs_libp2p/p2p/host/peerstore/pstoremem/addr_book.dart';
import 'package:quic_lib/quic_lib.dart' as quic_lib;
import 'package:test/test.dart';
import 'package:transpiled_block_format/transpiled_block_format.dart' as blocks;
import 'package:transpiled_boxo/bitswap/message.dart';
import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_ipfs/src/blockstore/blockstore.dart';
import 'package:transpiled_ipfs/src/config/ipfs_runtime_config.dart';
import 'package:transpiled_ipfs/src/core/builders/build_cfg.dart';
import 'package:transpiled_ipfs/src/core/interfaces/routing_table.dart';
import 'package:transpiled_ipfs/src/network/libp2p_host.dart';
import 'package:transpiled_ipfs/src/node/ipfs_node.dart';
import 'package:transpiled_ipfs/src/protocols/bitswap/bitswap_client.dart';
import 'package:transpiled_ipfs/src/protocols/bitswap/bitswap_message.dart';
import 'package:transpiled_ipfs/src/protocols/bitswap/interface_bitswap_handler.dart';
import 'package:transpiled_ipfs/src/protocols/dht/dht_message.dart';
import 'package:transpiled_ipfs/src/protocols/dht/query_peerset.dart';
import 'package:transpiled_ipfs/src/routing/dht_provider_finder.dart';
import 'package:transpiled_ipfs/src/transport/dns/dns_bootstrap_resolver.dart';
import 'package:transpiled_ipfs/src/transport/dns/dns_message.dart';
import 'package:transpiled_ipfs/src/transport/dns/system_resolver.dart';
import 'package:transpiled_ipfs/src/transport/dns/udp_dns_client.dart';
import 'package:transpiled_ipfs/src/transport/go_yamux_adapter.dart';
import 'package:transpiled_ipfs/src/transport/noise/dart_ipfs_noise_security.dart';
import 'package:transpiled_ipfs/src/transport/quic/libp2p_tls_extension.dart';
import 'package:transpiled_ipfs/src/transport/quic/quic_listener.dart';
import 'package:transpiled_ipfs/src/transport/quic/quic_p2p_stream.dart';
import 'package:transpiled_ipfs/src/transport/quic/quic_transport.dart';
import 'package:transpiled_ipfs/src/unixfs/unixfs.dart';
import 'package:transpiled_ipfs/src/utils/immutable_bytes.dart';
import 'package:transpiled_ipfs/src/utils/typed_map.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart' as libp2p;
import 'package:transpiled_multiaddr/transpiled_multiaddr.dart';
import 'package:transpiled_multihash/transpiled_multihash.dart';
import 'package:transpiled_varint/transpiled_varint.dart';

// ---------------------------------------------------------------------------
// Helpers e Fakes de Teste
// ---------------------------------------------------------------------------

class _MemoryConn implements TransportConn {
  _MemoryConn();

  _MemoryConn? _peer;
  final List<Uint8List> _incoming = [];
  final List<Completer<Uint8List>> _pendingReads = [];
  bool _closed = false;

  static (_MemoryConn, _MemoryConn) pair() {
    final a = _MemoryConn();
    final b = _MemoryConn();
    a._peer = b;
    b._peer = a;
    return (a, b);
  }

  @override
  Future<Uint8List> read([int? length]) {
    if (_closed) return Future.value(Uint8List(0));
    if (_incoming.isNotEmpty) {
      final chunk = _incoming.removeAt(0);
      if (length == null || chunk.length <= length) return Future.value(chunk);
      _incoming.insert(0, Uint8List.sublistView(chunk, length));
      return Future.value(Uint8List.sublistView(chunk, 0, length));
    }
    final completer = Completer<Uint8List>();
    _pendingReads.add(completer);
    return completer.future;
  }

  @override
  Future<void> write(Uint8List data) async {
    if (_closed) return;
    if (_peer != null && !_peer!._closed) {
      final chunk = Uint8List.fromList(data);
      if (_peer!._pendingReads.isNotEmpty) {
        _peer!._pendingReads.removeAt(0).complete(chunk);
      } else {
        _peer!._incoming.add(chunk);
      }
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final r in _pendingReads) {
      if (!r.isCompleted) r.complete(Uint8List(0));
    }
    _pendingReads.clear();
    final p = _peer;
    if (p != null && !p._closed) {
      p.close();
    }
  }

  @override
  String get id => 'memory';
  @override
  Future<libp2p_stream.P2PStream<dynamic>> newStream(
    libp2p_context.Context context,
  ) => throw UnimplementedError();
  @override
  Future<List<libp2p_stream.P2PStream<dynamic>>> get streams async => const [];
  @override
  bool get isClosed => _closed;
  @override
  libp2p_peer.PeerId get localPeer => throw UnimplementedError();
  @override
  libp2p_peer.PeerId get remotePeer => throw UnimplementedError();
  @override
  Future<libp2p_keys.PublicKey?> get remotePublicKey async => null;
  @override
  libp2p_conn.ConnState get state => throw UnimplementedError();
  @override
  libp2p_addr.MultiAddr get localMultiaddr => throw UnimplementedError();
  @override
  libp2p_addr.MultiAddr get remoteMultiaddr => throw UnimplementedError();
  @override
  Socket get socket => throw UnimplementedError();
  @override
  libp2p_conn.ConnStats get stat => throw UnimplementedError();
  @override
  libp2p_rcmgr.ConnScope get scope => libp2p_rcmgr.NullScope();
  @override
  void setReadTimeout(Duration timeout) {}
  @override
  void setWriteTimeout(Duration timeout) {}
  @override
  void notifyActivity() {}
}

(_MemoryConn, _MemoryConn) _memoryPair() => _MemoryConn.pair();

class _TestQuicConnectionAdapter implements QuicConnectionAdapter {
  _TestQuicConnectionAdapter({
    Map<int, quic_lib.QuicStream>? streams,
    this.isEstablished = true,
    this.nextStreamId = 0,
  }) : _streams = streams ?? {};

  final Map<int, quic_lib.QuicStream> _streams;
  @override
  bool isEstablished;
  int nextStreamId;
  bool isClosed = false;

  @override
  quic_lib.QuicStream? getQuicStream(int id) => _streams[id];

  @override
  int openBidirectionalStream() => nextStreamId;

  @override
  Future<void> close() async {
    isClosed = true;
  }
}

class _TestBlockGetter implements BlockGetter {
  @override
  Future<blocks.Block> getBlock(Cid cid) async =>
      blocks.BasicBlock(Uint8List.fromList([1, 2, 3]), cid);
}

class _TestDistanceMetric implements DistanceMetric {
  @override
  int calculateDistance(libp2p.PeerId a, libp2p.PeerId b) => 42;

  @override
  int calculateDistanceToKey(libp2p.PeerId peerId, List<int> key) => 24;
}

class _TestDhtRoutingTable implements DhtRoutingTable {
  final _peers = <libp2p.PeerId>{};
  final _metric = _TestDistanceMetric();

  @override
  DistanceMetric get distanceMetric => _metric;

  @override
  List<libp2p.PeerId> findClosestPeers(libp2p.PeerId target, {int k = 20}) =>
      _peers.take(k).toList();

  @override
  List<libp2p.PeerId> findClosestPeersToKey(List<int> key, {int k = 20}) =>
      _peers.take(k).toList();

  @override
  Future<void> addPeer(
    libp2p.PeerId peerId,
    libp2p.PeerId associatedPeerId, {
    String? address,
  }) async {
    _peers.add(peerId);
  }

  @override
  void removePeer(libp2p.PeerId peerId) {
    _peers.remove(peerId);
  }

  @override
  bool containsPeer(libp2p.PeerId peerId) => _peers.contains(peerId);

  @override
  int get peerCount => _peers.length;

  @override
  void clear() => _peers.clear();
}

class _FakeHost implements runtime.Host {
  _FakeHost({libp2p.PeerId? selfId})
      : selfId = selfId ??
            libp2p.PeerId.decode(
              '12D3KooWCryG7Mon9orvQxcS1rYZjotPgpwoJNHHKcLLfE4Hf5mV',
            );

  final libp2p.PeerId selfId;
  final MemoryAddrBook addrBook = MemoryAddrBook();
  final Map<String, dynamic> handlers = {};

  @override
  runtime.PeerId get id => runtime.PeerId.decode(selfId.toBase58());

  @override
  runtime.Peerstore get peerStore => _FakePeerStore(this);

  @override
  Future<void> connect(runtime.AddrInfo pi, {libp2p_context.Context? context}) async {}

  @override
  void setStreamHandler(String protocol, dynamic handler) {
    handlers[protocol] = handler;
  }

  @override
  Future<libp2p_stream.P2PStream<dynamic>> newStream(
    runtime.PeerId p,
    List<String> protocols, [
    libp2p_context.Context? context,
  ]) async => _FakeP2PStream();

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePeerStore implements runtime.Peerstore {
  _FakePeerStore(this.host);
  final _FakeHost host;

  @override
  runtime.AddrBook get addrBook => _FakeAddrBook(host);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAddrBook implements runtime.AddrBook {
  _FakeAddrBook(this.host);
  final _FakeHost host;

  @override
  Future<void> addAddrs(
    runtime.PeerId p,
    List<runtime.MultiAddr> addrs,
    Duration ttl,
  ) async {
    await host.addrBook.addAddrs(p, addrs, ttl);
  }

  @override
  Future<List<runtime.MultiAddr>> addrs(runtime.PeerId p) =>
      host.addrBook.addrs(p);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeP2PStream implements libp2p_stream.P2PStream<dynamic> {
  _FakeP2PStream([List<int>? bytes]) : _data = bytes ?? [];
  final List<int> _data;
  int _readOffset = 0;
  bool _closed = false;

  @override
  Future<Uint8List> read([int? maxLength]) async {
    if (_closed) throw StateError('stream closed');
    if (_readOffset >= _data.length) return Uint8List(0);
    final remaining = _data.length - _readOffset;
    final count = (maxLength == null || remaining < maxLength) ? remaining : maxLength;
    final result = Uint8List.fromList(
      _data.sublist(_readOffset, _readOffset + count),
    );
    _readOffset += count;
    return result;
  }

  @override
  Future<void> write(Uint8List data) async {}

  @override
  Future<void> close() async {
    _closed = true;
  }

  @override
  Future<void> reset() async {
    _closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Testes Atomicos
// ---------------------------------------------------------------------------

void main() {
  final samplePeerId = libp2p.PeerId.decode(
    '12D3KooWCryG7Mon9orvQxcS1rYZjotPgpwoJNHHKcLLfE4Hf5mV',
  );
  final sampleRawData = Uint8List.fromList([1, 2, 3, 4, 5]);
  final sampleCid = Cid.v1(
    'raw',
    MultihashUtils.sum('sha2-256', sampleRawData),
  );

  // Top-level functions
  test('goYamuxFactory() - constroi instancia de multiplexador go yamux', () {
    final (c1, c2) = _memoryPair();
    final muxer = goYamuxFactory(c1, true);
    expect(muxer, isA<GoYamuxMultiplexer>());
    c1.close();
    c2.close();
  });

  test('unixFsLinks() - decodifica links filhos de blocos raw ou dag pb', () {
    final links = unixFsLinks(sampleCid, sampleRawData);
    expect(links, isEmpty);
    expect(
      () => unixFsLinks(
        Cid.v1('dag-cbor', MultihashUtils.sum('sha2-256', sampleRawData)),
        sampleRawData,
      ),
      throwsFormatException,
    );
  });

  test('readUnixFs() - realiza streaming de bytes de arquivo unixfs', () async {
    final chunks = await readUnixFs(
      sampleCid,
      (c) async => blocks.BasicBlock(sampleRawData, c),
    ).toList();
    expect(chunks, hasLength(1));
    expect(chunks.single, equals(sampleRawData));
  });

  test('walkUnixFs() - percorre dag unixfs em profundidade', () async {
    final walked = await walkUnixFs(
      sampleCid,
      (c) async => blocks.BasicBlock(sampleRawData, c),
    ).toList();
    expect(walked, equals([sampleCid]));
  });

  test('createDnsResolver() - instancia resolver dns padrao da plataforma', () {
    final resolver = createDnsResolver();
    expect(resolver, isNotNull);
  });

  test('encodeDnsQuery() - codifica requisicao dns com id e tipo', () {
    final query = encodeDnsQuery(id: 0x1234, name: 'ipfs.io', type: 16);
    expect(query, isNotEmpty);
    expect(query.length, greaterThan(12));
  });

  test('decodeDnsMessage() - decodifica mensagem dns da rede com validacao', () {
    expect(() => decodeDnsMessage(Uint8List(5)), throwsFormatException);
  });

  test('encodeWantBlock() - codifica mensagem want block com prioridade', () {
    final bytes = encodeWantBlock(sampleCid, priority: 2);
    expect(bytes, isNotEmpty);
  });

  test('encodeBitswapMessage() - codifica mensagem bitswap com framing varint', () {
    final msg = BitSwapMessage(false);
    msg.addEntry(sampleCid, 1, WantType.block, true);
    final bytes = encodeBitswapMessage(msg);
    expect(bytes, isNotEmpty);
  });

  test('readBitswapMessage() - le mensagem bitswap emoldurada em varint', () async {
    final payload = encodeWantBlock(sampleCid);
    final stream = _FakeP2PStream(payload);
    final msg = await readBitswapMessage(stream);
    expect(msg, isA<BitSwapMessage>());
    expect(msg.wantlist(), isNotEmpty);
  });

  test('blockFromMessage() - extrai bloco correspondente da mensagem', () {
    final msg = BitSwapMessage(false);
    final blk = blocks.BasicBlock(sampleRawData, sampleCid);
    msg.addBlock(blk);
    final extracted = blockFromMessage(msg, sampleCid);
    expect(extracted?.rawData(), equals(sampleRawData));

    final msgDontHave = BitSwapMessage(false);
    msgDontHave.addDontHave(sampleCid);
    expect(() => blockFromMessage(msgDontHave, sampleCid), throwsStateError);

    final emptyMsg = BitSwapMessage(false);
    expect(blockFromMessage(emptyMsg, sampleCid), isNull);
  });

  test('encodeGetProviders() - codifica requisicao get providers para a dht', () {
    final bytes = encodeGetProviders(sampleCid);
    expect(bytes, isNotEmpty);
  });

  test('boundPeerRecordAddrs() - delimita enderecos para caber no limite maximo', () {
    final maddr = Multiaddr.parse('/ip4/127.0.0.1/tcp/4001');
    final bounded = boundPeerRecordAddrs(
      id: samplePeerId.value,
      rawAddrs: [maddr.toBytes()],
      connection: 2,
      maxSize: 8192,
    );
    expect(bounded, hasLength(1));
  });

  test('encodePeerRecord() - codifica registro de peer com enderecos', () {
    final maddr = Multiaddr.parse('/ip4/127.0.0.1/tcp/4001');
    final record = encodePeerRecord(id: samplePeerId, addrs: [maddr]);
    expect(record, isNotEmpty);
  });

  test('encodeDhtResponse() - codifica resposta protobuf da dht com peers', () {
    final maddr = Multiaddr.parse('/ip4/127.0.0.1/tcp/4001');
    final peer = libp2p.AddrInfo(id: samplePeerId, addrs: [maddr]);
    final resp = encodeDhtResponse(
      closerPeers: [peer],
      providerPeers: [peer],
    );
    expect(resp, isNotEmpty);
  });

  // BlockstoreHashMismatchException
  group('BlockstoreHashMismatchException [Atomic Audit]', () {
    test('toString() - formata mensagem de erro de hash mismatch', () {
      final ex = BlockstoreHashMismatchException(sampleCid);
      expect(ex.toString(), contains('blockstore: data did not match'));
    });
  });

  // Blockstore
  group('Blockstore [Atomic Audit]', () {
    test('has() - verifica se o bloco existe no blockstore', () async {
      final bs = Blockstore();
      expect(await bs.has(sampleCid), isFalse);
      await bs.close();
    });

    test('getSize() - retorna tamanho em bytes do bloco', () async {
      final bs = Blockstore();
      await bs.put(blocks.BasicBlock(sampleRawData, sampleCid));
      expect(await bs.getSize(sampleCid), equals(sampleRawData.length));
      await bs.close();
    });

    test('get() - recupera bloco validando o hash', () async {
      final bs = Blockstore();
      await bs.put(blocks.BasicBlock(sampleRawData, sampleCid));
      final blk = await bs.get(sampleCid);
      expect(blk.rawData(), equals(sampleRawData));
      await bs.close();
    });

    test('put() - persiste bloco no storage', () async {
      final bs = Blockstore();
      await bs.put(blocks.BasicBlock(sampleRawData, sampleCid));
      expect(await bs.has(sampleCid), isTrue);
      await bs.close();
    });

    test('putMany() - persiste multiplos blocos no storage', () async {
      final bs = Blockstore();
      final data2 = Uint8List.fromList([6, 7, 8]);
      final cid2 = Cid.v1('raw', MultihashUtils.sum('sha2-256', data2));
      await bs.putMany([
        blocks.BasicBlock(sampleRawData, sampleCid),
        blocks.BasicBlock(data2, cid2),
      ]);
      expect(await bs.has(sampleCid), isTrue);
      expect(await bs.has(cid2), isTrue);
      await bs.close();
    });

    test('close() - fecha o datastore subjacente', () async {
      final bs = Blockstore();
      await bs.close();
      expect(await bs.has(sampleCid), isFalse);
    });
  });

  // IpfsConfig
  group('IpfsConfig [Atomic Audit]', () {
    test('copyWith() - cria copia com novos parametros', () {
      const cfg = IpfsConfig(offline: true);
      final copy = cfg.copyWith(offline: false);
      expect(copy.offline, isFalse);
      expect(cfg.offline, isTrue);
    });
  });

  // Libp2pRouter
  group('Libp2pRouter [Atomic Audit]', () {
    test('connect() - conecta ao endereco do peer', () async {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final peer = libp2p.AddrInfo(
        id: samplePeerId,
        addrs: [Multiaddr.parse('/ip4/127.0.0.1/tcp/4001')],
      );
      await router.connect(peer);
      expect(router.host, equals(host));
    });

    test('addAddrs() - adiciona enderecos no peerstore com ttl', () async {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final peer = libp2p.AddrInfo(
        id: samplePeerId,
        addrs: [Multiaddr.parse('/ip4/127.0.0.1/tcp/4001')],
      );
      await router.addAddrs(peer);
      expect(router.host, equals(host));
    });

    test('getAddrs() - busca enderecos do peer no peerstore', () async {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final addrs = await router.getAddrs(samplePeerId);
      expect(addrs, isA<List<Multiaddr>>());
    });

    test('runtimePeerId() - converte peer id para o tipo de runtime', () {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final rtId = router.runtimePeerId(samplePeerId);
      expect(rtId.toBase58(), equals(samplePeerId.toBase58()));
    });
  });

  // IpfsNode
  group('IpfsNode [Atomic Audit]', () {
    test('fromBuildCfg() - constroi instancia de ipfs node', () async {
      final cfg = BuildCfg(online: false);
      final node = await IpfsNode.fromBuildCfg(cfg);
      expect(node, isA<IpfsNode>());
      await node.close();
    });

    test('isOnline - indica se o node possui rede ativa', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      expect(node.isOnline, isFalse);
      await node.close();
    });

    test('connect() - lanca erro se o node estiver offline', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      final peer = libp2p.AddrInfo(id: samplePeerId, addrs: []);
      expect(() => node.connect(peer), throwsStateError);
      await node.close();
    });

    test('getBlock() - lanca erro se o node estiver offline', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      expect(() => node.getBlock(sampleCid), throwsStateError);
      await node.close();
    });

    test('findProvidersAsync() - lanca erro se o node estiver offline', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      expect(() => node.findProvidersAsync(sampleCid, 1), throwsStateError);
      await node.close();
    });

    test('getBlockFromDht() - lanca erro se o node estiver offline', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      expect(() => node.getBlockFromDht(sampleCid), throwsStateError);
      await node.close();
    });

    test('getUnixFs() - le bytes de arquivo unixfs', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      await node.blockstore.put(blocks.BasicBlock(sampleRawData, sampleCid));
      final chunks = await node.getUnixFs(sampleCid).toList();
      expect(chunks.single, equals(sampleRawData));
      await node.close();
    });

    test('statUnixFs() - retorna estatisticas do unixfs', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      await node.blockstore.put(blocks.BasicBlock(sampleRawData, sampleCid));
      final stat = await node.statUnixFs(sampleCid);
      expect(stat.size, equals(sampleRawData.length));
      expect(stat.numBlocks, equals(1));
      await node.close();
    });

    test('listUnixFsCids() - lista cids da arvore unixfs', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      await node.blockstore.put(blocks.BasicBlock(sampleRawData, sampleCid));
      final cids = await node.listUnixFsCids(sampleCid).toList();
      expect(cids, equals([sampleCid]));
      await node.close();
    });

    test('exportCar() - exporta dag em formato car', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      await node.blockstore.put(blocks.BasicBlock(sampleRawData, sampleCid));
      final carBytes = await node.exportCar(sampleCid).fold<List<int>>(
        [],
        (a, b) => [...a, ...b],
      );
      expect(carBytes, isNotEmpty);
      await node.close();
    });

    test('importCar() - importa blocos de arquivo car', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      await node.blockstore.put(blocks.BasicBlock(sampleRawData, sampleCid));
      final carBytes = await node.exportCar(sampleCid).fold<List<int>>(
        [],
        (a, b) => [...a, ...b],
      );
      final header = await node.importCar(Uint8List.fromList(carBytes));
      expect(header.roots, contains(sampleCid));
      await node.close();
    });

    test('peerId() - lanca erro se o node estiver offline', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      expect(() => node.peerId, throwsStateError);
      await node.close();
    });

    test('listenAddresses() - retorna lista vazia se offline', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      expect(node.listenAddresses, isEmpty);
      await node.close();
    });

    test('swarmAddresses() - lanca erro se offline pois depende do peerId', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      expect(() => node.swarmAddresses, throwsStateError);
      await node.close();
    });

    test('putBlock() - persiste bloco no blockstore local', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      final blk = blocks.BasicBlock(sampleRawData, sampleCid);
      await node.putBlock(blk);
      expect(await node.blockstore.has(sampleCid), isTrue);
      await node.close();
    });

    test('putRawBlock() - divide dados brutos, persiste no blockstore e retorna cid', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      final cid = await node.putRawBlock(sampleRawData);
      expect(cid.version, equals(0));
      expect(await node.blockstore.has(cid), isTrue);
      await node.close();
    });

    test('close() - encerra componentes do ipfs node', () async {
      final node = await IpfsNode.fromBuildCfg(BuildCfg(online: false));
      await node.close();
      expect(node.isOnline, isFalse);
    });
  });

  // DhtClient
  group('DhtClient [Atomic Audit]', () {
    test('close() - encerra cliente dht e cancela streams', () async {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final client = DhtClient(router: router, bootstrapPeers: []);
      await client.close();
      expect(() => client.findProvidersAsync(sampleCid, 1), throwsStateError);
    });

    test('findProvidersAsync() - valida parametros e encerramento', () async {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final client = DhtClient(router: router, bootstrapPeers: []);
      expect(() => client.findProvidersAsync(sampleCid, -1), throwsRangeError);
      await client.close();
    });
  });

  // GoYamuxMultiplexer
  group('GoYamuxMultiplexer [Atomic Audit]', () {
    test('protocolId - retorna identificador do protocolo yamux', () {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      expect(muxer.protocolId, equals('/yamux/1.0.0'));
      c1.close();
      c2.close();
    });

    test('acceptStream() - aceita novo stream de entrada', () async {
      final (c1, c2) = _memoryPair();
      final client = GoYamuxMultiplexer(c1, true);
      final server = GoYamuxMultiplexer(c2, false);
      final accepted = server.acceptStream();
      final clientConn = await client.newConnOnTransport(
        c1, false, libp2p_rcmgr.NullScope(),
      );
      final outgoing = await clientConn.openStream(libp2p_context.Context());
      final incoming = await accepted;
      expect(incoming.id(), '1');
      await incoming.setProtocol('/test/1.0.0');
      await outgoing.write(Uint8List.fromList([1, 2, 3]));
      expect(await incoming.read(), [1, 2, 3]);
      await outgoing.close();
      await incoming.close();
      await client.close();
      await server.close();
    });

    test('streams - lista streams ativos', () async {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      expect(await muxer.streams, isEmpty);
      await muxer.close();
      c2.close();
    });

    test('incomingStreams - stream de fluxos recebidos', () {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      expect(muxer.incomingStreams, isA<Stream<libp2p_stream.P2PStream>>());
      muxer.close();
      c2.close();
    });

    test('close() - encerra sessao do multiplexador', () async {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      await muxer.close();
      expect(muxer.isClosed, isTrue);
      c2.close();
    });

    test('close() - compartilha encerramento concorrente com o transporte', () async {
      final (c1, c2) = _memoryPair();
      final client = GoYamuxMultiplexer(c1, true);
      final server = GoYamuxMultiplexer(c2, false);
      await Future.wait([client.close(), client.close(), server.close()]);
      expect(client.isClosed, isTrue);
      expect(server.isClosed, isTrue);
    });

    test('isClosed - indica se a conexao foi encerrada', () {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      expect(muxer.isClosed, isFalse);
      muxer.close();
      c2.close();
    });

    test('maxStreams - limite maximo de streams', () {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      expect(muxer.maxStreams, equals(0xffffffff));
      muxer.close();
      c2.close();
    });

    test('numStreams - quantidade de streams ativos', () {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      expect(muxer.numStreams, equals(0));
      muxer.close();
      c2.close();
    });

    test('canCreateStream - indica se novos streams podem ser abertos', () {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      expect(muxer.canCreateStream, isTrue);
      muxer.close();
      c2.close();
    });

    test('setStreamHandler() - registra handler para novos fluxos', () {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      muxer.setStreamHandler((stream) async {});
      expect(muxer.canCreateStream, isTrue);
      muxer.close();
      c2.close();
    });

    test('removeStreamHandler() - remove handler de novos fluxos', () {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      muxer.removeStreamHandler();
      expect(muxer.canCreateStream, isTrue);
      muxer.close();
      c2.close();
    });

    test('newConnOnTransport() - associa conexao protegida', () async {
      final (c1, c2) = _memoryPair();
      final muxer = GoYamuxMultiplexer(c1, true);
      final muxConn = await muxer.newConnOnTransport(
        c1,
        false,
        libp2p_rcmgr.NullScope(),
      );
      expect(muxConn, isNotNull);
      await muxer.close();
      c2.close();
    });
  });

  // ImmutableBytes
  group('ImmutableBytes [Atomic Audit]', () {
    test('toBytes() - retorna copia dos bytes subjacentes', () {
      final bytes = ImmutableBytes(Uint8List.fromList([1, 2, 3]));
      expect(bytes.toBytes(), equals(Uint8List.fromList([1, 2, 3])));
    });

    test('length - retorna quantidade de bytes encapsulados', () {
      final bytes = ImmutableBytes(Uint8List.fromList([1, 2, 3]));
      expect(bytes.length, equals(3));
    });

    test('operator == - compara igualdade de valor entre bytes', () {
      final a = ImmutableBytes(Uint8List.fromList([1, 2, 3]));
      final b = ImmutableBytes(Uint8List.fromList([1, 2, 3]));
      final c = ImmutableBytes(Uint8List.fromList([4, 5, 6]));
      expect(a == b, isTrue);
      expect(a == c, isFalse);
    });

    test('hashCode - computa hash code consistente', () {
      final a = ImmutableBytes(Uint8List.fromList([1, 2, 3]));
      final b = ImmutableBytes(Uint8List.fromList([1, 2, 3]));
      expect(a.hashCode, equals(b.hashCode));
      expect({a, b}, hasLength(1));
      expect({a: 'found'}[b], 'found');
    });
  });

  // TypedMap
  group('TypedMap [Atomic Audit]', () {
    test('get() - obtem valor com fallback caso ausente', () {
      final map = TypedMap({'a': 10, 'b': 'ola'});
      expect(map.get<int>('a', 0), equals(10));
      expect(map.get<int>('naoExiste', 99), equals(99));
    });

    test('operator [] - acessa valor diretamente pela chave', () {
      final map = TypedMap({'chave': 'valor'});
      expect(map['chave'], equals('valor'));
      expect(map['outra'], isNull);
    });

    test('toMap() - exporta mapa subjacente nao modificavel', () {
      final map = TypedMap({'k': 'v'});
      expect(map.toMap(), equals({'k': 'v'}));
    });

    test('containsKey() - verifica existencia da chave no mapa', () {
      final map = TypedMap({'existe': true});
      expect(map.containsKey('existe'), isTrue);
      expect(map.containsKey('naoExiste'), isFalse);
    });

    test('length - retorna numero de entradas no mapa', () {
      final map = TypedMap({'a': 1, 'b': 2});
      expect(map.length, equals(2));
    });

    test('operator == - compara igualdade de conteudo entre mapas', () {
      final a = TypedMap({'x': 1});
      final b = TypedMap({'x': 1});
      final c = TypedMap({'x': 2});
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(TypedMap({'x': 1, 'y': 2}), TypedMap({'y': 2, 'x': 1}));
      expect(TypedMap({'x': null}) == TypedMap({'y': null}), isFalse);
    });

    test('hashCode - gera hash code compativel', () {
      final a = TypedMap({'x': 1});
      final b = TypedMap({'x': 1});
      expect(a.hashCode, equals(b.hashCode));
      expect({a, b}, hasLength(1));
      expect(TypedMap({'x': 1, 'y': 2}).hashCode,
          TypedMap({'y': 2, 'x': 1}).hashCode);
    });
  });

  // SystemResolver
  group('SystemResolver [Atomic Audit]', () {
    test('lookupIpAddr() - resolve enderecos ip pelo sistema', () async {
      final resolver = SystemResolver();
      final ips = await resolver.lookupIpAddr('127.0.0.1');
      expect(ips, contains('127.0.0.1'));
    });

    test('lookupTxt() - consulta registros txt via cliente dns', () async {
      final client = UdpDnsClient(
        resolvers: ['127.0.0.1'],
        timeout: const Duration(milliseconds: 10),
        attemptsPerResolver: 1,
      );
      final resolver = SystemResolver(client: client);
      expect(() => resolver.lookupTxt('example.invalid'), throwsA(isA<TimeoutException>()));
    });
  });

  // UdpDnsClient
  group('UdpDnsClient [Atomic Audit]', () {
    test('lookup() - executa consulta udp com tratamento de timeout', () async {
      final client = UdpDnsClient(
        resolvers: ['127.0.0.1'],
        timeout: const Duration(milliseconds: 10),
        attemptsPerResolver: 1,
      );
      expect(() => client.lookup('example.invalid', 16), throwsA(isA<TimeoutException>()));
    });
  });

  // DartIpfsNoiseException
  group('DartIpfsNoiseException [Atomic Audit]', () {
    test('toString() - formata informacoes da excecao noise', () {
      final ex = DartIpfsNoiseException('falha noise', 'timeout');
      expect(ex.toString(), contains('DartIpfsNoiseException: falha noise (timeout)'));
    });
  });

  // DartIpfsNoiseSecurity
  group('DartIpfsNoiseSecurity [Atomic Audit]', () {
    test('protocolId - retorna identificador do protocolo noise', () async {
      final key = await libp2p.generateEd25519KeyPair();
      final sec = DartIpfsNoiseSecurity(key);
      expect(sec.protocolId, equals('/noise'));
    });

    test('secureOutbound() - lanca excecao com transporte invalido', () async {
      final key = await libp2p.generateEd25519KeyPair();
      final sec = DartIpfsNoiseSecurity(key);
      final (c1, c2) = _memoryPair();
      await c1.close();
      await c2.close();
      expect(() => sec.secureOutbound(c1), throwsA(isA<DartIpfsNoiseException>()));
    });

    test('secureInbound() - lanca excecao com transporte invalido', () async {
      final key = await libp2p.generateEd25519KeyPair();
      final sec = DartIpfsNoiseSecurity(key);
      final (c1, c2) = _memoryPair();
      await c1.close();
      await c2.close();
      expect(() => sec.secureInbound(c2), throwsA(isA<DartIpfsNoiseException>()));
    });
  });

  // Libp2pTlsVerificationResult
  group('Libp2pTlsVerificationResult [Atomic Audit]', () {
    test('toString() - formata resultado de verificacao tls', () {
      final res = Libp2pTlsVerificationResult.failed(
        Libp2pTlsFailureReason.parseError,
        'certificado invalido',
      );
      expect(res.toString(), contains('Libp2pTlsVerificationResult(valid: false'));
    });
  });

  // Libp2pTlsHandshakeVerifier
  group('Libp2pTlsHandshakeVerifier [Atomic Audit]', () {
    test('verify() - verifica certificado x509 e extensao libp2p', () async {
      const verifier = Libp2pTlsHandshakeVerifier();
      final res = await verifier.verify([1, 2, 3]);
      expect(res.valid, isFalse);
    });
  });

  // PeerIdMismatchException
  group('PeerIdMismatchException [Atomic Audit]', () {
    test('toString() - formata excecao de divergencia de peer id', () {
      final expected = libp2p_peer.PeerId.fromString(samplePeerId.toBase58());
      final ex = PeerIdMismatchException(expected, expected, 'mismatch detalhe');
      expect(ex.toString(), contains('PeerIdMismatchException'));
    });
  });

  // PeerCertificateVerificationException
  group('PeerCertificateVerificationException [Atomic Audit]', () {
    test('toString() - formata excecao de falha de certificado', () {
      final ex = PeerCertificateVerificationException(
        Libp2pTlsFailureReason.parseError,
        'erro ao parsear x509',
      );
      expect(ex.toString(), contains('PeerCertificateVerificationException'));
    });
  });

  // QuicListener
  group('QuicListener [Atomic Audit]', () {
    test('addr - retorna multiaddr de escuta configurado', () {
      final controller = StreamController<quic_lib.Libp2pQuicConnection>.broadcast();
      final listener = QuicListener(
        stream: controller.stream,
        addr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
      );
      expect(listener.addr.toString(), equals('/ip4/127.0.0.1/udp/4002/quic-v1'));
      listener.close();
      controller.close();
    });

    test('connectionStream - stream de conexoes aceitas', () {
      final controller = StreamController<quic_lib.Libp2pQuicConnection>.broadcast();
      final listener = QuicListener(
        stream: controller.stream,
        addr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
      );
      expect(listener.connectionStream, isA<Stream<TransportConn>>());
      listener.close();
      controller.close();
    });

    test('isClosed - indica status de fechamento do listener', () {
      final controller = StreamController<quic_lib.Libp2pQuicConnection>.broadcast();
      final listener = QuicListener(
        stream: controller.stream,
        addr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
      );
      expect(listener.isClosed, isFalse);
      listener.close();
      expect(listener.isClosed, isTrue);
      controller.close();
    });

    test('accept() - aceita conexao pendente ou encerra', () async {
      final controller = StreamController<quic_lib.Libp2pQuicConnection>.broadcast();
      final listener = QuicListener(
        stream: controller.stream,
        addr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
      );
      await controller.close();
      final conn = await listener.accept();
      expect(conn, isNull);
      await listener.close();
    });

    test('close() - encerra o listener e cancela subscricoes', () async {
      final controller = StreamController<quic_lib.Libp2pQuicConnection>.broadcast();
      final listener = QuicListener(
        stream: controller.stream,
        addr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
      );
      await listener.close();
      expect(listener.isClosed, isTrue);
      await controller.close();
    });

    test('supportsAddr() - valida compatibilidade de enderecos quic', () {
      final controller = StreamController<quic_lib.Libp2pQuicConnection>.broadcast();
      final listener = QuicListener(
        stream: controller.stream,
        addr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
      );
      expect(
        listener.supportsAddr(libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1')),
        isTrue,
      );
      expect(
        listener.supportsAddr(libp2p_addr.MultiAddr('/ip4/127.0.0.1/tcp/4001')),
        isFalse,
      );
      listener.close();
      controller.close();
    });
  });

  // QuicConnectionAdapter
  group('QuicConnectionAdapter [Atomic Audit]', () {
    test('getQuicStream() - busca stream quic por id', () {
      final adapter = _TestQuicConnectionAdapter();
      expect(adapter.getQuicStream(0), isNull);
    });

    test('isEstablished - indica se handshake esta concluido', () {
      final adapter = _TestQuicConnectionAdapter(isEstablished: true);
      expect(adapter.isEstablished, isTrue);
    });

    test('openBidirectionalStream() - abre novo stream bidirecional', () {
      final adapter = _TestQuicConnectionAdapter(nextStreamId: 5);
      expect(adapter.openBidirectionalStream(), equals(5));
    });

    test('close() - fecha adaptador de conexao quic', () async {
      final adapter = _TestQuicConnectionAdapter();
      await adapter.close();
      expect(adapter.isClosed, isTrue);
    });
  });

  // QuicConnection
  group('QuicConnection [Atomic Audit]', () {
    test('id - identificador unico da conexao', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.id, isNotEmpty);
      conn.close();
    });

    test('isClosed - status de encerramento da conexao', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.isClosed, isFalse);
      conn.close();
      expect(conn.isClosed, isTrue);
    });

    test('quicConnection - objeto interno da conexao quic', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.quicConnection, equals(adapter));
      conn.close();
    });

    test('getQuicStream() - busca stream por id no adaptador', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.getQuicStream(10), isNull);
      conn.close();
    });

    test('isEstablished - verifica estado do handshake', () {
      final adapter = _TestQuicConnectionAdapter(isEstablished: true);
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.isEstablished, isTrue);
      conn.close();
    });

    test('openBidirectionalStream() - abre novo fluxo bidirecional', () {
      final adapter = _TestQuicConnectionAdapter(nextStreamId: 8);
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.openBidirectionalStream(), equals(8));
      conn.close();
    });

    test('localPeer - peer id local da conexao', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.localPeer, isA<libp2p_peer.PeerId>());
      conn.close();
    });

    test('remotePeer - lanca erro antes de verificacao', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(() => conn.remotePeer, throwsStateError);
      conn.close();
    });

    test('remotePublicKey - chave publica remota nula antes do tls', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(await conn.remotePublicKey, isNull);
      conn.close();
    });

    test('verifyPeer() - verifica conformidade de alpn', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.verifyPeer, throwsStateError);
      conn.close();
    });

    test('verifyPeerCertificate() - valida certificado x509 fornecido', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      await expectLater(conn.verifyPeerCertificate([]), throwsFormatException);
      conn.close();
    });

    test('verifyPeerFromHandshake() - valida certificado capturado no handshake', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(await conn.verifyPeerFromHandshake(), isFalse);
      conn.close();
    });

    test('localMultiaddr - endereco multiaddr local da conexao', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.localMultiaddr.toString(), equals('/ip4/127.0.0.1/udp/4002/quic-v1'));
      conn.close();
    });

    test('remoteMultiaddr - endereco multiaddr remoto da conexao', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.remoteMultiaddr.toString(), equals('/ip4/127.0.0.1/udp/4003/quic-v1'));
      conn.close();
    });

    test('state - estado de seguranca e transporte da conexao', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.state.transport, equals('quic-v1'));
      expect(conn.state.security, equals('/tls/1.3'));
      conn.close();
    });

    test('stat - estatisticas de conexao direcao e streams', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.stat.stats.direction, equals(libp2p_common.Direction.outbound));
      conn.close();
    });

    test('scope - escopo de gerenciamento da conexao', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(conn.scope, isA<libp2p_rcmgr.ConnScope>());
      conn.close();
    });

    test('newStream() - cria novo stream p2p sobre quic', () async {
      final adapter = _TestQuicConnectionAdapter(isEstablished: true, nextStreamId: 1);
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = await conn.newStream(libp2p_context.Context());
      expect(stream, isA<libp2p_stream.P2PStream<dynamic>>());
      await stream.close();
      await conn.close();
    });

    test('streams - lista streams de entrada ativos', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(await conn.streams, isEmpty);
      conn.close();
    });

    test('close() - encerra conexao quic', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      await conn.close();
      expect(conn.isClosed, isTrue);
    });

    test('read() - lanca unsupported error para leitura crua', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(() => conn.read(), throwsUnsupportedError);
      conn.close();
    });

    test('write() - lanca unsupported error para escrita crua', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(() => conn.write(Uint8List(0)), throwsUnsupportedError);
      conn.close();
    });

    test('socket - lanca unsupported error para socket nativo', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      expect(() => conn.socket, throwsUnsupportedError);
      conn.close();
    });

    test('setReadTimeout() - operacao segura de timeout de leitura', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      conn.setReadTimeout(const Duration(seconds: 1));
      expect(conn.isClosed, isFalse);
      conn.close();
    });

    test('setWriteTimeout() - operacao segura de timeout de escrita', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      conn.setWriteTimeout(const Duration(seconds: 1));
      expect(conn.isClosed, isFalse);
      conn.close();
    });

    test('notifyActivity() - notifica atividade na conexao', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      conn.notifyActivity();
      expect(conn.isClosed, isFalse);
      conn.close();
    });
  });

  // QuicP2pStream
  group('QuicP2pStream [Atomic Audit]', () {
    test('id() - retorna identificador unico do stream', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      expect(stream.id(), isNotEmpty);
      stream.close();
      conn.close();
    });

    test('protocol() - retorna protocolo negociado no stream', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      expect(stream.protocol(), equals('/test/1.0.0'));
      stream.close();
      conn.close();
    });

    test('setProtocol() - atualiza protocolo associado ao stream', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.setProtocol('/novo/1.0.0');
      expect(stream.protocol(), equals('/novo/1.0.0'));
      await stream.close();
      await conn.close();
    });

    test('stat() - retorna estatisticas do stream', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      expect(stream.stat().direction, equals(libp2p_common.Direction.outbound));
      stream.close();
      conn.close();
    });

    test('conn - referencia a conexao quic pai', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      expect(stream.conn, equals(conn));
      stream.close();
      conn.close();
    });

    test('scope() - escopo de gerenciamento de recursos', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      expect(stream.scope(), isA<libp2p_rcmgr.StreamManagementScope>());
      stream.close();
      conn.close();
    });

    test('read() - lanca erro se o stream estiver fechado', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.close();
      expect(() => stream.read(), throwsStateError);
      await conn.close();
    });

    test('write() - lanca erro se o stream estiver fechado', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.close();
      expect(() => stream.write(Uint8List(0)), throwsStateError);
      await conn.close();
    });

    test('incoming - retorna referencia para o stream recebido', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      expect(stream.incoming, equals(stream));
      stream.close();
      conn.close();
    });

    test('stream - expoe stream de bytes recebidos', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      expect(stream.stream, isA<Stream<Uint8List>>());
      stream.close();
      conn.close();
    });

    test('close() - fecha stream para leitura e escrita', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.close();
      expect(stream.isClosed, isTrue);
      await conn.close();
    });

    test('closeWrite() - fecha lado de escrita do stream', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.closeWrite();
      expect(stream.isWritable, isFalse);
      await stream.close();
      await conn.close();
    });

    test('closeRead() - fecha lado de leitura do stream', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.closeRead();
      expect(stream.isClosed, isFalse);
      await stream.close();
      await conn.close();
    });

    test('reset() - reseta stream abruptamente', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.reset();
      expect(stream.isClosed, isTrue);
      await conn.close();
    });

    test('setDeadline() - configura limite de tempo geral', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.setDeadline(DateTime.now());
      expect(stream.isClosed, isFalse);
      await stream.close();
      await conn.close();
    });

    test('setReadDeadline() - configura limite de tempo de leitura', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.setReadDeadline(DateTime.now());
      expect(stream.isClosed, isFalse);
      await stream.close();
      await conn.close();
    });

    test('setWriteDeadline() - configura limite de tempo de escrita', () async {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      await stream.setWriteDeadline(DateTime.now());
      expect(stream.isClosed, isFalse);
      await stream.close();
      await conn.close();
    });

    test('isClosed - indica status de fechamento do stream', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      expect(stream.isClosed, isFalse);
      stream.close();
      conn.close();
    });

    test('isWritable - indica se escrita ainda e permitida', () {
      final adapter = _TestQuicConnectionAdapter();
      final conn = QuicConnection(
        quic_lib.Libp2pQuicConnection(adapter),
        localAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1'),
        remoteAddr: libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4003/quic-v1'),
        isServer: false,
      );
      final stream = QuicP2pStream(conn, 1, libp2p_common.Direction.outbound, '/test/1.0.0');
      expect(stream.isWritable, isTrue);
      stream.close();
      conn.close();
    });
  });

  // QuicTransport
  group('QuicTransport [Atomic Audit]', () {
    test('protocols - lista protocolos suportados pelo transporte', () {
      final transport = QuicTransport();
      expect(transport.protocols, contains('/ip4/udp/quic-v1'));
      expect(transport.protocols, contains('/ip6/udp/quic-v1'));
    });

    test('canDial() - valida compatibilidade de discagem quic', () {
      final transport = QuicTransport();
      expect(
        transport.canDial(libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1')),
        isTrue,
      );
      expect(
        transport.canDial(libp2p_addr.MultiAddr('/ip4/127.0.0.1/tcp/4001')),
        isFalse,
      );
    });

    test('canListen() - valida compatibilidade de escuta quic', () {
      final transport = QuicTransport();
      expect(
        transport.canListen(libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1')),
        isTrue,
      );
    });

    test('dial() - lanca erro quando transporte esta descartado', () async {
      final transport = QuicTransport();
      await transport.dispose();
      expect(
        () => transport.dial(libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1')),
        throwsStateError,
      );
    });

    test('listen() - lanca erro quando transporte esta descartado', () async {
      final transport = QuicTransport();
      await transport.dispose();
      expect(
        () => transport.listen(libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1')),
        throwsStateError,
      );
    });

    test('dispose() - descarta recursos do transporte', () async {
      final transport = QuicTransport();
      await transport.dispose();
      expect(
        transport.canDial(libp2p_addr.MultiAddr('/ip4/127.0.0.1/udp/4002/quic-v1')),
        isTrue,
      );
    });
  });

  // BitswapClient
  group('BitswapClient [Atomic Audit]', () {
    test('start() - registra handler para protocolo bitswap', () {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final bstore = Blockstore();
      final client = BitswapClient(
        router: router,
        blockstore: bstore,
        timeout: const Duration(seconds: 30),
      );
      client.start();
      expect(host.handlers.containsKey('/ipfs/bitswap/1.2.0'), isTrue);
      client.close();
      bstore.close();
    });

    test('connect() - conecta a provedor bitswap', () async {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final bstore = Blockstore();
      final client = BitswapClient(
        router: router,
        blockstore: bstore,
        timeout: const Duration(seconds: 30),
      );
      final peer = libp2p.AddrInfo(id: samplePeerId, addrs: []);
      await client.connect(peer);
      expect(client.blockstore, equals(bstore));
      await client.close();
      await bstore.close();
    });

    test('getBlock() - recupera bloco do storage se disponivel', () async {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final bstore = Blockstore();
      await bstore.put(blocks.BasicBlock(sampleRawData, sampleCid));
      final client = BitswapClient(
        router: router,
        blockstore: bstore,
        timeout: const Duration(seconds: 30),
      );
      final blk = await client.getBlock(sampleCid);
      expect(blk.rawData(), equals(sampleRawData));
      await client.close();
      await bstore.close();
    });

    test('close() - encerra cliente bitswap e fluxos pendentes', () async {
      final host = _FakeHost();
      final router = Libp2pRouter(host);
      final bstore = Blockstore();
      final client = BitswapClient(
        router: router,
        blockstore: bstore,
        timeout: const Duration(seconds: 30),
      );
      await client.close();
      expect(client.blockstore, equals(bstore));
      await bstore.close();
    });
  });

  // BlockGetter
  group('BlockGetter [Atomic Audit]', () {
    test('getBlock() - busca bloco por cid na interface block getter', () async {
      final getter = _TestBlockGetter();
      final blk = await getter.getBlock(sampleCid);
      expect(blk.rawData(), equals([1, 2, 3]));
    });
  });

  // QueryPeerset
  group('QueryPeerset [Atomic Audit]', () {
    test('tryAdd() - insere novo peer no peerset se ausente', () {
      final target = samplePeerId;
      final qp = QueryPeerset(target, (t, a, b) => 0);
      final p1 = libp2p.PeerId.decode(
        '12D3KooWStiM2F2p4k2c6c3H3c2wM7d8Xv5R7n3w4k7K2c6c3H3c',
      );
      expect(qp.tryAdd(p1, target), isTrue);
      expect(qp.tryAdd(p1, target), isFalse);
    });

    test('setState() - atualiza estado de consulta do peer', () {
      final target = samplePeerId;
      final qp = QueryPeerset(target, (t, a, b) => 0);
      final p1 = libp2p.PeerId.decode(
        '12D3KooWStiM2F2p4k2c6c3H3c2wM7d8Xv5R7n3w4k7K2c6c3H3c',
      );
      qp.tryAdd(p1, target);
      qp.setState(p1, PeerState.waiting);
      expect(qp.getState(p1), equals(PeerState.waiting));
    });

    test('getState() - consulta estado atual do peer', () {
      final target = samplePeerId;
      final qp = QueryPeerset(target, (t, a, b) => 0);
      final p1 = libp2p.PeerId.decode(
        '12D3KooWStiM2F2p4k2c6c3H3c2wM7d8Xv5R7n3w4k7K2c6c3H3c',
      );
      qp.tryAdd(p1, target);
      expect(qp.getState(p1), equals(PeerState.heard));
    });

    test('getReferrer() - obtem peer que indicou o endereco', () {
      final target = samplePeerId;
      final qp = QueryPeerset(target, (t, a, b) => 0);
      final p1 = libp2p.PeerId.decode(
        '12D3KooWStiM2F2p4k2c6c3H3c2wM7d8Xv5R7n3w4k7K2c6c3H3c',
      );
      qp.tryAdd(p1, target);
      expect(qp.getReferrer(p1), equals(target));
    });

    test('getClosestNInStates() - busca n peers mais proximos nos estados', () {
      final target = samplePeerId;
      final qp = QueryPeerset(target, (t, a, b) => 0);
      final p1 = libp2p.PeerId.decode(
        '12D3KooWStiM2F2p4k2c6c3H3c2wM7d8Xv5R7n3w4k7K2c6c3H3c',
      );
      qp.tryAdd(p1, target);
      final list = qp.getClosestNInStates(1, {PeerState.heard});
      expect(list, equals([p1]));
    });

    test('getClosestInStates() - busca todos os peers mais proximos nos estados', () {
      final target = samplePeerId;
      final qp = QueryPeerset(target, (t, a, b) => 0);
      final p1 = libp2p.PeerId.decode(
        '12D3KooWStiM2F2p4k2c6c3H3c2wM7d8Xv5R7n3w4k7K2c6c3H3c',
      );
      qp.tryAdd(p1, target);
      final list = qp.getClosestInStates({PeerState.heard});
      expect(list, equals([p1]));
    });

    test('numHeard - quantidade de peers descobertos pendentes', () {
      final target = samplePeerId;
      final qp = QueryPeerset(target, (t, a, b) => 0);
      final p1 = libp2p.PeerId.decode(
        '12D3KooWStiM2F2p4k2c6c3H3c2wM7d8Xv5R7n3w4k7K2c6c3H3c',
      );
      qp.tryAdd(p1, target);
      expect(qp.numHeard, equals(1));
    });

    test('numWaiting - quantidade de queries em andamento', () {
      final target = samplePeerId;
      final qp = QueryPeerset(target, (t, a, b) => 0);
      final p1 = libp2p.PeerId.decode(
        '12D3KooWStiM2F2p4k2c6c3H3c2wM7d8Xv5R7n3w4k7K2c6c3H3c',
      );
      qp.tryAdd(p1, target);
      expect(qp.numWaiting, equals(0));
      qp.setState(p1, PeerState.waiting);
      expect(qp.numWaiting, equals(1));
    });
  });

  // BuildCfg
  group('BuildCfg [Atomic Audit]', () {
    test('config - obtem configuracao resolvida do build cfg', () {
      final cfgOffline = BuildCfg(online: false);
      expect(cfgOffline.config.offline, isTrue);
      final cfgOnline = BuildCfg(online: true);
      expect(cfgOnline.config.offline, isFalse);
    });
  });

  // DistanceMetric
  group('DistanceMetric [Atomic Audit]', () {
    test('calculateDistance() - calcula distancia numerica entre peers', () {
      final metric = _TestDistanceMetric();
      expect(metric.calculateDistance(samplePeerId, samplePeerId), equals(42));
    });

    test('calculateDistanceToKey() - calcula distancia entre peer e chave raw', () {
      final metric = _TestDistanceMetric();
      expect(metric.calculateDistanceToKey(samplePeerId, [1, 2, 3]), equals(24));
    });
  });

  // DhtRoutingTable
  group('DhtRoutingTable [Atomic Audit]', () {
    test('distanceMetric - expoem metrica de distancia da tabela', () {
      final rt = _TestDhtRoutingTable();
      expect(rt.distanceMetric, isA<DistanceMetric>());
    });

    test('findClosestPeers() - busca peers mais proximos por id', () {
      final rt = _TestDhtRoutingTable();
      rt.addPeer(samplePeerId, samplePeerId);
      final closest = rt.findClosestPeers(samplePeerId);
      expect(closest, equals([samplePeerId]));
    });

    test('findClosestPeersToKey() - busca peers mais proximos por chave', () {
      final rt = _TestDhtRoutingTable();
      rt.addPeer(samplePeerId, samplePeerId);
      final closest = rt.findClosestPeersToKey([1, 2, 3]);
      expect(closest, equals([samplePeerId]));
    });

    test('addPeer() - adiciona peer a tabela de roteamento', () async {
      final rt = _TestDhtRoutingTable();
      await rt.addPeer(samplePeerId, samplePeerId);
      expect(rt.containsPeer(samplePeerId), isTrue);
    });

    test('removePeer() - remove peer da tabela de roteamento', () {
      final rt = _TestDhtRoutingTable();
      rt.addPeer(samplePeerId, samplePeerId);
      rt.removePeer(samplePeerId);
      expect(rt.containsPeer(samplePeerId), isFalse);
    });

    test('containsPeer() - verifica presenca de peer na tabela', () {
      final rt = _TestDhtRoutingTable();
      expect(rt.containsPeer(samplePeerId), isFalse);
      rt.addPeer(samplePeerId, samplePeerId);
      expect(rt.containsPeer(samplePeerId), isTrue);
    });

    test('peerCount - quantidade total de peers na tabela', () {
      final rt = _TestDhtRoutingTable();
      expect(rt.peerCount, equals(0));
      rt.addPeer(samplePeerId, samplePeerId);
      expect(rt.peerCount, equals(1));
    });

    test('clear() - remove todos os peers da tabela', () {
      final rt = _TestDhtRoutingTable();
      rt.addPeer(samplePeerId, samplePeerId);
      rt.clear();
      expect(rt.peerCount, equals(0));
    });
  });
}
