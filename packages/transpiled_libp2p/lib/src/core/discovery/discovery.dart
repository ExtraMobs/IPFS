// Port of go-libp2p/core/discovery/discovery.go.
import 'dart:async';

import '../peer/addr_info.dart';
import 'options.dart';

/// Advertises services to the network.
abstract interface class Advertiser {
  /// Advertises [namespace] and returns the advertisement TTL.
  ///
  /// Go's `context.Context` is represented by Dart's normal Future/Stream
  /// cancellation and lifecycle mechanisms, so it is not an argument here.
  Future<Duration> advertise(
    String namespace, {
    List<DiscoveryOption> options = const [],
  });
}

/// Discovers peers providing a service.
abstract interface class Discoverer {
  /// Finds peers providing [namespace]. A zero option limit is unbounded.
  Stream<AddrInfo> findPeers(
    String namespace, {
    List<DiscoveryOption> options = const [],
  });
}

/// Combines service advertisement and peer discovery.
abstract interface class Discovery implements Advertiser, Discoverer {}
