---
test-group: (root)
generated: 2026-08-25T08:48:16.286039
---

# `test/(root)/`

## `test/block_test.dart`

- Block
- equality is by CID object identity (structural), not by encoded 
- creates block from data and computes CID
- validates matching CID
- validation fails for tampered data
- validateSync is structural
- toBytes returns data
- InMemoryBlockStore
- stores and retrieves block
- reports missing block
- removes block
- returns all blocks
- getStatus reports block count and total size
- gc is a documented no-op without pin information

## `test/cid_prefix_test.dart`

- Prefix
- v1 prefix.sum matches a manually-built CID
- v0 prefix.sum matches a manually-built CID
- prefix equality is structural, not identity

## `test/cid_test.dart`

- CID
- creates CID v0 from 32-byte SHA2-256 hash
- creates CID v1 from content
- round-trips CID through string encoding
- round-trips CID v1 through bytes
- returns CIDv0 bytes from toBytes
- toPrefixBytes omits digest
- CID v1 encodes with different bases
-  CID v0 rejects non-32-byte hash
- Multicodec
- looks up codec codes
- looks up codec names
- rejects unsupported codec
- CID gap-closing additions (Phase 1)
- fromContent with version:0 produces a CIDv0
- fromContent rejects unsupported hashType
- computeForData matches fromContent for the same input
- computeForDataSync matches the async fromContent digest
- fromPrefixBytes reconstructs the same CID given matching data
- validate accepts a well-formed CIDv1
- validate rejects a CIDv0 with a non-dag-pb codec
- MultihashUtils
- encodes SHA2-256 digest
- decodes multihash

## `test/codec_test.dart`

- RawCodec
- encodes and decodes Uint8List
- rejects non-Uint8List input
- DagJsonCodec
- encodes and decodes map
- encodes and decodes bytes
- DagCborCodec
- encodes and decodes map
- encodes and decodes list
- encodes and decodes CID link
- declares correct name and code

## `test/crypto_test.dart`

- CryptoUtils
- deriveKey returns deterministic key for same password/salt
- deriveKey returns different keys for different salts
- encrypt/decrypt round trip
- decrypt fails with wrong key
- constantTimeEquals
- Ed25519Signer
- generates key pair
- sign/verify round trip
- verify fails with wrong signature
- deterministic key pair from seed

## `test/dag_cbor_canonical_test.dart`

- DagCborCodec canonical encoding
- sorts map keys in byte-wise lexicographic order
- canonical encoding is deterministic regardless of input order
- encodes and decodes BigInt within int64 range as regular int
- encodes positive BigInt beyond int64 with tag 2
- encodes negative BigInt beyond int64 with tag 3
- round-trips large positive BigInt
- round-trips large negative BigInt
- round-trips BigInt zero
- encodes CID link with tag 42
- round-trips CID link
- round-trips nested map with mixed types
- encodes double as 64-bit float
- canonical encoding produces consistent bytes for same data
- rejects unsupported types
- handles empty map
- handles empty list
- handles null value

## `test/data_structures_test.dart`

- ImmutableBytes
- value-based equality
- returns defensive copy
- TypedMap
- gets typed values with defaults
- contains key and length

## `test/dns_resolver_parity_test.dart`

- dnsMatches
- matches dns-bearing multiaddrs
- Resolver.resolve -- simple IP resolution
- dns4 keeps only v4 addresses
- dns6 keeps only v6 addresses
- dns keeps every address
- resolve() only resolves the first DNS component
- resolving repeatedly walks every DNS component (middle)
- resolving repeatedly walks every DNS component (sandwiched)
- dnsaddr resolves TXT records
- a non-DNS multiaddr resolves to itself
- a suffix with no matching dnsaddr record yields no results
- a domain with no records yields no results
- resolving null yields no results
- dnsaddr suffix matching
- matches the tcp/123/http suffix specifically
- matches the tcp/123 suffix specifically
- resolving a huge record set is capped at 100 addresses
- custom per-domain resolvers
- match left-to-right, most specific wins
- isFqdn / fqdn
- isFqdn(${input.isEmpty ? 
- fqdn(${input.isEmpty ? 

## `test/ecdsa_key_parity_test.dart`

- ECDSA (P-256) -- real Go-generated vector
- unmarshal SEC1 private key, re-marshal matches byte-for-byte
- unmarshal PKIX public key, re-marshal matches byte-for-byte
- private key
- verifies a real Go-produced ECDSA/SHA-256 signature
- rejects a tampered signature
- rejects a signature over the wrong message
- Dart
- ECDSA (P-256) -- generation and round-trip
- a freshly generated key signs and verifies its own signature
- marshal -> unmarshal round-trips a freshly generated key
- rejects a public key on the wrong curve OID

## `test/ed25519_key_parity_test.dart`

- Ed25519 -- real Go-generated vector
- unmarshal 64-byte private key, re-marshal matches byte-for-byte
- unmarshal 32-byte public key, re-marshal matches byte-for-byte
- private key
- verifies a real Go-produced EdDSA signature
- rejects a tampered signature
- Dart
- rejects a private key with a mismatched redundant public key
- Ed25519 -- generation and round-trip
- a freshly generated key signs and verifies its own signature
- marshal -> unmarshal round-trips a freshly generated key
- rejects a private key of the wrong length

## `test/key_codec_test.dart`

- key_codec
- RSA public/private key round-trip through the generic codec
- Ed25519 public/private key round-trip through the generic codec
- Secp256k1 public/private key round-trip through the generic codec
- ECDSA public/private key round-trip through the generic codec
- a signature made with one type verifies through the generically-decoded key

## `test/multiaddr_parity_test.dart`

- Multiaddr.parse -- must succeed (go-multiaddr `good`)
- Multiaddr.parse -- must fail (go-multiaddr TestConstructFails)
- Multiaddr.fromBytes
- rejects an empty byte sequence
- p2p transcoder cross-base parity
- base58, base32, and base36 CID PeerIds decode to the same value
- encapsulate / decapsulate
- decapsulate removes the matched suffix
- encapsulate then decapsulate round-trips
- valueForProtocol
- finds the first matching component

## `test/multibase_base32_test.dart`

- MultibaseUtils base32 (RFC 4648 §10 official test vectors)
- encodes 
- decodes RFC 4648 vector for 
- MultibaseUtils base32 leading-zero-byte regression
- single zero byte round-trips without losing length
- all-zero 40-byte sequence round-trips exactly
- leading zero byte followed by non-zero data round-trips exactly
- real-world raw-codec CIDv1 byte sequence with leading-zero digest 

## `test/multibase_parity_test.dart`

- MultibaseUtils parity with go-multibase (sampleBytes)
- encode $name
- decode $name
- MultibaseUtils parity with go-multibase spec CSVs
- ${entry.key} -- ${plaintext.length} byte(s)
- MultibaseUtils.decode -- case-insensitive (non-canonical inputs)
- MultibaseUtils -- unsupported encodings match go-multibase
- base8/base10/base45 are not implemented (matches upstream)
- empty string is rejected on decode

## `test/multicodec_expanded_test.dart`

- Multicodec expanded registry
- has at least 50 codecs
- supports all IPLD codecs
- supports all multihash codecs
- supports multiaddr codecs
- supports key type codecs
- supports namespace codecs
- code() returns correct codes for known codecs
- name() returns correct names for known codes
- code() throws for unknown codec
- name() throws for unknown code
- supportsByCode() returns true for known codes
- supported returns unmodifiable list
- round-trip: code -> name -> code is stable

## `test/multicodec_parity_test.dart`

- Multicodec parity with go-multicodec code_table.go
- has all 603 entries from the real table
- round-trip: every code -> name -> code is stable
- spot-check values across the file
- 0x300 range matches the real table, not the previous drifted names
- no duplicate codes or names

## `test/multihash_sum_parity_test.dart`

- MultihashUtils.sum parity with go-multihash
- unsupported algorithm throws

## `test/rsa_key_parity_test.dart`

- RSA -- real Go-generated vector
- unmarshal PKCS1 private key, re-marshal matches byte-for-byte
- unmarshal PKIX public key, re-marshal matches byte-for-byte
- private key
- verifies a real go-libp2p-style SHA256/PKCS1v1.5 signature
- rejects a tampered signature
- rejects a signature over the wrong message
- signs with Dart
- RSA -- generation and round-trip
- a freshly generated key signs and verifies its own signature
- rejects a key smaller than minRsaKeyBits
- marshal -> unmarshal round-trips a freshly generated key

## `test/secp256k1_key_parity_test.dart`

- Secp256k1 -- real Go-generated vector
- unmarshal 32-byte private key, re-marshal matches byte-for-byte
- unmarshal compressed public key, re-marshal matches byte-for-byte
- private key
- verifies a real dcrd RFC6979/DER signature
- rejects a tampered signature
- rejects a signature over the wrong message
- Dart
- Secp256k1 -- generation and round-trip
- a freshly generated key signs and verifies its own signature
- signing the same key/message twice is deterministic
- marshal -> unmarshal round-trips a freshly generated key
- rejects a private key of the wrong length

