import 'package:ipfs_libp2p/p2p/transport/transport.dart' as libp2p_transport;

import 'quic/quic_transport.dart';

/// Probes for the pure-Dart QUIC transport on non-web platforms.
///
/// Returns the [QuicTransport] adapter when it can be instantiated;
/// otherwise returns `null` so the caller can fall back to TCP.
Future<libp2p_transport.Transport?> probeQuicTransport(
  libp2p_transport.Transport? Function()? factory,
) async {
  if (factory != null) {
    return factory();
  }

  try {
    return QuicTransport();
  } catch (_) {
    return null;
  }
}
