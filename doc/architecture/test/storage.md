---
test-group: storage
generated: 2026-08-24T07:56:46.038429
---

# `test/storage/`

## `test/storage/hive_datastore_test.dart`

- HiveDatastore
- throws StateError when used before init
- init is idempotent
- put/get/has/delete round-trips for blocks prefix
- routes pins/dht/default prefixes into separate boxes
- query without prefix iterates all boxes
- query with prefix filters to its target box
- query keysOnly skips loading values
- query honours custom filters

