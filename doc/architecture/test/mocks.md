---
test-group: mocks
generated: 2026-08-24T07:49:40.312018
---

# `test/mocks/`

## `test/mocks/in_memory_datastore.dart`


## `test/mocks/in_memory_datastore_test.dart`

- InMemoryDatastore
- initializes and closes correctly
- stores and retrieves data
- has() returns correct existence status
- deletes data
- query() returns matching entries
- query with keysOnly returns null values
- query without keysOnly returns values
- throws error when operating on closed datastore
- get() on non-existent key returns null
- put() with same key overwrites
- handles long keys
- handles special characters in keys
- prefix filtering works correctly

## `test/mocks/mock_block_store.dart`


## `test/mocks/mock_block_store_test.dart`

- MockBlockStore
- lifecycle operations record calls
- putBlock returns success and records call
- getBlock returns block if exists
- getBlock returns not found if missing
- removeBlock removes and returns success
- removeBlock returns error if not found
- operations fail when not started
- reset clears all state
- getStatus returns correct metadata

## `test/mocks/mock_dht_handler.dart`


## `test/mocks/mock_dht_handler_test.dart`

- MockDHTHandler
- lifecycle tracks state correctly
- putValue/getValue stores and retrieves
- getValue throws if not found
- simulates delays
- simulates errors on next call
- reset clears data and state
- operations throw if not running

## `test/mocks/mock_http_client.dart`


## `test/mocks/mock_integration_test.dart`

- Mock Infrastructure Integration
- InMemoryDatastore works as expected
- MockDHTHandler implements IDHTHandler
- MockDHTHandler stores and retrieves values
- MockDHTHandler tracks method calls
- MockDHTHandler simulates delays
- MockDHTHandler simulates errors
- MockDHTHandler resets state correctly
- Mock infrastructure works together
- Multiple test blocks can be created and stored
- InMemoryDatastore pin functionality via key prefix
- Test Helpers
- createTestBlock creates valid blocks
- createTestBlocks creates multiple blocks
- generateTestPrivateKey creates a key
- TestBlockGraph.create creates linked blocks

## `test/mocks/mock_nat_traversal_service.dart`


## `test/mocks/mock_security_manager.dart`


## `test/mocks/test_helpers.dart`


