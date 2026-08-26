import 'package:test/test.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';

void main() {
  test('network enum text matches go-libp2p', () {
    expect(Direction.inbound.text, 'Inbound');
    expect(Connectedness.limited.text, 'Limited');
    expect(Reachability.private_.text, 'Private');
    expect(messageSizeMax, 1 << 22);
  });
}
