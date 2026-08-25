---
test-group: utils
generated: 2026-08-25T08:48:49.428226
---

# `test/utils/`

## `test/utils/base58_test.dart`

- Base58
- encode/decode empty bytes
- encode/decode simple string
- encode/decode with leading zeros
- decode invalid characters throws ArgumentError
- bigIntToUint8List - zero
- encode/decode large value (multi-hash style)

## `test/utils/car_test.dart`

- CAR Format
- CarWriter creates a valid CAR v1 archive
- CarWriter creates a valid CAR v2 archive with index
- CarReader reads from a stream
- CarHeader value equality and fields
- CarSection reports serialized size
- IndexBuilder emits sorted IndexSorted index
- IndexBuilder emits sorted MultihashIndexSorted index
- CarWriter rejects missing roots
- CarReader rejects CAR v2 with invalid pragma

## `test/utils/dnslink_resolver_test.dart`

- DNSLinkResolver
- resolve success
- resolve failure status code
- resolve exception

## `test/utils/dnslink_resolver_test.mocks.dart`


## `test/utils/encoding_test.dart`

- EncodingUtils
- toBase58 and fromBase58 roundtrip
- fromBase58 empty string throws
- fromBase58 invalid prefix throws
- fromBase58 unsupported encoding throws
- isValidCIDBytes - CIDv0
- isValidCIDBytes - CIDv1
- isValidCIDBytes - invalid bytes
- isValidMultibasePrefix
- getEncodingFromPrefix
- codec conversion
- supportedCodecs list
- cidToBytes

## `test/utils/encoding_utils_test.dart`

- EncodingUtils
- Base58
- toBase58 encodes correctly with z prefix
- fromBase58 throws on empty string
- fromBase58 throws on invalid prefix
- fromBase58 throws on unsupported supported prefix
- CID Validation
- isValidCIDBytes returns true for valid CIDv0
- isValidCIDBytes handles invalid data gracefully
- Codecs
- getCodecFromCode returns correct strings
- getCodeFromCodec returns correct codes
- getCodecFromCode throws on unknown code
- getCodeFromCodec throws on unknown codec
- supportedCodecs list is not empty
- Multibase
- isValidMultibasePrefix correctly identifies prefixes
- getEncodingFromPrefix returns correct encoding name

## `test/utils/generate_message_id_test.dart`

- MessageId Generator
- generateMessageId returns non-empty string
- generateMessageId returns unique IDs
- generateMessageId returns UUID v4 format
- multiple calls generate different IDs

## `test/utils/generic_lru_cache_test.dart`

- GenericLRUCache
- basic operations
- puts and gets values
- returns null for missing keys
- updates existing values
- reports correct length
- eviction
- evicts LRU when at capacity
- get updates LRU order
- calls onEvict callback
- remove
- removes existing key
- returns null for missing key
- clear
- removes all entries
- calls onEvict for all entries
- getOrCompute
- returns cached value if exists
- computes and caches if missing
- containsKey
- returns true for existing keys
- TimedLRUCache
- expires entries after TTL
- fresh entries are not expired
- clear empties the timestamps and entries
- GenericLRUCache extras
- isFull reports when at capacity
- getOrComputeSync caches the computed value
- keys returns MRU-first order
- eviction at capacity removes the LRU node

## `test/utils/keystore_test.dart`

- Keystore
- add and get key pair
- getKeyPair throws if not found
- remove key pair
- remove non-existent key pair (warning path)
- listKeyPairs
- serialize and deserialize
- withConfig named constructor
- privateKey getter (defaultKeyName)
- verifySignature - simple hex pubkey
- verifySignature - base64 pubkey
- verifySignature - raw string fallback
- exportKeysForMigration and clearAfterMigration

## `test/utils/logger_test.dart`

- Logger
- initializeMetrics succeeds
- emits info/debug/verbose/warning without throwing
- debug/verbose suppressed when flags disabled
- setLevel maps the documented levels
- setLevel rejects unknown levels

## `test/utils/message_id_verified_test.dart`

- Message ID Generation - Verified Tests
- generateMessageId returns non-empty string
- generateMessageId creates unique IDs
- generateMessageId format is consistent
- concurrent ID generation produces unique IDs
- IDs remain unique across batches

## `test/utils/private_key_test.dart`

- IPFSPrivateKey
- generate and sign/verify roundtrip
- fromString and sign/verify
- fromBytes - ECDSA
- fromBytes - Unsupported algorithm
- signature verification failure on wrong data
- publicKeyBytes for non-ECDSA (theoretical)

## `test/utils/varint_test.dart`

- Varint
- encode/decode small integers
- encode/decode multi-byte integers
- decode stops at MSB 0
- encode large integers

