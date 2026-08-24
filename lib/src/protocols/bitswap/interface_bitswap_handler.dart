import 'package:dart_ipfs/src/core/data_structures/block.dart';

/// Interface for Bitswap handler implementations.
///
/// Mirrors the pattern already used for DHT (see
/// protocols/dht/interface_dht_handler.dart): protocol code that only
/// needs to exchange blocks (e.g. [GraphsyncHandler]) can depend on this
/// abstraction instead of the concrete `BitswapHandler`.
abstract class IBitswapHandler {
  /// Handles blocks received from the network, adding them to the store
  /// and resolving matching pending requests.
  Future<void> handleBlocks(List<Block> blocks);

  /// Requests blocks from the network with proper Bitswap session handling.
  Future<List<Block>> want(
    List<String> cids, {
    int priority = 1,
    Duration timeout = const Duration(seconds: 30),
  });

  /// Handles an incoming want request for a single CID.
  Future<void> handleWantRequest(String cidStr);

  /// Requests a single block from the network.
  Future<Block?> wantBlock(String cid);

  /// Retrieves a block, from the local store or (optionally) an HTTP
  /// gateway fallback if the P2P request doesn't resolve it.
  Future<Block?> getBlock(String cidStr, {bool useHttpFallback = true});

  /// Total bytes sent over Bitswap.
  int get bandwidthSent;

  /// Total bytes received over Bitswap.
  int get bandwidthReceived;

  /// Returns a status snapshot for diagnostics/RPC.
  Future<Map<String, dynamic>> getStatus();

  /// Starts the Bitswap handler.
  Future<void> start() async {}

  /// Stops the Bitswap handler.
  Future<void> stop() async {}
}
