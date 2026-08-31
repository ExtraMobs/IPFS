import 'package:test/test.dart';
import 'package:transpiled_libp2p/src/core/discovery/options.dart';

void main() {
  test('applies TTL and limit options in order', () {
    final options = DiscoveryOptions();
    options.apply([
      ttl(const Duration(minutes: 5)),
      limit(3),
      ttl(const Duration(minutes: 1)),
    ]);

    expect(options.ttl, const Duration(minutes: 1));
    expect(options.limit, 3);
  });
}
