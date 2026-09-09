import 'dart:typed_data';

import 'package:ipfs_libp2p/config/config.dart' as runtime_config;
import 'package:ipfs_libp2p/config/defaults.dart' as runtime_defaults;
import 'package:ipfs_libp2p/config/stream_muxer.dart';
import 'package:ipfs_libp2p/core/crypto/ed25519.dart' as runtime_ed25519;
import 'package:ipfs_libp2p/core/host/host.dart' as runtime;
import 'package:ipfs_libp2p/core/multiaddr.dart';
import 'package:ipfs_libp2p/p2p/host/resource_manager/limiter.dart';
import 'package:ipfs_libp2p/p2p/host/resource_manager/resource_manager_impl.dart';
import 'package:ipfs_libp2p/p2p/transport/tcp_transport.dart';
import 'package:transpiled_block_format/transpiled_block_format.dart' as blocks;
import 'package:transpiled_boxo/transpiled_boxo.dart' hide Blockstore;
import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_go_car/transpiled_go_car.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';
import 'package:transpiled_multiaddr/transpiled_multiaddr.dart' as core_ma;

import '../blockstore/blockstore.dart';
import '../config/ipfs_runtime_config.dart';
import '../core/builders/build_cfg.dart';
import '../network/libp2p_host.dart';
import '../protocols/bitswap/bitswap_client.dart';
import '../routing/dht_provider_finder.dart';
import '../transport/go_yamux_adapter.dart';
import '../transport/noise/dart_ipfs_noise_security.dart';
import '../unixfs/unixfs.dart';

/// Embedded IPFS node containing the currently ported reusable runtime.
final class IpfsNode {
  IpfsNode._({
    required this.config,
    required this.blockstore,
    required runtime.Host? host,
    required BitswapClient? bitswap,
    required DhtClient? dht,
    required Duration shutdownTimeout,
  }) : _host = host,
       _bitswap = bitswap,
       _dht = dht,
       _shutdownTimeout = shutdownTimeout;

  /// Kubo `core.NewNode` equivalent for the supported Dart subset.
  static Future<IpfsNode> fromBuildCfg(BuildCfg buildCfg) async {
    final config = buildCfg.config;
    final blockstore = Blockstore();
    if (!buildCfg.online) {
      return IpfsNode._(
        config: config,
        blockstore: blockstore,
        host: null,
        bitswap: null,
        dht: null,
        shutdownTimeout: buildCfg.shutdownTimeout,
      );
    }

    final identityKey = await generateEd25519KeyPair();
    final runtimeIdentity = await runtime_ed25519
        .generateEd25519KeyPairFromSeed(
          Uint8List.fromList(identityKey.raw().sublist(0, 32)),
        );
    final resourceManager = ResourceManagerImpl(limiter: FixedLimiter());
    final runtimeConfig = runtime_config.Config()
      ..peerKey = runtimeIdentity
      ..transports.add(TCPTransport(resourceManager: resourceManager))
      ..securityProtocols.add(DartIpfsNoiseSecurity(identityKey))
      ..muxers.add(
        const StreamMuxer(id: goYamuxProtocolId, muxerFactory: goYamuxFactory),
      )
      ..listenAddrs.addAll(config.network.listenAddresses.map(MultiAddr.new));
    await runtime_defaults.applyDefaults(runtimeConfig);
    runtimeConfig
      ..enableAutoNAT = false
      ..enableHolePunching = false
      ..enablePing = false
      ..enableRelay = false
      ..enableAutoRelay = false
      ..addrsFactory = (addrs) => addrs;
    final host = await runtimeConfig.newNode();
    await host.start();
    final router = Libp2pRouter(host);
    final bootstrapPeers = config.network.bootstrapPeers
        .map(addrInfoFromString)
        .toList();
    final dht = DhtClient(router: router, bootstrapPeers: bootstrapPeers);
    final bitswap = BitswapClient(
      router: router,
      blockstore: blockstore,
      timeout: config.bitswap.p2pTimeout,
    )..start();
    return IpfsNode._(
      config: config,
      blockstore: blockstore,
      host: host,
      bitswap: bitswap,
      dht: dht,
      shutdownTimeout: buildCfg.shutdownTimeout,
    );
  }

  /// Effective node configuration.
  final IpfsConfig config;

  /// Validating blockstore used by Bitswap.
  final Blockstore blockstore;

  final runtime.Host? _host;
  final BitswapClient? _bitswap;
  final DhtClient? _dht;
  final Duration _shutdownTimeout;
  Future<void>? _closeFuture;

  /// Whether networking is active.
  bool get isOnline => _host != null;

  /// Local cryptographic peer ID of this node.
  PeerId get peerId {
    final host = _host;
    if (host == null) throw StateError('IPFS node is offline');
    return PeerId.decode(host.id.toBase58());
  }

  /// Active listening multiaddresses for this node.
  List<String> get listenAddresses {
    final host = _host;
    if (host == null) return const [];
    final addrs = host.addrs;
    if (addrs.isNotEmpty) {
      return addrs.map((a) => a.toString()).toList();
    }
    return host.network.listenAddresses.map((a) => a.toString()).toList();
  }

  /// Formatted multiaddresses including peer ID (e.g. `/ip4/127.0.0.1/tcp/xxxxx/p2p/<peerId>`).
  List<String> get swarmAddresses {
    final pid = peerId.toBase58();
    return listenAddresses.map((a) => '$a/p2p/$pid').toList();
  }

  /// Stores a block in the local blockstore.
  Future<void> putBlock(blocks.Block block) => blockstore.put(block);

  /// Creates and stores a raw block from [bytes] and returns its Cid.
  Future<Cid> putRawBlock(Uint8List bytes) async {
    final block = blocks.BasicBlock.fromData(bytes);
    await blockstore.put(block);
    return block.cid();
  }

  /// Connects this node to a complete provider address.
  Future<void> connect(AddrInfo provider) {
    final bitswap = _bitswap;
    if (bitswap == null) throw StateError('IPFS node is offline');
    return bitswap.connect(provider);
  }

  /// Retrieves and persists one block through Bitswap.
  Future<blocks.Block> getBlock(Cid cid) {
    final bitswap = _bitswap;
    if (bitswap == null) throw StateError('IPFS node is offline');
    return bitswap.getBlock(cid);
  }

  /// Discovers providers through the IPFS Kademlia DHT.
  Stream<AddrInfo> findProvidersAsync(Cid cid, int count) {
    final dht = _dht;
    if (dht == null) throw StateError('IPFS node is offline');
    return dht.findProvidersAsync(cid, count);
  }

  /// Announces this node as a provider of [cid] to the DHT.
  Future<void> provide(Cid cid) async {
    final dht = _dht;
    if (dht == null) throw StateError('IPFS node is offline');
    final self = AddrInfo(
      id: peerId,
      addrs: listenAddresses.map(core_ma.Multiaddr.parse).toList(),
    );
    await dht.provide(cid, self);
  }

  /// Discovers providers and downloads the first valid Bitswap block.
  Future<blocks.Block> getBlockFromDht(Cid cid) async {
    Object? lastError;
    await for (final provider in findProvidersAsync(cid, 0)) {
      if (provider.addrs.isEmpty) continue;
      try {
        await connect(provider);
        return await getBlock(cid);
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('DHT/Bitswap could not retrieve $cid: $lastError');
  }

  /// Streams a regular UnixFS file, fetching every missing block by Bitswap.
  Stream<Uint8List> getUnixFs(Cid cid) => readUnixFs(cid, _getContentBlock);

  /// Returns logical and stored sizes for a UnixFS root.
  Future<UnixFsStat> statUnixFs(Cid cid) async {
    final root = await _getContentBlock(cid);
    final bytes = root.rawData();
    if (cid.codec == 'raw') {
      return UnixFsStat(
        cid: cid,
        size: bytes.length,
        blockSize: bytes.length,
        cumulativeSize: bytes.length,
        numLinks: 0,
        numBlocks: 1,
      );
    }
    final dag = DagPbNode.fromBytes(bytes);
    final fs = UnixFsData.fromBytes(dag.data);
    var blocksCount = 0;
    await for (final _ in walkUnixFs(cid, _getContentBlock)) {
      blocksCount++;
    }
    return UnixFsStat(
      cid: cid,
      size: fs.filesize,
      blockSize: bytes.length,
      cumulativeSize:
          bytes.length + dag.links.fold(0, (total, link) => total + link.tsize),
      numLinks: dag.links.length,
      numBlocks: blocksCount,
    );
  }

  /// Lists the root and all nested CIDs in depth-first order.
  Stream<Cid> listUnixFsCids(Cid cid) => walkUnixFs(cid, _getContentBlock);

  /// Streams a CAR v1 containing the complete UnixFS DAG.
  Stream<Uint8List> exportCar(Cid cid) => CarWriter(
    roots: [cid],
    get: (child) async => (await _getContentBlock(child)).rawData(),
    linksWithData: unixFsLinks,
  ).stream();

  /// Validates and imports a CAR v1 into this node's blockstore.
  Future<CarHeader> importCar(Object input) => loadCar(
    input,
    (CarBlock block) => blockstore.put(block),
  );

  Future<blocks.Block> _getContentBlock(Cid cid) async {
    if (await blockstore.has(cid)) return blockstore.get(cid);
    try {
      return await getBlock(cid);
    } catch (bitswapError) {
      try {
        return await getBlockFromDht(cid);
      } catch (dhtError) {
        throw StateError(
          'could not retrieve $cid; connected Bitswap: $bitswapError; '
          'DHT fallback: $dhtError',
        );
      }
    }
  }

  /// Closes the node once; concurrent callers share the same future.
  Future<void> close() => _closeFuture ??= _close();

  Future<void> _close() async {
    final close = () async {
      await _dht?.close();
      await _bitswap?.close();
      await _host?.close();
      await blockstore.close();
    }();
    if (_shutdownTimeout > Duration.zero) {
      try {
        await close.timeout(_shutdownTimeout);
      } catch (_) {}
    } else {
      await close;
    }
  }
}
