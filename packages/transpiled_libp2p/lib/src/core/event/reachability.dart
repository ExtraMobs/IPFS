// ignore_for_file: public_member_api_docs

import 'package:transpiled_multiaddr/transpiled_multiaddr.dart';

import '../network/network.dart';

/// Emitted when the local node's reachability changes.
final class EvtLocalReachabilityChanged {
  const EvtLocalReachabilityChanged({required this.reachability});

  final Reachability reachability;
}

/// Sent when the host's reachable or unreachable addresses change.
final class EvtHostReachableAddrsChanged {
  const EvtHostReachableAddrsChanged({
    required this.reachable,
    required this.unreachable,
    required this.unknown,
  });

  final List<Multiaddr> reachable;
  final List<Multiaddr> unreachable;
  final List<Multiaddr> unknown;
}
