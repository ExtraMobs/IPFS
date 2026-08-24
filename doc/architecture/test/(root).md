---
test-group: (root)
generated: 2026-08-24T09:15:13.511653
---

# `test/(root)/`

## `test/advanced_coverage_analyzer.dart`


## `test/coverage_analyzer.dart`


## `test/gateway_selector_test.dart`

- Gateway Selector Integration
- GatewayMode.custom uses the provided URL
- GatewayMode.internal does NOT use the gateway (for non-existent local content)
- GatewayMode.public uses default ipfs.io logic (Integration Check)

## `test/protocol_test.dart`


## `test/rpc_test.dart`

- RPC Protocol Tests
- handleBlockPut should store the block

## `test/umbrella_reexports_test.dart`

- Umbrella re-exports
- CID API is available from umbrella and core
- Block API is available from umbrella and core
- InMemoryBlockStore is available from umbrella
- CryptoUtils is available from umbrella and core
- CarHeader.roots exposes the same CID type the barrel exports 

