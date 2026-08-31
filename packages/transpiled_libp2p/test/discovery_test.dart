import 'dart:async';

import 'package:test/test.dart';
import 'package:transpiled_libp2p/src/core/discovery/discovery.dart';
import 'package:transpiled_libp2p/src/core/discovery/options.dart';
import 'package:transpiled_libp2p/src/core/peer/addr_info.dart';

class _Discovery implements Discovery {
  @override
  Future<Duration> advertise(
    String namespace, {
    List<DiscoveryOption> options = const [],
  }) async {
    final applied = DiscoveryOptions()..apply(options);
    return applied.ttl;
  }

  @override
  Stream<AddrInfo> findPeers(
    String namespace, {
    List<DiscoveryOption> options = const [],
  }) async* {
    if (namespace == 'chat') yield* const Stream<AddrInfo>.empty();
  }
}

void main() {
  test('advertiser and discoverer contracts compose', () async {
    final discovery = _Discovery();
    expect(
      await discovery.advertise(
        'chat',
        options: [ttl(const Duration(seconds: 10))],
      ),
      const Duration(seconds: 10),
    );
    expect(await discovery.findPeers('chat').toList(), isEmpty);
  });
}
