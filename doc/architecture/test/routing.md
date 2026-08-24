---
test-group: routing
generated: 2026-08-24T09:15:13.519118
---

# `test/routing/`

## `test/routing/content_routing_test.dart`

- ContentRouting
- start calls initialize and start on DHT client
- stop calls stop on DHT client
- findProviders returns base58 encoded peer IDs
- findProviders returns empty list on error
- resolveDNSLink handles success and error
- start error handling
- stop error handling
- findProviders with multiple providers
- findProviders with no providers
- provide calls addProvider on DHT client
- provide rethrows error on failure
- resolveDNSLink success path

## `test/routing/content_routing_test.mocks.dart`


## `test/routing/delegated_routing_test.dart`

- DelegatedRoutingHandler
- findProviders success 200 with providers
- findProviders 200 with no providers key
- findProviders 404 returns success empty
- findProviders error status code
- findProviders exception
- dispose closes client
- RoutingResponse helpers

## `test/routing/delegated_routing_test.mocks.dart`


## `test/routing/ipni_client_test.dart`

- IPNIClient
- findProviders success with providers
- findProviders 404 returns empty success
- findProviders error status code
- findProviders invalid JSON response
- findProviders with no Providers key returns empty
- findProviders exception returns error
- findProviders merges and deduplicates by peer ID
- addEndpoint and removeEndpoint
- provider with empty ID is skipped
- IPNIProvider toJson
- IPNIProviderMetadata toJson
- IPNIResponse helpers
- dispose closes client
- default endpoint is cid.contact

## `test/routing/ipni_client_test.mocks.dart`


## `test/routing/reframe_routing_test.dart`

- ReframeRoutingClient
- findProviders success with providers
- findProviders with top-level Providers key
- findProviders 404 returns empty success
- findProviders error status code
- findProviders invalid JSON response
- findProviders with no Providers key returns empty
- findProviders exception returns error
- findProviders merges results from multiple endpoints
- addEndpoint and removeEndpoint
- provider with empty ID is skipped
- ReframeProvider toJson
- ReframeResponse helpers
- dispose closes client

## `test/routing/reframe_routing_test.mocks.dart`


