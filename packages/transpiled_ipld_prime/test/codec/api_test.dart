// Parity checks for go-ipld-prime's codec/api.go public values.
import 'package:test/test.dart';
import 'package:transpiled_ipld_prime/codec.dart';

void main() {
  test('ErrBudgetExhausted.Error', () {
    expect(
      const BudgetExhaustedException().toString(),
      'decoder resource budget exhausted (message too long or too complex)',
    );
  });

  test('MapSortMode values match Go iota order', () {
    expect(MapSortMode.none.index, 0);
    expect(MapSortMode.lexical.index, 1);
    expect(MapSortMode.rfc7049.index, 2);
  });
}
