---
test-group: fuzz
generated: 2026-08-24T07:44:28.716597
---

# `test/fuzz/`

## `test/fuzz/_fuzz_helpers.dart`


## `test/fuzz/cbor_fuzz_test.dart`

- CBOR fuzz
- random byte sequences of various lengths do not crash
- empty input throws a known exception
- truncated valid CBOR sequences are handled gracefully
- CBOR with invalid major types is handled gracefully
- CBOR with extreme nesting depth is handled gracefully
- CBOR with invalid UTF-8 strings is handled gracefully
- random bytes with CBOR-like first byte do not crash
- corrupted valid CBOR with flipped bytes is handled gracefully
- lenient mode handles random bytes without crashing

## `test/fuzz/cid_fuzz_test.dart`

- CID fuzz
- random byte sequences (1-100 bytes) do not crash
- empty input throws a known exception
- very long input (10000+ bytes) is handled gracefully
- valid CID with corrupted version byte is handled gracefully
- valid CID with corrupted multihash is handled gracefully
- truncated CIDs are handled gracefully
- random strings do not crash CID.decode
- empty string throws a known exception
- CIDv0-prefixed random strings are handled gracefully
- every single-byte input is handled gracefully

## `test/fuzz/multiaddr_fuzz_test.dart`

- Multiaddr fuzz
- random bytes fed to multiaddrFromBytes do not crash
- empty bytes are handled gracefully
- valid multiaddr with corrupted protocol codes
- truncated multiaddr bytes are handled gracefully
- corrupted valid multiaddr with flipped bytes
- random strings fed to parseMultiaddrString do not crash
- valid multiaddr strings with corrupted protocol codes
- truncated multiaddr strings are handled gracefully
- Peer.fromMultiaddr with random strings is handled gracefully

## `test/fuzz/multihash_fuzz_test.dart`

- Multihash fuzz
- random bytes do not crash Multihash.decode
- empty input throws a known exception
- valid multihash with corrupted hash function code
- valid multihash with corrupted length field
- truncated multihashes are handled gracefully
- multihash with extreme length field is handled gracefully
- every single-byte and two-byte input is handled gracefully
- corrupted valid multihash with flipped bytes

## `test/fuzz/protobuf_fuzz_test.dart`

- Protobuf fuzz
- Bitswap message decoder
- random bytes fed to Bitswap Message.fromBytes do not crash
- truncated protobuf messages are handled gracefully
- protobuf with invalid wire types is handled gracefully
- corrupted valid Bitswap messages with flipped bytes
- empty bytes are handled gracefully
- direct pb.Message.fromBuffer with random bytes does not crash
- DHT message decoder
- random bytes fed to DHT PingRequest.fromBuffer do not crash
- truncated DHT messages are handled gracefully
- DHT messages with invalid wire types are handled gracefully
- corrupted valid DHT messages with flipped bytes
- DHT envelope decoder
- random bytes fed to DHTEnvelope.fromBytes do not crash
- truncated DHT envelopes are handled gracefully
- empty bytes are handled gracefully

