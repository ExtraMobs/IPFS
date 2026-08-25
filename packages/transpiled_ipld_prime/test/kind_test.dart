// Port of go-ipld-prime's datamodel/kind_test.go: TestErrWrongKind_String.
import 'package:test/test.dart';
import 'package:transpiled_ipld_prime/transpiled_ipld_prime.dart';

void main() {
  test('TestErrWrongKind_String', () {
    expect(const KindSet([]).toString(), equals('<empty KindSet>'));
    expect(
      const WrongKindException(
        methodName: '',
        appropriateKind: KindSet([]),
        actualKind: Kind.invalid,
      ).toString(),
      equals(
        'func called on wrong kind: "" called on a INVALID node, but only '
        'makes sense on <empty KindSet>',
      ),
    );
  });
}
