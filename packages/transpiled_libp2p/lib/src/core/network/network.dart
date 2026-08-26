// ignore_for_file: public_member_api_docs

import 'package:transpiled_multiaddr/transpiled_multiaddr.dart';

const messageSizeMax = 1 << 22;

enum Direction { unknown, inbound, outbound }

extension DirectionText on Direction {
  String get text => switch (this) {
        Direction.unknown => 'Unknown',
        Direction.inbound => 'Inbound',
        Direction.outbound => 'Outbound',
      };
}

enum Connectedness { notConnected, connected, canConnect, cannotConnect, limited }

extension ConnectednessText on Connectedness {
  String get text => switch (this) {
        Connectedness.notConnected => 'NotConnected',
        Connectedness.connected => 'Connected',
        Connectedness.canConnect => 'CanConnect',
        Connectedness.cannotConnect => 'CannotConnect',
        Connectedness.limited => 'Limited',
      };
}

enum Reachability { unknown, public_, private_ }

extension ReachabilityText on Reachability {
  String get text => switch (this) {
        Reachability.unknown => 'Unknown',
        Reachability.public_ => 'Public',
        Reachability.private_ => 'Private',
      };
}

abstract interface class Network {}
abstract interface class Conn {}

abstract interface class Notifiee {
  void listen(Network network, Multiaddr address);
  void listenClose(Network network, Multiaddr address);
  void connected(Network network, Conn connection);
  void disconnected(Network network, Conn connection);
}

final class NotifyBundle implements Notifiee {
  NotifyBundle({this.listenF, this.listenCloseF, this.connectedF, this.disconnectedF});
  final void Function(Network, Multiaddr)? listenF;
  final void Function(Network, Multiaddr)? listenCloseF;
  final void Function(Network, Conn)? connectedF;
  final void Function(Network, Conn)? disconnectedF;
  @override void listen(Network n, Multiaddr a) => listenF?.call(n, a);
  @override void listenClose(Network n, Multiaddr a) => listenCloseF?.call(n, a);
  @override void connected(Network n, Conn c) => connectedF?.call(n, c);
  @override void disconnected(Network n, Conn c) => disconnectedF?.call(n, c);
}

final class NoopNotifiee implements Notifiee {
  const NoopNotifiee();
  @override void listen(Network n, Multiaddr a) {}
  @override void listenClose(Network n, Multiaddr a) {}
  @override void connected(Network n, Conn c) {}
  @override void disconnected(Network n, Conn c) {}
}

const globalNoopNotifiee = NoopNotifiee();
