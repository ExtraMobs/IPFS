---
test-group: interop
generated: 2026-08-24T07:56:46.034696
---

# `test/interop/`

## `test/interop/bin/setup.dart`


## `test/interop/lib/cid_matcher.dart`


## `test/interop/lib/dart_ipfs_client.dart`


## `test/interop/lib/helia_client.dart`


## `test/interop/lib/kubo_client.dart`


## `test/interop/test/bitswap_test.dart`

- P0 Bitswap fetch with Kubo
- dart_ipfs can fetch a block from Kubo via Bitswap
- Kubo can fetch a block from dart_ipfs via Bitswap

## `test/interop/test/car_test.dart`

- P0 CAR exchange with Kubo
- dart_ipfs can export a CAR that Kubo can import
- Kubo can export a CAR that dart_ipfs can import
- CAR format validation
- CAR export/import roundtrip preserves data
- CAR with multiple blocks exports and imports correctly

## `test/interop/test/dht_test.dart`

- P1 DHT provide/find with Kubo
- dart_ipfs provides a CID and Kubo finds it as a provider
- Kubo provides a CID and dart_ipfs finds it as a provider

## `test/interop/test/gateway_test.dart`

- P0 Gateway retrieval with Kubo
- trustless gateway returns raw block with correct headers
- trustless gateway returns a CAR response
- default gateway response returns the original content

## `test/interop/test/helia_test.dart`

- Helia basic connectivity
- Helia server is reachable
- Helia version endpoint works
- Helia can add and retrieve data
- Helia Bitswap/CAR interop
- dart_ipfs can exchange a CAR with Helia

## `test/interop/test/ipns_test.dart`

- P1 IPNS resolution with Kubo
- dart_ipfs publishes a signed IPNS record and Kubo resolves it
- Kubo publishes a signed IPNS record and dart_ipfs resolves it

