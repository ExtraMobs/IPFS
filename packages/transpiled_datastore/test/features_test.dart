// Port of go-datastore's features_test.go: TestFeatureByName,
// TestFeaturesForDatastore.
import 'package:test/test.dart';
import 'package:transpiled_datastore/transpiled_datastore.dart';

void main() {
  test('TestFeatureByName', () {
    final feat = featureByName(featureNameBatching);
    expect(feat, isNotNull);
    expect(feat!.name, equals(featureNameBatching));

    expect(featureByName('UnknownFeature'), isNull);
  });

  test('TestFeaturesForDatastore', () {
    List<Feature> byNames(List<String> names) => [for (final n in names) featureByName(n)!];

    final cases = <(String, Datastore?, List<String>)>[
      ('MapDatastore', MapDatastore(), const ['Batching']),
      (
        'NullDatastore',
        NullDatastore(),
        const ['Batching', 'Checked', 'GC', 'Persistent', 'Scrubbed', 'Transaction'],
      ),
      (
        'LogDatastore',
        LogDatastore(MapDatastore()),
        const ['Batching', 'Checked', 'GC', 'Persistent', 'Scrubbed'],
      ),
      ('nil datastore', null, const <String>[]),
    ];

    for (final (name, ds, expectedNames) in cases) {
      final feats = featuresForDatastore(ds);
      expect(feats, hasLength(expectedNames.length), reason: name);
      expect(feats, equals(byNames(expectedNames)), reason: name);
    }
  });
}
