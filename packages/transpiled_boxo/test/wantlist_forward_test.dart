import 'package:test/test.dart';
import 'package:transpiled_boxo/bitswap/wantlist.dart';
import 'package:transpiled_boxo/src/bitswap/client/wantlist/want_type.dart';
import 'package:transpiled_cid/transpiled_cid.dart';

void main() {
  test('deprecated forward aliases client wantlist', () {
    final cid = CID.decode('QmQL8LqkEgYXaDHdNYCG2mmpow7Sp8Z8Kt3QS688vyBeC7');
    final wantlist = newWantlist();
    expect(wantlist, isA<Wantlist>());
    expect(wantlist.add(cid, 1, WantType.block), isTrue);
    expect(newRefEntry(cid, 2).cid, equals(cid));
  });
}
