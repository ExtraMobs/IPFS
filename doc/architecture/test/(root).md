---
test-group: (root)
generated: 2026-09-02T08:21:38.725908
---

# `test/(root)/`

## `test/advanced_coverage_analyzer.dart`


## `test/architecture_boundary_test.dart`

- architecture boundaries (foundation layer, Phase 2)
- platform has no lib/src dependencies
- utils only depends on core and platform
- core (outside the ipfs_node/ and builders/ composition root) 
- transport does not depend on the protocol/routing/service layers
- network does not depend on the protocol/routing/service layers
- architecture boundaries (protocol layer, Phase 3)
- protocols/* only cross-import each other via the documented pairs 

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

