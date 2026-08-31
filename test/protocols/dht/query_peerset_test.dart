import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transpiled_ipfs/src/protocols/dht/query_peerset.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';

void main() {
  PeerId peer(int value) => PeerId(value: Uint8List.fromList([value]));

  int compare(PeerId target, PeerId a, PeerId b) =>
      (target.value.first ^ a.value.first).compareTo(
        target.value.first ^ b.value.first,
      );

  test('tracks state, referrer, uniqueness and XOR order', () {
    final target = peer(0);
    final oracle = peer(9);
    final peers = QueryPeerset(target, compare);

    expect(peers.tryAdd(peer(2), oracle), isTrue);
    expect(peers.tryAdd(peer(2), oracle), isFalse);
    expect(peers.tryAdd(peer(4), oracle), isTrue);
    expect(peers.getClosestNInStates(2, {PeerState.heard}), [peer(2), peer(4)]);
    expect(peers.getReferrer(peer(2)), oracle);
    expect(peers.numHeard, 2);

    peers.setState(peer(2), PeerState.waiting);
    expect(peers.numWaiting, 1);
    peers.setState(peer(2), PeerState.queried);
    peers.setState(peer(4), PeerState.unreachable);

    expect(peers.getClosestInStates({PeerState.heard, PeerState.queried}), [
      peer(2),
    ]);
    expect(() => peers.setState(peer(8), PeerState.heard), throwsStateError);
  });
}
