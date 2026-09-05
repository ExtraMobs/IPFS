import 'package:ipfs_libp2p/dart_libp2p.dart' as runtime;
import 'package:transpiled_libp2p/transpiled_libp2p.dart' as core;

/// Adapts the ported go-libp2p `AddrInfo` to the runtime host.
final class Libp2pRouter {
  /// Creates an adapter for [host].
  const Libp2pRouter(this.host);

  /// Runtime host used for connections and streams.
  final runtime.Host host;

  /// Connects the host to the complete peer information in [peer].
  Future<void> connect(core.AddrInfo peer) async {
    final id = runtime.PeerId.decode(peer.id.toBase58());
    final addrs = <runtime.MultiAddr>[];
    for (final address in peer.addrs) {
      try {
        addrs.add(runtime.MultiAddr(address.toAddrString()));
      } on FormatException {
        // An unsupported transport address does not invalidate the peer.
      }
    }
    // The dependency's default AddrsFactory removes loopback addresses.
    // Absorb the complete AddrInfo first, preserving go-libp2p Host.Connect.
    await host.peerStore.addrBook.addAddrs(
      id,
      addrs,
      const Duration(minutes: 2),
    );
    await host.connect(runtime.AddrInfo(id, addrs));
  }

  /// Converts a ported peer ID for runtime stream creation.
  runtime.PeerId runtimePeerId(core.PeerId peer) =>
      runtime.PeerId.decode(peer.toBase58());
}
