// Port of go-libp2p-kbucket's table_test.go: TestNPeersForCpl -- exercises
// TryAddPeer, NPeersForCpl and bucket-splitting together.
import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';
import 'package:transpiled_libp2p_kbucket/transpiled_libp2p_kbucket.dart';

class _NoOpMetrics implements PeerMetrics {
  @override
  Duration latencyEWMA(PeerId id) => Duration.zero;
}

PeerId _randPeerId() {
  final random = Random.secure();
  final bytes = Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  return PeerId(value: bytes);
}

void main() {
  test('nPeersForCpl tracks peer counts per common-prefix-length across bucket splits', () {
    final local = _randPeerId();
    final rt = RoutingTable(
      bucketSize: 2,
      local: local,
      maxLatency: const Duration(hours: 1),
      metrics: _NoOpMetrics(),
      usefulnessGracePeriod: const Duration(hours: 100),
    );

    expect(rt.nPeersForCpl(0), equals(0));
    expect(rt.nPeersForCpl(1), equals(0));

    // One peer with cpl 1.
    rt.tryAddPeer(PeerId(value: rt.genRandPeerId(1)), queryPeer: true, isReplaceable: false);
    expect(rt.nPeersForCpl(0), equals(0));
    expect(rt.nPeersForCpl(1), equals(1));
    expect(rt.nPeersForCpl(2), equals(0));

    // One peer with cpl 0.
    rt.tryAddPeer(PeerId(value: rt.genRandPeerId(0)), queryPeer: true, isReplaceable: false);
    expect(rt.nPeersForCpl(0), equals(1));
    expect(rt.nPeersForCpl(1), equals(1));
    expect(rt.nPeersForCpl(2), equals(0));

    // Splits the bucket with a peer with cpl 1.
    rt.tryAddPeer(PeerId(value: rt.genRandPeerId(1)), queryPeer: true, isReplaceable: false);
    expect(rt.nPeersForCpl(0), equals(1));
    expect(rt.nPeersForCpl(1), equals(2));
    expect(rt.nPeersForCpl(2), equals(0));

    rt.tryAddPeer(PeerId(value: rt.genRandPeerId(0)), queryPeer: true, isReplaceable: false);
    expect(rt.nPeersForCpl(0), equals(2));
  });
}
