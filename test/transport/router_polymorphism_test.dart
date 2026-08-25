// test/transport/router_polymorphism_test.dart
//
// Phase 4 verification (core-module-split plan): concrete, end-to-end
// proof that a protocol handler works correctly against multiple
// RouterInterface implementations -- not just that the type system
// accepts them structurally. Ping is the representative protocol: send
// 32 bytes, expect them echoed back with a measured RTT (see
// lib/src/protocols/ping/ping_handler.dart). The same assertions run
// against two RouterInterface implementations that resolve sendRequest
// differently -- one immediately, one after a real async delay -- to
// show PingHandler doesn't depend on timing or details RouterInterface
// doesn't promise.

import 'dart:async';
import 'dart:typed_data';

import 'package:transpiled_ipfs/src/protocols/ping/ping_handler.dart';
import 'package:transpiled_ipfs/src/transport/router_events.dart';
import 'package:transpiled_ipfs/src/transport/router_interface.dart';
import 'package:test/test.dart';

/// No-ops every [RouterInterface] member via `noSuchMethod`; subclasses
/// only override what [PingHandler] actually calls.
class _NoOpRouter implements RouterInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Echoes the ping payload back on the same event-loop turn.
class _ImmediateEchoRouter extends _NoOpRouter {
  @override
  void registerProtocolHandler(
    String protocolId,
    void Function(NetworkPacket) handler,
  ) {}

  @override
  void removeMessageHandler(String protocolId) {}

  @override
  Future<Uint8List?> sendRequest(
    String peerId,
    String protocolId,
    Uint8List request,
  ) async => request;
}

/// Echoes the ping payload back after a real async delay -- a genuinely
/// different code path from immediate resolution.
class _DelayedEchoRouter extends _NoOpRouter {
  @override
  void registerProtocolHandler(
    String protocolId,
    void Function(NetworkPacket) handler,
  ) {}

  @override
  void removeMessageHandler(String protocolId) {}

  @override
  Future<Uint8List?> sendRequest(
    String peerId,
    String protocolId,
    Uint8List request,
  ) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return request;
  }
}

void main() {
  final implementations = <String, RouterInterface Function()>{
    'immediate-echo': _ImmediateEchoRouter.new,
    'delayed-echo': _DelayedEchoRouter.new,
  };

  for (final entry in implementations.entries) {
    test(
      'PingHandler succeeds with a valid RTT against a '
      '${entry.key} RouterInterface',
      () async {
        final handler = PingHandler(router: entry.value());
        await handler.start();

        final result = await handler.ping('QmPeer1');

        expect(result.success, isTrue);
        expect(result.rtt, isNotNull);
        expect(result.rtt!.inMicroseconds, greaterThanOrEqualTo(0));
      },
    );
  }
}
