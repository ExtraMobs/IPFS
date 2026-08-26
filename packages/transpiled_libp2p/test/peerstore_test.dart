import 'package:test/test.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';

void main() {
  test('peerstore TTLs match go-libp2p', () {
    expect(AddressTTL, const Duration(hours: 1));
    expect(TempAddrTTL, const Duration(minutes: 2));
    expect(RecentlyConnectedAddrTTL, const Duration(minutes: 15));
    expect(OwnObservedAddrTTL, const Duration(minutes: 30));
    expect(PermanentAddrTTL.inMicroseconds, 9223372036854775);
    expect(ConnectedAddrTTL.inMicroseconds, 9223372036854774);
    expect(PermanentAddrTTL > ConnectedAddrTTL, isTrue);
  });
}
