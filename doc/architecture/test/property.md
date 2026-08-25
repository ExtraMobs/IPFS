---
test-group: property
generated: 2026-08-25T14:23:03.822615
---

# `test/property/`

## `test/property/cbor_property_test.dart`

- CBOR property-based tests
- for any map: encode as DAG-CBOR -> decode -> equals original map
- for any list: encode -> decode -> equals original list
- for any int: encode -> decode -> equals original int
- for any string: encode -> decode -> equals original string
- for any bytes: encode -> decode -> equals original bytes
- for any bool: encode -> decode -> equals original bool
- for any null: encode -> decode -> equals null
- encoding is deterministic: same logical content -> identical bytes
- canonical map ordering: insertion order does not affect encoding
- nested structures round-trip: map of lists of maps

## `test/property/cid_property_test.dart`

- CID property-based tests
- for any valid bytes: encode as CIDv1 -> decode -> equals original bytes
- for any CID: encode -> decode -> equals original CID
- for any CID: base32 encode -> decode -> equals original CID
- for any CID: base58btc encode -> decode -> equals original CID
- for any CID: base16 encode -> decode -> equals original CID
- for any CID: toBytes -> fromBytes -> equals original CID
- CIDv0 round-trip: v0 -> encode -> decode -> equals original
- CIDv0 toBytes -> fromBytes -> equals original
- for any CID: encode is deterministic (same CID always produces same string)
- for any CID: validate() returns true
- different content produces different CIDs (injectivity)
- same content produces same CID (determinism)

## `test/property/dht_property_test.dart`

- DHT property-based tests
- for any peer ID: XOR distance to itself is 0
- for any two peer IDs: distance metric is symmetric
- distance is non-negative
- distance between identical bytes is 0 regardless of length
- bucket index is in valid range [0, 255]
- bucket index for distance 0 is 0
- bucket index for distance d is d-1 for d > 0
- peers differing only in the last bit have distance 1
- peers differing in the first bit have maximum distance
- XOR distance satisfies triangle inequality for same-length peer IDs
- PeerId base58 round-trip: toBase58 -> fromBase58 -> equals original
- PeerId base36 round-trip: toBase36 -> fromBase36 -> equals original
- PeerId base36 round-trips leading zero bytes
- PeerId equality: same bytes -> equal
- PeerId inequality: different bytes -> not equal

## `test/property/unixfs_property_test.dart`

- UnixFS property-based tests
- for any file data: chunk -> build UnixFS -> root block is valid DAG-PB
- chunk size property: different chunk sizes produce valid UnixFS
- small file (single chunk): root has one link and correct filesize
- empty file: produces a valid root with zero links
- leaf blocks can be decoded as UnixFSNode and contain original data
- root CID is deterministic: same data -> same root CID
- different data produces different root CIDs
- rawLeaves option produces raw-codec leaf blocks
- CIDv0 option produces CIDv0 blocks

