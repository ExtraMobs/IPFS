// Port of go-datastore's basic_ds_test.go: TestLogDatastore, running the
// full dstest conformance suite against a LogDatastore wrapping a
// MapDatastore. Go redirects `log.SetOutput` to discard the noise; this
// port doesn't need the equivalent since `developer.log` doesn't print to
// stdout during `dart test` by default.
import 'package:test/test.dart';
import 'package:transpiled_datastore/transpiled_datastore.dart';

import 'dstest/basic_tests.dart';
import 'dstest/test_util.dart';

void main() {
  test('LogDatastore passes the full dstest conformance suite', () async {
    final ds = LogDatastore(MapDatastore());
    await subtestAll(ds);
    for (final subtest in batchSubtests) {
      await subtest(ds);
    }
  });
}
