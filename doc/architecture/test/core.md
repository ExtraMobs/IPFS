---
test-group: core
generated: 2026-08-24T09:15:13.512479
---

# `test/core/`

## `test/core/bitswap/bitswap_service_test.dart`

- BitswapService
- convertToProtoBlock converts Block to proto
- convertFromProtoBlock converts proto to Block

## `test/core/block_dag_test.dart`

- Block
- fromData computes CID and stores data
- validate returns true for correct data
- validate returns false for corrupted data
- validateSync performs structural checks
- operator == and hashCode deep dive
- proto roundtrip
- Bitswap and raw bytes conversion
- MerkleDAGNode
- create and toBytes/fromBytes
- cid property computation
- toString and HAMTShard coverage

## `test/core/blockstore_test.dart`

- Block Tests
- should create from data
- should serialize to/from proto
- should serialize to/from bitswap proto
- BlockStore Tests
- should start and stop
- should put and get block
- should fail to get non-existent block
- should remove block
- should get all blocks
- should get status
- gc removes unpinned blocks
- putBlock handles already indexed block
- removeBlock handles non-existent block
- getBlock handles disk-based blocks
- hasBlock returns false for non-existent
- getStatus includes pinned blocks count
- getAllBlocks returns empty list when empty

## `test/core/builders/ipfs_node_builder_test.dart`

- IPFSNodeBuilder
- build offline node
- build node with minimal config

## `test/core/car_edge_cases_test.dart`

- CarHeader edge cases
- CarWriter rejects empty roots
- CarHeader equals and hashCode are stable
- CarSection edge cases
- equals distinguishes bytes
- CarReader error cases
- empty input throws CarHeaderException
- truncated header varint throws
- varint too long throws
- truncated section throws CarSectionException
- section length smaller than CID throws
- CAR v2 invalid pragma throws
- CAR v2 header too short throws
- CAR v2 characteristics must be zero
- CAR v2 index unknown format throws
- CarWriter error cases
- block too large throws CarSectionException
- missing root CID throws CarHeaderException
- rejects index without v2
- IndexBuilder
- builds sorted index with multihash sorting
- builds sorted index without multihash sorting

## `test/core/car_full_test.dart`

- CAR Utilities Deep Coverage
- CarWriter constructor and basic properties
- CarWriter v2 with index
- CarWriter rejects index without v2
- CarWriter rejects empty roots
- CarReader/Writer roundtrip v1
- CarReader/Writer roundtrip v2 with index
- CarReader findCID falls back to linear scan for CAR v1
- CarWriter closeStream yields equivalent bytes
- CarWriter file roundtrip
- CarReader/Writer preserve cid and block bytes
- CarHeader toString is descriptive

## `test/core/cbor/byte_reader_comprehensive_test.dart`

- ByteReader - Comprehensive Tests
- Initialization
- creates reader with byte list
- creates reader with empty list
- initial position is zero
- readByte
- reads single byte and advances position
- reads bytes sequentially
- throws StateError when no bytes remain
- throws StateError on empty reader
- handles binary values correctly
- readBytes
- reads multiple bytes at once
- reads all remaining bytes
- reads zero bytes
- throws StateError when insufficient bytes
- sequential readBytes calls
- mixed readByte and readBytes
- isBreak
- returns true when next byte is 0xFF
- returns false when next byte is not 0xFF
- returns false when no bytes remaining
- isBreak after consuming bytes
- isBreak does not consume byte
- remaining
- returns all bytes initially
- returns remaining after reading
- returns empty list when all consumed
- hasRemaining
- returns true when bytes available
- returns false when all bytes consumed
- returns false for empty reader
- updates after each read
- position
- tracks read position accurately
- position equals length when all consumed
- Edge Cases
- handles large byte arrays
- handles all-zero bytes
- handles all-max bytes
- single byte reader
- Error Conditions
- readBytes with negative count throws
- multiple reads past end all throw

## `test/core/cbor/byte_reader_test.dart`

- ByteReader
- readByte moves position
- readByte throws at end
- readBytes returns correct sublist
- readBytes throws if not enough
- isBreak detects 0xFF
- hasRemaining and remaining

## `test/core/cbor/enhanced_cbor_handler_test.dart`

- EnhancedCBORHandler
- cborTags
- contains the standard IPLD CBOR tags
- Encoding and decoding primitives
- round-trips null, bool, int, float, string
- round-trips int64 boundary values
- Bytes
- round-trips raw bytes as plain CBOR byte strings
- rejects non-standard tag 45 bytes
- Links
- round-trips CIDv0 as CBOR tag 42
- round-trips CIDv1 dag-pb as CBOR tag 42
- round-trips CIDv1 dag-json as CBOR tag 42
- round-trips CIDv1 raw as CBOR tag 42
- Canonical map ordering
- encoder sorts keys by length then lexicographic order
- same logical map produces identical bytes regardless of insertion order
- round-trips complex nested map and list
- Big integers
- 2^64 - 1 encodes as unsigned major type 0
- 2^64 encodes as CBOR tag 2
- -2^64 encodes as CBOR negative major type 1, not tag 3
- -2^64 - 1 encodes as CBOR tag 3
- Strict decoding
- rejects unknown tags
- rejects duplicate map keys
- rejects non-canonical map key order
- rejects non-canonical integer encodings
- rejects non-minimal big-integer byte strings
- rejects indefinite-length items
- DagCborOptions limits
- maxStringLength is enforced during decoding
- maxDepth is enforced during decoding
- MerkleDAG conversion
- convertFromMerkleDAGNode correctly shapes IPLDMap
- convertToMerkleLink converts IPLDNode map back to Link
- convertToMerkleLink handles BYTES Hash fallback
- convertToMerkleLink throws if not MAP

## `test/core/cid_coverage_test.dart`

- CID Coverage Expansion
- encode/decode (string representation)
- fromProto and toProto
- fromContent
- computeForData (async)
- operator == and hashCode
- fromBytes edge cases
- decode invalid multibase
- toString returns encoded value
- bytesEqual coverage
- bytesEqual coverage deep
- CIDv0 full coverage
- codec with multi-byte varint
- error paths

## `test/core/cid_test.dart`

- CID
- v0 creates valid CIDv0
- v1 creates valid CIDv1 with different codecs
- toBytes and fromBytes round trip
- toBytes throws on unsupported codec
- validate returns true for valid CIDs

## `test/core/cid_verified_test.dart`

- CID - Verified API Tests
- CID Creation
- computeForDataSync creates CID from data
- computeForDataSync with different codecs
- same data produces same CID
- different data produces different CIDs
- CID Encoding/Decoding
- encode and decode round-trip
- toString returns encoded string
- decode handles CIDv0 format (Qm prefix)
- decode throws on empty string
- toBytes returns Uint8List
- fromBytes round-trip
- fromBytes throws on empty bytes
- CID Properties
- version property is accessible
- codec property is accessible
- multihash property exists
- validate returns true for valid CID
- CID Comparison
- equality operator works
- inequality works
- identical CIDs are equal
- Edge Cases
- handles empty data
- handles large data
- handles binary data
- handles UTF-8 special characters
- Codec Variations
- raw codec
- dag-pb codec
- dag-cbor codec
- fromContent Factory
- creates CID from content
- fromContent with custom codec
- fromContent with custom hash
- Protobuf Conversion
- toProto converts to protobuf
- fromProto round-trip

## `test/core/config/config_test.dart`

- MetricsConfig
- defaults
- fromJson/toJson
- StorageConfig
- defaults
- helpers
- fromJson/toJson
- NetworkConfig
- defaults
- fromJson/toJson
- IPFSConfig
- defaults
- withDefaults factory
- fromJson/toJson

## `test/core/config/gateway_config_test.dart`

- GatewayConfig
- default constructor
- fromJson
- toJson
- corsOrigins defaults to localhost
- corsOrigins round-trips through json

## `test/core/config/ipfs_config_test.dart`

- IPFSConfig
- default constructor values
- withDefaults factory
- toJson / fromJson roundtrip is complete
- fromJson with empty Map
- fromFile - YAML support
- fromFile - JSON support
- customConfig storage

## `test/core/config/metrics_config_test.dart`

- MetricsConfig
- default values
- toJson and fromJson roundtrip
- fromJson with empty Map

## `test/core/config/network_config_test.dart`

- NetworkConfig
- defaults are correct
- fromJson parses correctly
- toJson and fromJson work correctly
- withGeneratedId factory creates config with generated ID
- fromJson with enableMDNS and delegatedRoutingEndpoint
- toJson includes all fields
- ProtocolConfig
- constructor initializes correctly
- constructor uses default values
- constructor with only required parameters
- constructor with zero maxRetries

## `test/core/crypto/crypto_utils_test.dart`

- CryptoUtils
- deriveKey
- derives consistent key from password and salt
- derives different keys with different salts
- derives different keys with different passwords
- supports custom key length
- encrypt/decrypt
- encrypts and decrypts data correctly
- produces different ciphertext each time (random nonce)
- fails to decrypt with wrong key
- rejects key of wrong size
- zeroMemory
- zeros buffer contents
- handles empty buffer
- randomBytes
- generates bytes of correct length
- generates different bytes each call
- input validation
- deriveKey rejects empty password
- deriveKey rejects salts shorter than 8 bytes
- decrypt rejects keys of wrong size
- decrypt rejects ciphertexts shorter than the auth tag
- randomBytes rejects non-positive lengths
- EncryptedData serialisation
- toBytes/fromBytes round-trip
- fromBytes rejects payloads shorter than the nonce
- constantTimeEquals
- returns true for equal buffers
- returns false for different buffers
- returns false for different length buffers

## `test/core/crypto/ecdsa_signer_test.dart`

- EcdsaSigner
- generateKeyPair produces valid P-256 key pair
- sign and verify roundtrip
- verify fails with wrong data
- verify fails with wrong key
- verify fails with invalid signature bytes
- serializePublicKey produces valid DER
- deserializePublicKey reconstructs the same key
- derivePeerId returns non-empty base58 string
- derivePeerId is deterministic for same key
- derivePeerId differs for different keys
- encodePublicKeyPb produces valid protobuf
- encodePublicKeyPb uses ECDSA key type
- decodePublicKeyPb rejects non-ECDSA key type
- EcdsaKeyPair stores both keys
- sign produces different signatures for same data (non-deterministic)

## `test/core/crypto/ed25519_signer_test.dart`

- Ed25519Signer
- generateKeyPair without seed
- generateKeyPair with seed
- generateKeyPair with invalid seed length
- keyPairFromSeed
- keyPairFromSeed with invalid seed length
- sign and verify roundtrip
- verify failure with wrong data
- verify failure with catch path
- extractPublicKeyBytes
- extractSeed
- publicKeyFromBytes
- publicKeyFromBytes invalid length
- KeyPairExtensions.extractSeedAndZero

## `test/core/crypto/encrypted_keystore_test.dart`

- EncryptedKeyEntry
- toJson serializes correctly
- fromJson deserializes correctly
- EncryptedKeystore Lifecycle
- isUnlocked is false by default
- unlock sets isUnlocked to true
- lock sets isUnlocked to false
- EncryptedKeystore Key Management
- generateKey creates new key
- generateKey with label stores label
- generateKey throws for duplicate name
- hasKey returns true for existing key
- hasKey returns false for non-existent key
- getPublicKey returns public key bytes
- getPublicKey returns null for missing key
- removeKey removes key
- keyNames lists all keys
- EncryptedKeystore importSeed
- importSeed stores seed successfully
- importSeed throws for invalid seed length
- EncryptedKeystore getKey
- getKey retrieves decryptable key
- getKey throws for missing key
- EncryptedKeystore Serialization
- serialize produces valid JSON
- deserialize restores keystore
- deserialize throws for unsupported version
- EncryptedKeystore Locked Operations
- generateKey throws when locked
- getKey throws when locked

## `test/core/crypto/pbkdf2_cross_implementation_test.dart`

- PBKDF2 cross-implementation agreement
- agrees on 
- is deterministic across repeated calls (both implementations)

## `test/core/crypto/rsa_signer_test.dart`

- RsaSigner
- generateKeyPair produces valid 2048-bit key pair
- generateKeyPair with custom key size
- generateKeyPair rejects key size below 2048
- sign and verify roundtrip
- verify fails with wrong data
- verify fails with wrong key
- verify fails with invalid signature bytes
- serializePublicKey produces valid DER
- deserializePublicKey reconstructs the same key
- serializePrivateKey produces valid DER
- derivePeerId returns non-empty base58 string
- derivePeerId is deterministic for same key
- derivePeerId differs for different keys
- encodePublicKeyPb produces valid protobuf
- encodePublicKeyPb uses RSA key type
- decodePublicKeyPb rejects non-RSA key type
- RsaKeyPair stores both keys

## `test/core/data_structures/bitfield_test.dart`

- BitField
- creates bitfield of correct size
- rounds up to byte boundary
- all bits are initially false
- setBit sets bit to true
- clearBit sets bit to false
- setBit only affects target bit
- multiple bits can be set
- throws RangeError for negative index
- throws RangeError for index >= size
- BitField Protobuf Serialization
- toProto creates valid proto
- fromProto restores bitfield
- roundtrip preserves all bits

## `test/core/data_structures/block_verified_test.dart`

- Block - Verified API Tests
- Block Creation
- creates block from CID and data
- fromData creates block with computed CID
- fromData with different data creates different blocks
- same data in fromData produces same CID
- Block Properties
- cid property is accessible
- data property is accessible
- data is stored as Uint8List
- Block Equality
- blocks with same CID have matching CID strings
- blocks with different CIDs have different CID strings
- Edge Cases
- handles empty data
- handles large data
- handles binary data
- handles UTF-8 data
- Data Integrity
- data stored matches data retrieved
- CID is derived from data content
- block data is preserved as Uint8List
- Constructor Variations
- direct constructor with CID and data
- fromData computes CID automatically
- Concurrent Operations
- concurrent block creation
- concurrent blocks have unique CIDs

## `test/core/data_structures/blockstore_test.dart`

- BlockStore
- lifecycle: start and stop
- CRUD: put, has, get, remove
- put duplicate block
- get non-existent block
- remove non-existent block
- getAllBlocks and status
- gc removes unpinned blocks
- gc removes all blocks when none are pinned
- gc returns 0 when all blocks are pinned
- pinManager getter returns pin manager
- getStatus includes pinned_blocks count
- getBlock loads from disk when not in memory
- putBlock handles write errors
- removeBlock handles file not found gracefully
- start loads existing blocks from disk
- stop saves pin state
- removeBlock with block in index but not on disk
- hasBlock returns false for non-existent block
- getAllBlocks returns empty list when no blocks
- putBlock with large data
- getStatus returns correct values after multiple operations
- removeBlock removes from index and disk
- gc with no blocks returns 0
- pinManager persists pins across restarts

## `test/core/data_structures/directory_test.dart`

- IPFSDirectoryEntry
- creates entry with required fields
- creates entry with optional mode and mtime
- toLink() creates PBLink
- IPFSDirectoryManager
- build creates a directory node with minimal data
- build includes mode and mtime if provided
- setMode and setModificationTime update internal state
- addEntry adds entries to directory
- build sorts entries by name

## `test/core/data_structures/metadata_test.dart`

- IPLDMetadata
- creates metadata with required size
- creates metadata with all optional fields
- toJson() converts metadata to map
- toJson() handles null optional fields

## `test/core/data_structures/node_stats_test.dart`

- NodeStats
- toProto and fromProto
- fromJson
- toString

## `test/core/data_structures/peer_coverage_test.dart`

- Peer Coverage Tests
- Peer.fromProto and toProto
- Peer.fromMultiaddr success
- Peer.fromMultiaddr with IPv6
- Peer.fromMultiaddr error cases
- parseMultiaddrString more cases
- multiaddrToBytes unsupported type
- multiaddrFromBytes edge cases

## `test/core/data_structures/peer_extended_test.dart`

- Peer Extended Tests
- FullAddress toString
- Peer.fromId
- Peer.toString
- Peer.fromMultiaddr edge cases
- parseMultiaddrString IPv6
- parseMultiaddrString invalid formats
- multiaddrToBytes and multiaddrFromBytes IPv4
- multiaddrToBytes and multiaddrFromBytes IPv6
- multiaddrFromBytes invalid
- multiaddrFromBytes UDP

## `test/core/data_structures/pin_manager_coverage_test.dart`

- PinManager Coverage Completion
- isBlockPinned indirect via _isIndirectlyPinned many
- unpinBlock recursive cleanup - complex removal
- _extractCborReferences: non-string link value
- pinnedBlockCount path - empty references
- unpin non-existent
- getBlockReferences: unknown format throw path
- load and save pin state
- load handles non-existent file
- load handles invalid JSON
- pinBlock with blockstore error
- getPinnedBlocks handles invalid CID strings
- pinBlock with raw format
- unpinBlock with direct pin
- isBlockPinned with empty references
- save handles write errors

## `test/core/data_structures/pin_manager_test.dart`

- PinManager
- direct pinning
- recursive pinning - complex DAG
- indirect pinning check via isBlockPinned
- unpinning recursive cleanup logic
- unpinning recursive - child pinned twice (recursive + direct)
- CBOR list extraction
- errors - getBlockReferences failure
- errors - decodeCbor failure
- CBOR nested map extraction
- recursive pinnedBlockCount includes indirect pins
- getPinnedBlocks handles recursive pins

## `test/core/data_structures/pin_test.dart`

- Pin
- constructor initializes with timestamp
- constructor accepts custom timestamp
- toProto converts to protobuf
- toString returns formatted string
- fromProto creates Pin from protobuf

## `test/core/data_structures_test.dart`

- IPLDMetadata Tests
- should create and serialize correctly
- Peer Tests
- should create from multiaddr
- should serialize to/from protobuf
- validates multiaddr parsing
- Pin Tests
- should create and serialize

## `test/core/datastore_handler_test.dart`

- DatastoreHandler Tests
- should put and get blocks
- should handle missing blocks
- should persist and load pinned CIDs
- should report status
- should handle import and export of CAR files
- should recursively export dag-pb blocks in CAR
- handles putBlock error
- handles getBlock error
- handles hasBlock error
- handles start error
- handles stop error
- handles loadPinnedCIDs error
- handles persistPinnedCIDs error
- handles importCAR error
- handles exportCAR error

## `test/core/di/service_container_test.dart`

- ServiceContainer
- registerSingleton stores and retrieves value
- registerSingleton replaces an existing registration
- registerFactory lazily creates the instance
- registerFactory replaces an existing factory
- isRegistered reports registration state

## `test/core/errors/error_instantiation_verified_test.dart`

- Error Instantiation - Verified Tests
- IPLD Errors
- IPLDEncodingError instantiates correctly
- IPLDDecodingError instantiates correctly
- IPLDResolutionError instantiates correctly
- IPLDStorageError instantiates correctly
- IPLDValidationError instantiates correctly
- IPLDLinkError instantiates correctly
- IPLDSchemaError instantiates correctly
- Graphsync Errors
- BlockNotFoundError instantiates correctly
- BlockParseError instantiates correctly
- GraphTraversalError instantiates correctly
- MessageError instantiates correctly
- RequestTimeoutError instantiates correctly
- RequestHandlingError instantiates correctly
- Datastore Error
- DatastoreError instantiates correctly
- Error Properties
- IPLD errors are Exceptions
- Graphsync errors are Exceptions
- errors have toString

## `test/core/errors/graphsync_errors_test.dart`

- Graphsync Errors
- BlockNotFoundError creates correct message
- BlockParseError includes cause
- GraphTraversalError without cause
- MessageError with cause
- RequestTimeoutError creates correct message
- RequestHandlingError with cause
- All errors are exceptions

## `test/core/errors/node_errors_test.dart`

- IPFSNode error hierarchy
- IPFSNodeError exposes details and stringifies
- IPFSNodeError without details omits parenthetical
- subclasses share the IPFSNodeError parent
- ComponentError formats component name in toString

## `test/core/errors_test.dart`

- IPLD Errors
- IPLDEncodingError
- IPLDDecodingError
- IPLDResolutionError
- IPLDStorageError
- IPLDValidationError
- IPLDLinkError
- IPLDSchemaError

## `test/core/events/event_bus_test.dart`

- EventBus
- subscribe returns stream
- publish delivers event to subscriber
- multiple subscribers receive same event
- typed events are isolated
- dispose closes all streams
- PeerConnectedEvent
- stores peerId and address
- has timestamp
- BlockTransferEvent
- stores transfer details
- sent transfer type
- TransferType
- has received value
- has sent value

## `test/core/interfaces/block_data_test.dart`

- BlockData
- toBytes and size

## `test/core/interfaces/block_store_operations_test.dart`

- BlockStoreOperations Interface
- interface defines required methods

## `test/core/interfaces/interface_validation_test.dart`

- Interface Validation
- BlockStoreOperations interface is defined
- BlockData abstract class is defined
- IBlockStore interface is defined
- All interfaces are accessible

## `test/core/ipfs_node/auto_nat_handler_test.dart`

- AutoNATHandler
- start and stop with direct connectivity
- start with NAT and port mapping
- start with NAT and port mapping failure
- getStatus returns correct info
- already running/stopped warnings
- detectNATType handles error
- attemptPortMapping with no ports in config
- stop handles unmapPort error
- periodic dialback test
- _performDialbackTest handles exception
- _checkDirectConnectivity with empty bootstrap list
- _attemptPortMapping with multiple addresses
- _attemptPortMapping failure

## `test/core/ipfs_node/auto_nat_handler_test.mocks.dart`


## `test/core/ipfs_node/bootstrap_handler_test.dart`

- BootstrapHandler
- start and stop lifecycle
- start when already running
- stop when already stopped
- connection failure handles error
- start handles invalid multiaddr

## `test/core/ipfs_node/bootstrap_handler_test.mocks.dart`


## `test/core/ipfs_node/bootstrap_utils_test.dart`

- IPFSUtils
- isValidCID
- isValidPeerID
- Base64 encoding/decoding
- hashSHA256
- extractCIDFromResponse
- BootstrapHandler Reconnection
- periodic reconnection works
- reconnection with new peers (simulated)
- start/stop multiple times
- connection failure handles error

## `test/core/ipfs_node/bootstrap_utils_test.mocks.dart`


## `test/core/ipfs_node/content_routing_handler_test.dart`

- ContentRoutingHandler
- start and stop
- findProviders DHT success
- findProviders DHT fail fallback to delegated
- findProviders all fail
- resolveDNSLink DHT fallback
- findProviders catches exceptions
- getStatus
- findProviders DHT empty -> IPNI success
- findProviders DHT empty -> IPNI empty -> Reframe success
- getStatus reflects IPNI and Reframe configuration

## `test/core/ipfs_node/content_routing_handler_test.mocks.dart`


## `test/core/ipfs_node/datastore_handler_test.dart`

- DatastoreHandler
- start and stop lifecycle
- start rethrows error
- stop catches error
- putBlock and getBlock
- getBlock returns null when not found or error
- hasBlock and errors
- loadPinnedCIDs
- persistPinnedCIDs
- getStatus
- exportCAR errors when root missing
- exportCAR with links
- importCAR calls putBlock

## `test/core/ipfs_node/datastore_handler_test.mocks.dart`


## `test/core/ipfs_node/dns_link_handler_test.dart`

- DNSLinkHandler
- resolve returns CID from public resolver
- resolve caches result
- resolve tries fallback resolvers on failure
- resolve returns null when all fail
- start and stop clear cache

## `test/core/ipfs_node/ipfs_node_coverage_test.dart`

- IPFSNode Coverage Tests
- Full start and stop sequence
- getHealthStatus with all services
- getHealthStatus with missing service
- addresses getter handles missing NetworkHandler
- bandwidthMetrics when MetricsCollector is registered
- publicKey with Secp256k1 key
- publicKey with empty key bytes
- dhtClient throws when DHTHandler not registered
- constructor throws StateError when required service missing
- resolvePeerId delegates to networkManager
- pinnedCids returns list
- onNewContent returns stream
- cat is alias for get
- ls/pin/unpin/importCAR/exportCAR/findProviders/requestBlock/resolveDNSLink coverage

## `test/core/ipfs_node/ipfs_node_network_events_test.dart`

- IpfsNodeNetworkEvents
- start and connection events
- disconnected event
- dispose

## `test/core/ipfs_node/ipfs_node_network_events_test.mocks.dart`


## `test/core/ipfs_node/ipfs_web_node_coverage_test.dart`

- IPFSWebNode Coverage
- start with bootstrap peers
- addStream handles data
- addStream for empty stream creates root node
- addFile throws UnimplementedError on non-web
- get fallback to Bitswap (uncovered branch)
- publishIPNS and resolveIPNS coverage
- publishIPNS/resolveIPNS throw when not started
- cat uses encode
- double start is idempotent
- stop when not started
- pinning coverage
- addStream throws on empty stream
- addFile returns Stream on web
- get returns null when not in local storage and no peers
- peerID getter returns router peer ID
- bitswap getter throws Error when not started
- pubsub getter throws Error when not started
- securityManager getter throws Error when not started
- WebStubRouter hasStarted returns true
- WebStubRouter connectedPeers returns empty set
- addFile on non-web throws UnimplementedError
- addFile with non-stream on web throws
- get with connected peers attempts Bitswap
- pin and unpin operations
- listPins returns list
- start with custom config
- add with empty data
- addStream with empty stream returns root CID
- get with valid CID from local storage
- get with invalid CID returns null
- cat with CID object
- pin with CID
- unpin with CID
- bootstrap peer connection failure is handled
- multiple bootstrap peers
- add with large data
- get returns null for empty CID string
- cat with string CID
- pin with string CID
- unpin with string CID
- unpin non-existent CID does not throw
- listPins after pinning contains CID
- addStream with single chunk
- addStream with multiple chunks
- bitswap getter returns instance when started
- pubsub getter returns instance when started
- securityManager getter returns instance when started

## `test/core/ipfs_node/ipfs_web_node_test.dart`

- IPFSWebNode
- start and stop
- add and get
- pinning

## `test/core/ipfs_node/ipld_handler_coverage_test.dart`

- IPLDHandler Coverage
- Codec and Storage Errors
- put throws error for unsupported codec
- registerCodec works correctly
- get throws error if block not found
- UnixFS Resolution
- resolvePath /ipfs/cid/file should return file data
- Lifecycle
- start handles error
- put throws when not running
- get throws when not running
- resolveLink throws when not running
- resolvePath throws when not running
- executeSelector throws when not running
- put with schema
- put throws when schema not found
- put throws when schema validation fails
- resolveLink
- resolveLink with empty path returns node
- resolveLink throws on segment resolution failure
- resolvePath
- resolvePath with unsupported namespace throws
- executeSelector
- executeSelector with all selector returns results
- executeSelector with none selector returns empty
- getStatus
- getStatus returns handler status
- getStatus returns not running when stopped
- resolveLink edge cases
- resolveLink with nested path segments
- resolveLink throws for invalid CID format
- resolvePath edge cases
- resolvePath with empty path after CID
- resolvePath with IPNS namespace
- executeSelector edge cases
- executeSelector with matcher selector
- executeSelector with recursive selector
- executeSelector throws for block not found
- registerSchema
- registerSchema adds schema to registry
- registerSchema replaces existing schema
- put with unknown schema type throws
- put edge cases
- put with empty data
- put with large data
- executeSelector edge cases
- executeSelector with null selector throws
- executeSelector with recursive selector with maxDepth 0
- lifecycle edge cases
- start when already started is idempotent
- stop when not started is safe
- start after stop restarts handler
- get throws when not started
- put throws when not started
- schema validation edge cases
- put with schema validation failure throws
- put with schema that throws during validation
- resolveLink with different data types
- resolveLink with nested links
- resolvePath with various formats
- resolvePath with CID only
- executeSelector with different selectors
- executeSelector with maxDepth limit
- getStatus with different states
- getStatus includes codec information
- put with different codecs
- put with dag-cbor codec
- put with dag-json codec
- put with raw codec
- resolveLink with special characters
- resolveLink with empty path returns root
- executeSelector with complex selectors
- executeSelector with none selector returns empty
- put with map data
- put with map data using dag-cbor
- put with nested map data
- lifecycle with concurrent operations
- concurrent put operations
- concurrent get operations
- concurrent resolveLink operations
- put with list data
- put with list of integers
- put with list of strings
- executeSelector with recursive depth
- executeSelector with maxDepth 0 returns only root
- getStatus includes running state
- getStatus includes cache information

## `test/core/ipfs_node/ipld_handler_coverage_test.mocks.dart`


## `test/core/ipfs_node/ipld_handler_expanded_test.dart`

- IPLDHandler Expanded
- getStatus returns supported codecs
- put with BigInt handles large numbers
- registerSchema and validation
- resolveLink with nested map
- executeSelector with matcher
- executeSelector with explore/recursive
- resolveLink with list index
- matchesValue advanced criteria
- unwrapIPLDNode exhaustive
- resolvePath with invalid namespace throws IPLDPathError
- resolveLink with empty path returns node
- resolveLink with invalid segment throws IPLDResolutionError
- put when not running throws ComponentError
- get when not running throws ComponentError
- resolveLink when not running throws ComponentError
- executeSelector when not running throws ComponentError
- resolvePath when not running throws ComponentError

## `test/core/ipfs_node/ipld_handler_expanded_test.mocks.dart`


## `test/core/ipfs_node/ipld_handler_final_test.dart`

- IPLDHandler Final Coverage
- put/get with dag-json
- BigInt negative values encoding/decoding
- executeSelector with SelectorType.union
- executeSelector with SelectorType.intersection
- matchesValue with \$mod and \$elemMatch
- matchesValue \$type exhaustive
- resolvePath with ipld namespace
- getMetadata with UnixFS mode and mtime
- _tryGetCidFromMap with Bytes multihash

## `test/core/ipfs_node/ipld_handler_test.dart`

- IPLDHandler
- Basic Operations
- put and get dag-cbor
- put and get raw
- put and get dag-json
- Path Resolution
- resolveLink through nested maps
- resolvePath with ipfs namespace
- Selectors
- executeSelector with \$gt operator
- executeSelector with \$lt operator
- executeSelector with \$regex operator
- Error Handling
- get non-existent block throws
- put with unsupported codec throws
- resolveLink with invalid path segment throws
- Link Traversal
- _tryGetCidFromMap handles string CID link
- _tryGetCidFromMap handles bytes CID link
- resolveLink through nested lists and maps
- UnixFS Support
- resolvePath through UnixFS directory
- getMetadata for UnixFS node
- Path Normalization
- resolvePath handles various prefixes

## `test/core/ipfs_node/ipld_handler_test.mocks.dart`


## `test/core/ipfs_node/lifecycle_integration_test.dart`

- Node Service Lifecycle Integration
- LifecycleManager sequences MetricsCollector and SecurityManager correctly

## `test/core/ipfs_node/lifecycle_manager_test.dart`

- LifecycleManager
- register adds service to list
- startAll starts all services in order
- startAll is idempotent
- startAll stops all services if one fails
- stopAll stops all services in reverse order
- stopAll continues if one service fails to stop
- register warns when adding service while running
- startAll and stopAll with no services
- stopAll when not running

## `test/core/ipfs_node/lifecycle_manager_test.mocks.dart`


## `test/core/ipfs_node/managers_coverage_test.dart`

- ContentManager
- addFile adds block to datastore
- addFileStream handles errors
- addDirectory handles nested directories
- get gateway fallback and internal path resolution errors
- ls handles non-directories and missing blocks
- pin errors
- unpin errors
- importCAR and exportCAR errors
- NetworkManager
- start and stop
- peerId returns offline when no handler
- connectedPeers returns empty when no handler
- resolvePeerId returns empty when no handler
- connectToPeer throws when no handler
- disconnectFromPeer handles no handler gracefully
- findProviders returns empty when no handler
- requestBlock throws when no handler
- ProtocolManager
- start and stop
- subscribe handles no handler gracefully
- unsubscribe handles no handler gracefully
- publish throws when no handler
- pubsubMessages returns empty stream when no handler
- resolveIPNS throws when no handler
- publishIPNS throws when no handler
- resolveDNSLink throws when no handler

## `test/core/ipfs_node/managers_coverage_test.mocks.dart`


## `test/core/ipfs_node/mdns_handler_test.dart`

- MDNSHandler
- start and stop
- getStatus
- already running/stopped warnings
- peer discovery works
- start error handling
- _resolvePeerInfo handles empty TXT
- _getPort fallback
- stop error handling
- _getPort with invalid port string
- _resolvePeerInfo handles SocketException
- _advertiseService error handling
- _resolvePeerInfo generic catch block
- _advertiseService error handling
- _resolvePeerInfo generic catch block

## `test/core/ipfs_node/mdns_handler_test.mocks.dart`


## `test/core/ipfs_node/network_handler_io_test.dart`

- NetworkHandler
- start and stop
- connectToPeer and disconnectFromPeer
- listConnectedPeers
- sendMessage
- receiveMessages
- handle connection event: connected
- handle connection event: disconnected
- handle message event
- sendRequest
- canConnectDirectly
- testDialback returns false when no bootstrap peers

## `test/core/ipfs_node/network_handler_io_test.mocks.dart`


## `test/core/ipfs_node/network_impl_test.dart`

- NetworkHandler IO Implementation
- Initialization and start
- Stop cancels subscriptions and closes controller
- peerConnected updates routing table
- peerDisconnected removes from routing table
- messageReceived event
- testDialback success
- testDialback failure on sendRequest
- dialback protocol handler
- canConnectDirectly
- canConnectDirectly failure
- sendMessage error handling
- receiveMessages error handling
- dhtRouter getter
- circuitRelayClient getter
- config getter
- peerID getter
- receiveMessages success

## `test/core/ipfs_node/network_impl_test.mocks.dart`


## `test/core/ipfs_node/network_manager_test.dart`

- NetworkManager
- peerId and connectedPeers delegating
- connect and disconnect delegating
- resolvePeerId delegating
- findProviders local first
- requestBlock delegating
- missing dependencies return defaults or throw
- findProviders DHT fallback
- findProviders all fail returns empty
- requestBlock handles null block from bitswap

## `test/core/ipfs_node/network_manager_test.mocks.dart`


## `test/core/ipfs_node/network_web_test.dart`

- NetworkHandler Web Implementation
- All stubs should be callable
- sendRequest throws UnimplementedError

## `test/core/ipfs_node/network_web_test.mocks.dart`


## `test/core/ipfs_node/node_handlers_test.dart`

- RoutingHandler
- start/stop delegates to ContentRouting
- findProviders delegates
- MDNSHandler
- start/stop delegates to MDnsClient
- status report
- AutoNATHandler
- start/stop
- DNSLinkHandler
- resolve uses client

## `test/core/ipfs_node/protocol_manager_test.dart`

- ProtocolManager
- subscribe/unsubscribe delegating
- publish delegating
- pubsubMessages stream
- resolveIPNS and publishIPNS delegating
- publish throws if PubSubHandler not registered
- resolveIPNS throws if DHTHandler not registered
- publishIPNS throws if DHTHandler not registered
- resolveDNSLink throws if resolution fails in both handlers

## `test/core/ipfs_node/protocol_manager_test.mocks.dart`


## `test/core/ipfs_node/pubsub_handler_test.dart`

- PubSubHandler
- start and stop
- subscribe and unsubscribe
- publish success
- onMessage delegating
- handle network event pubsub message
- resolveDNSLink fail
- stats success
- getStatus with subscriptions
- start error handling
- stop error handling
- subscribe error handling
- unsubscribe error handling
- publish error handling
- onMessage error handling
- stats error handling
- handle malformed pubsub message
- resolveDNSLink success

## `test/core/ipfs_node/pubsub_handler_test.mocks.dart`


## `test/core/ipfs_node/routing_handler_test.dart`

- RoutingHandler
- start and stop
- findProviders delegating and empty handling
- resolveDNSLink catches exceptions and hits alt path
- resolveDNSLink alternative paths
- default constructor coverage

## `test/core/ipfs_node/routing_handler_test.mocks.dart`


## `test/core/ipfs_node/routing_stack_test.dart`

- RoutingHandler
- start/stop error handling
- findProviders error handling
- resolveDNSLink coverage for exceptions
- ContentRoutingHandler
- start/stop success and error
- findProviders DHT success
- findProviders DHT empty -> Delegated success
- findProviders DHT empty -> Delegated empty
- findProviders error handling
- resolveDNSLink direct success
- resolveDNSLink direct fail -> DHT success
- resolveDNSLink all fail
- resolveDNSLink catch error
- getStatus
- DNSLinkHandler
- start/stop error handling
- resolve cache hit and expiry
- resolve with multiple resolvers
- resolve all fail
- resolve catch block
- extractCIDFromResponse formats
- resolve returns null on 200 but no CID
- resolve returns null on non-200
- getStatus

## `test/core/ipfs_node/routing_stack_test.mocks.dart`


## `test/core/ipfs_node/web_block_store_test.dart`

- WebBlockStore
- start and stop
- putBlock success
- getBlock success
- getBlock not found
- removeBlock
- hasBlock
- getAllBlocks
- getStatus returns block count and size
- getStatus returns empty when error occurs
- gc returns 0 (placeholder)
- putBlock handles errors
- removeBlock handles errors
- getAllBlocks handles errors
- getAllBlocks skips invalid CIDs

## `test/core/ipfs_node/web_block_store_test.mocks.dart`


## `test/core/ipfs_node_online_test.dart`

- IPFSNode Online Tests
- should initialize and start in online mode
- should find providers via DHT
- should resolve IPNS names
- should handle pubsub subscribe and publish
- should connect and disconnect peer
- should expose network addresses

## `test/core/ipfs_node_test.dart`

- IPFSNode Offline Tests
- should initialize and start in offline mode
- should add and retrieve file locally
- should add file from stream
- should add and list directory
- should handle pinning and unpinning
- should return null for missing content
- setGatewayMode changes node behavior
- subscribe/unsubscribe/publish are no-ops in offline mode
- connectToPeer throws in offline mode
- disconnectFromPeer is no-op in offline mode
- pubsubMessages returns empty stream in offline mode
- getHealthStatus returns comprehensive status
- resolvePeerId returns empty list in offline mode
- pinnedCids returns pinned content
- resolveIPNS throws when DHTHandler not available
- stop is idempotent
- double start throws StateError or is handled
- bandwidthIn and bandwidthOut return zero with no traffic
- bandwidthIn and bandwidthOut aggregate metrics
- dhtPeerCount returns zero when offline

## `test/core/ipfs_test.dart`

- IPFS Facade
- should start and stop successfully
- should add and get file
- should add and list directory
- should pin and unpin content
- should report stats
- should expose onNewContent stream
- peerID is exposed (offline returns 
- networking facades delegate to underlying node and surface errors
- unpin throws when CID is not pinned

## `test/core/ipld/codecs/codecs_coverage_test.dart`

- Standard Codecs
- RawCodec encode/decode
- DagCborCodec encode/decode
- DagJsonCodec encode/decode
- Advanced Codecs
- DagJoseCodec encode JWS
- DagJoseCodec decode basic
- DagJoseCodec decode with invalid format throws
- DagJoseCodec encode with empty map
- DagJoseCodec encode with string payload
- DagJoseCodec reports correct name and code

## `test/core/ipld/codecs/codecs_coverage_test.mocks.dart`


## `test/core/ipld/codecs/standard_codecs_test.dart`

- RawCodec
- reports raw name, code, and identifier
- encode returns the bytes payload
- encode rejects non-bytes nodes
- decode produces a BYTES node
- DagJsonCodec
- reports dag-json name, code, and identifier
- encode/decode round-trips a string node
- encode/decode round-trips a map node
- encode/decode round-trips a list node
- encode/decode round-trips a bool node
- encode/decode round-trips null
- encode/decode round-trips int
- encode/decode round-trips bytes
- DagPbCodec
- reports dag-pb name, code, and identifier
- encode rejects non-map nodes
- encode with valid map node
- decode produces node
- encode handles missing Data field
- encode handles missing Links field
- encode throws on invalid link format
- DagCborCodec
- reports dag-cbor name, code, and identifier
- encode produces bytes
- decode produces node
- encode/decode round-trips string
- encode/decode round-trips int
- encode/decode round-trips map
- encode/decode round-trips list
- encode/decode round-trips bool
- encode/decode round-trips bytes
- encode/decode round-trips null
- encode is deterministic/canonical for maps

## `test/core/ipld/dag_json_codec_test.dart`

- DagJsonCodec (unified IPLDCodec)
- reports the correct multicodec name and code
- encodes and decodes a simple map
- encodes and decodes a CID link
- encodes and decodes bytes

## `test/core/ipld/dag_json_handler_test.dart`

- DAGJsonHandler
- encodes and decodes NULL
- encodes and decodes BOOL
- encodes and decodes INTEGER
- encodes and decodes FLOAT
- encodes and decodes STRING
- encodes and decodes BYTES
- encodes and decodes LINK (CID)
- encodes and decodes LIST
- encodes and decodes MAP
- handles map with slash key correctly (escape mechanism or literal)

## `test/core/ipld/extensions/ipld_node_json_test.dart`

- IPLDNode JSON extension
- NULL kind serialises to null
- BOOL kind serialises to bool
- INTEGER kind serialises to int
- FLOAT kind serialises to double
- STRING kind serialises to string
- BYTES kind serialises to base64-wrapped link map
- LIST kind serialises children recursively
- MAP kind serialises into Dart map
- BIG_INT kind serialises as string of bytes

## `test/core/ipld/ipld_extras_test.dart`

- IPLDNodeJson
- toJson simple
- IPLDSelector
- factories create correct types
- serialization round trip

## `test/core/ipld/ipld_path_test.dart`

- IPLDPathHandler
- parsePath
- parses valid IPFS path with just CID
- parses valid IPFS path with subpath
- parses valid IPLD path
- parses valid IPNS path
- throws IPLDPathError on missing leading slash
- throws IPLDPathError on invalid namespace
- throws IPLDPathError on invalid CID
- throws IPLDPathError on empty path parts
- normalizePath
- removes duplicate slashes
- removes trailing slash
- preserves root slash
- handles already clean path

## `test/core/ipld/jose_cose_handler_test.dart`

- JoseCoseHandler
- encodeJWS
- throws on non-MAP node
- encodes MAP node successfully
- encodeJWE
- throws on non-MAP node
- encodes MAP node successfully (with mock result path check)
- encodeCOSE
- throws on non-MAP node
- encodes MAP node successfully
- decodeJWS
- throws on non-MAP node
- decodes a valid JWS roundtrip
- decodeJWE
- throws on non-MAP node
- decodeJWE handles exception path on invalid data
- decodeCOSE
- throws on non-MAP node
- successful COSE roundtrip
- throws IPLDDecodingError on invalid signature
- BigInt conversion
- throws on null value

## `test/core/ipld/path/ipld_path_handler_test.dart`

- IPLDPathHandler
- parsePath
- throws if path does not start with /
- throws if path is empty parts
- throws if namespace invalid
- throws if CID invalid
- parses simple path
- parses path with segments
- parses subpaths with multiple slashes
- normalizePath
- removes duplicate slashes
- removes trailing slash
- keeps root slash if only slash
- handles mixed

## `test/core/ipld/schema/ipld_schema_coverage_test.dart`

- IPLDSchema Coverage Tests
- validate with type reference
- validate with union type
- validate with struct type and required fields
- validate with struct type missing required field returns false
- validate with integer constraint min/max
- validate with integer constraint below min returns false
- validate with integer constraint above max returns false
- validate with string constraint pattern
- validate with string constraint minLength
- validate with string constraint minLength violation returns false
- validate with string constraint maxLength
- validate with string constraint maxLength violation returns false
- validate with bytes constraint minLength
- validate with bytes constraint maxLength
- validate with struct type and optional fields
- validate with struct type and strict validation
- validate throws for unknown type
- validate throws for missing kind in schema
- validate throws for unknown kind

## `test/core/ipld/selector_test.dart`

- IPLD Selectors
- SelectorType.all should return the node and traverse links
- SelectorType.none should return nothing and stop traversal
- SelectorType.matcher should match criteria
- SelectorType.explore should follow path and verify subselector

## `test/core/ipld/selectors/ipld_selector_coverage_test.dart`

- IPLDSelector Coverage Tests
- toBytes encoding
- toBytes encodes all selector type
- toBytes encodes none selector type
- toBytes encodes explore selector with path
- toBytes encodes matcher selector with criteria
- toBytes encodes recursive selector with maxDepth
- toBytes encodes recursive selector with stopAtLink
- toBytes encodes union selector
- toBytes encodes intersection selector
- toBytes encodes selector with nested subselectors
- fromBytesAsync decoding
- fromBytesAsync decodes all selector
- fromBytesAsync decodes none selector
- fromBytesAsync decodes explore selector
- fromBytesAsync decodes matcher selector with criteria
- fromBytesAsync decodes recursive selector
- fromBytesAsync decodes union selector
- fromBytesAsync decodes intersection selector
- fromNode decoding
- fromNode decodes all selector
- fromNode decodes none selector
- fromNode decodes selector with criteria
- fromNode decodes selector with maxDepth
- fromNode decodes selector with fieldPath
- fromNode decodes selector with stopAtLink
- round-trip encoding/decoding
- round-trip all selector
- round-trip complex nested selector

## `test/core/ipld/selectors/ipld_selectors_test.dart`

- Selector parsing
- parses matcher
- parses exploreAll
- parses exploreFields
- parses exploreIndex
- parses exploreRange
- parses exploreRecursive
- parses exploreUnion
- parses exploreInterpretAs
- parses exploreConditional
- rejects unknown selector keys
- rejects missing required fields
- rejects malformed field types
- rejects multi-key selector maps
- Selector serialization
- round-trips through DAG-CBOR
- round-trips through DAG-JSON
- decodeSelectorBytes detects DAG-JSON
- decodeSelectorBytes detects DAG-CBOR
- Selector execution
- matcher returns the root node
- exploreAll traverses map children and follows links
- exploreFields traverses only named fields
- exploreIndex and exploreRange traverse list indices
- exploreUnion applies all members
- exploreRecursive respects depth limit
- exploreConditional applies next only when condition matches
- exploreInterpretAs passes through for recognized ADL
- exploreInterpretAs rejects unknown ADL
- includePath escapes / and ~ per RFC 6901
- Budget enforcement
- maxDepth stops traversal
- maxNodes stops traversal
- Visited set / diamond DAG
- does not revisit a shared descendant

## `test/core/ipld_handler_test.dart`

- IPLDHandler
- should put and get DAG-CBOR data
- should handle various types in _toIPLDNode
- should put and get Raw data
- should put and get DAG-JSON data with links
- should resolve links through maps and lists
- should resolve paths with namespaces
- should get metadata
- should execute selectors
- should handle matcher with criteria operators
- should throw error for unsupported codec
- should throw IPLDResolutionError for invalid path segment
- should throw IPLDPathError for invalid namespace
- should handle BigInt in _toIPLDNode
- getStatus should return supported codecs
- should handle CID in _toIPLDNode
- should throw ComponentError when not running
- should throw ComponentError for get when not running
- should throw ComponentError for resolveLink when not running
- should throw ComponentError for executeSelector when not running
- should throw ComponentError for resolvePath when not running
- should throw IPLDSchemaError for unknown schema
- executeSelector with explore selector
- executeSelector with recursive selector
- executeSelector with union selector
- executeSelector with intersection selector
- executeSelector with none selector
- matcher with exists operator
- matcher with type operator
- matcher with mod operator
- matcher with all operator
- matcher with size operator
- matcher with elemMatch operator
- resolveLink with empty path returns node
- resolveLink handles list index out of bounds
- resolvePath with invalid CID throws IPLDPathError
- getMetadata for non-UnixFS node
- start when already running is idempotent
- stop when not running is idempotent
- registerCodec adds custom codec
- registerSchema adds custom schema
- put with dag-pb codec
- get with non-existent CID returns empty node
- resolveLink with list path
- resolveLink with nested map path
- resolveLink with link in list
- resolveLink with invalid list index throws error
- resolveLink with non-existent map key throws error
- resolveLink traverses through multiple links
- executeSelector with empty results
- put with empty data
- put with large data
- getMetadata returns correct size
- getStatus returns codec count
- resolvePath with trailing slash
- resolvePath with only CID
- executeSelector with recursive selector and maxDepth
- executeSelector with recursive selector and stopAtLink
- put with null value
- put with boolean values
- put with empty map
- put with empty list
- resolveLink with complex nested structure
- executeSelector with complex matcher criteria
- get with dag-json codec
- resolveLink handles circular references gracefully

## `test/core/ipld_schema_test.dart`

- IPLDSchema
- validates valid struct
- validates struct missing required field
- validates int constraint
- validates string constraint (minLength)
- throws on unknown type
- union accepts any matching representation
- basic-type schemas reject mismatched kinds
- string schemas honour pattern and maxLength
- throws when schema kind is unknown

## `test/core/messages/message_factory_test.dart`

- MessageFactory
- createBaseMessage creates message with all fields
- createBaseMessage sets timestamp
- createBaseMessage handles empty payload
- createBaseMessage handles different message types

## `test/core/metrics/metrics_collector_test.dart`

- MetricsCollector
- should initialize and start/stop
- should respect enabled flag in config
- recordMessageSent records message and byte counters
- recordMessageReceived records message and byte counters
- totalBytesSent aggregates bytes across all protocols
- totalBytesReceived aggregates bytes across all protocols
- recordLatency records observations and average latency
- recordPeerConnected and recordPeerDisconnected update gauge
- recordRoutingTableSize and recordBlockstoreStats update gauges
- recordGatewayRequest records counter and histogram
- recordRpcRequest records counter and histogram
- recordDhtProvide records success and failure labels
- recordReprovide records runs and duration
- recordSecurityEvent records type labels
- getPrometheusMetrics returns Prometheus text format
- reset clears all metrics
- metricsStream emits records
- updateConnectionMetrics updates legacy getters
- recordProtocolMetrics emits stream events without crashing
- recordError logs without crashing

## `test/core/metrics_test.dart`

- MetricsCollector
- should initialize and start/stop
- should record protocol metrics
- should update and retrieve connection metrics
- should calculate average latency correctly
- should record errors
- should handle disabled metrics gracefully
- should expose Prometheus metrics for P2P traffic
- should expose Prometheus metrics for node state

## `test/core/mfs_test.dart`

- MFSManager
- mkdir creates directory
- mkdir recursive
- write and read file
- stat returns correct info
- rm removes file/directory
- cp copies content
- mv moves content
- flush returns root CID
- chcid changes CID version
- write offset/truncate
- write with offset patches existing file
- truncate true zeros leading bytes and writes at offset
- truncate false requires existing file
- count limits bytes written
- negative offset or count throws ArgumentError
- stat honors cid-base

## `test/core/peer/peer_record_test.dart`

- PeerRecordPb
- encode/decode roundtrip preserves all fields
- encode/decode with empty addresses
- encode/decode with large seq and timestamp values
- toString contains useful info
- PublicKeyPb
- encode/decode roundtrip for Ed25519
- KeyType.fromValue throws for unknown
- KeyType enum values are correct
- EnvelopePb
- encode/decode roundtrip
- Varint encoding
- encodeVarint for small values
- encodeVarint for multi-byte values
- decodeVarint roundtrip
- decodeVarint throws on truncated
- PeerRecordSigner
- create produces a valid signed peer record
- seq increments on each create
- envelope bytes can be verified
- verifyPeerId matches
- tampered signature fails verification
- tampered payload fails verification
- wrong key type fails verification
- wrong payload type fails verification
- malformed envelope bytes return null
- buildSigningBuffer produces correct format
- SignedPeerRecord
- toString contains useful info
- envelopeBytes matches envelope.encode()

## `test/core/peering/peering_service_test.dart`

- PeeringConfig
- toJson/fromJson roundtrip
- fromJson uses defaults
- PeeringService
- start and stop when disabled
- start idempotency
- stop idempotency
- start with peer already connected emits connected event
- connects to a disconnected peer and emits event later
- addPeer extracts peerId and connects
- addPeer ignores invalid multiaddr
- addPeer ignores duplicate peer
- removePeer removes and reports missing
- isPeerConnected reflects state
- status is consistent after stop
- emits disconnected event when peer goes offline

## `test/core/plugins/plugin_security_test.dart`

- PluginHost signed plugin trust
- signed plugin loads when trusted
- signed plugin fails when key is not trusted
- PluginHost archive checksum verification
- tampered plugin archive fails after valid signature
- PluginHost unsigned plugin policy
- unsigned plugin fails by default
- unsigned plugin loads with allowUnsigned=true and logs a warning
- PluginHost capability enforcement
- capability violation throws CapabilityException and disables the plugin
- granted capability allows metric emission
- CapabilityRegistry
- unknown capabilities are rejected
- require throws CapabilityException for ungranted capability

## `test/core/responses/block_operation_response_test.dart`

- BlockOperationResponse
- success and failure factories
- fromProto AddBlockResponse
- fromProto GetBlockResponse success
- fromProto GetBlockResponse not found
- fromProto unsupported type

## `test/core/responses/block_response_factory_test.dart`

- BlockResponseFactory
- Success Responses
- successGet creates valid GetBlockResponse
- successAdd creates valid AddBlockResponse
- successRemove creates valid RemoveBlockResponse
- Failure Responses
- notFound creates GetBlockResponse with found=false
- failureAdd creates AddBlockResponse with success=false
- failureRemove creates RemoveBlockResponse with success=false
- Edge Cases
- handles empty message strings
- handles very long error messages
- handles special characters in messages
- Response Consistency
- multiple successGet calls create independent responses
- responses are properly typed

## `test/core/responses/block_response_handler_test.dart`

- BlockResponseHandler
- success and failure
- found and notFound
- removed and notRemoved

## `test/core/responses/block_responses_test.dart`

- BlockAddResponse
- toProto and fromProto
- toJson returns correct map
- toString returns formatted string
- BlockGetResponse
- toProto and fromProto
- toJson returns correct map
- toJson with null block
- BlockRemoveResponse
- toProto and fromProto
- toJson returns correct map
- toString returns formatted string

## `test/core/responses/response_handler_test.dart`

- ResponseHandler
- toAddBlockResponse
- toGetBlockResponse
- toRemoveBlockResponse
- fromProtoResponse GetBlockResponse

## `test/core/responses_test.dart`

- BlockResponseHandler
- success returns successful AddBlockResponse
- failure returns failed AddBlockResponse
- found returns valid GetBlockResponse
- notFound returns empty GetBlockResponse
- ResponseHandler
- toAddBlockResponse
- toGetBlockResponse
- fromProtoResponse handles AddBlockResponse
- BlockResponses Wrapper Classes
- BlockAddResponse
- BlockGetResponse

## `test/core/security/content_blocking_test.dart`

- DenylistService
- is default-off and has no effect when disabled
- blocks CID strings from plain text lists
- matches CID against base32 multihash entry
- parses BadBits compact format with comments and metadata
- skips lines longer than 4096 characters and counts warnings
- refreshes atomically and keeps previous list on failure
- loads from local file path
- increments refreshErrors on failed URL load
- audit log records hits with FIFO eviction
- log action records event and does not block
- persists loaded list and reloads from storage on URL failure
- start and stop schedule and cancel refresh timer
- Gateway denylist integration
- returns 451 for blocked CID with default block action
- returns 200 and logs for blocked CID with log action
- RPC denylist integration
- handleCat returns 451 for blocked CID
- handleBlockGet returns 451 for blocked CID
- handleDagGet returns 451 for blocked CID
- handleDhtProvide returns 451 for blocked CID

## `test/core/security/security_manager_test.dart`

- SecurityManager
- should initialize with locked keystore
- should unlock keystore with password
- should lock keystore
- should enforce rate limiting
- should track auth attempts
- should generate secure key when unlocked
- getSecureKey - success
- should throw error when accessing keys while locked
- migrateKeysFromPlaintext - empty
- migrateKeysFromPlaintext - locked error
- TLS initialization error - missing paths
- TLS initialization error - missing cert
- TLS initialization error - cert exists but key missing
- Key rotation execution
- getPrivateKey - key not found fallback
- getPrivateKey fallback - secure key
- getPrivateKey fallback - locked warning
- getStatus reporting
- unlockKeystore throws on empty password
- getSecureKey throws on empty key name
- generateSecureKey throws on empty key name
- generateSecureKey accepts label parameter
- start and stop lifecycle
- hasSecureKey returns true even when locked
- getSecurePublicKey returns key even when locked
- getSecurePublicKey returns null for non-existent key
- shouldRateLimit returns false when rate limiting disabled
- trackAuthAttempt returns true for successful auth
- trackAuthAttempt with maxAuthAttempts disabled
- migrateKeysFromPlaintext with no keys returns 0
- getStatus includes all expected fields
- unlockKeystore with same password twice is idempotent
- generateSecureKey with different names creates separate keys
- lockKeystore when already locked does not throw
- stop when not started does not throw
- start when already started does not throw

## `test/core/security/security_manager_web_test.dart`

- SecurityManagerWeb
- should start locked
- should unlock with password
- should generate and retrieve secure keys
- should lock and clear keys
- unlockKeystore throws on empty password
- generateSecureKey throws on empty key name
- getSecureKey throws on empty key name
- generateSecureKey accepts label parameter
- start method is a no-op
- stop method locks keystore
- should rate limit requests
- should respect enableRateLimiting flag
- should track auth attempts
- should return correct status

## `test/core/service_container_test.dart`

- ServiceContainer
- should register and retrieve singleton
- should register and retrieve factory
- should throw if service not registered
- should distinguish between different types

## `test/core/services/health_check_service_test.dart`

- HealthCheckService
- checkHealth returns healthy when everything is fine
- checkHealth returns starting when node is not running
- checkHealth returns degraded when errors are present

## `test/core/services/health_check_service_test.mocks.dart`


## `test/core/storage/datastore_test.dart`

- Key
- cleaning
- child and parent
- equality and toString
- DatastoreError
- toString
- Query
- instantiation

## `test/core/storage/flat_file_datastore_test.dart`

- FlatFileDatastore
- init
- creates directory if not exists
- does not fail if directory already exists
- put and get
- stores and retrieves data
- overwrites existing data
- returns null for non-existent key
- has
- returns true for existing key
- returns false for non-existent key
- delete
- deletes existing key
- does not fail when deleting non-existent key
- query
- returns all entries with empty query
- filters by prefix
- keysOnly query returns null values
- close
- close is a no-op

## `test/core/storage/memory_datastore_test.dart`

- MemoryDatastore
- put and get
- delete
- query with prefix
- query with limit and offset
- close
- init
- query with keysOnly returns entries without values
- query returns empty stream for no matches
- get returns null for non-existent key
- has returns false for non-existent key
- query with filters
- query with orders

## `test/core/types/peer_id_test.dart`

- PeerId base36
- toBase36 returns multibase-prefixed string
- fromBase36 round-trips
- fromBase36 accepts bare string without k prefix
- fromBase36 rejects invalid characters
- fromPublicKey Ed25519 derives deterministic PeerId
- fromPublicKey requires Ed25519 type and 32-byte key
- PeerId PoW
- verifyPoW should accept PeerId with enough leading zeros
- verifyPoW should reject PeerId with insufficient leading zeros
- difficulty 0 should always pass

## `test/core/types/peer_types_test.dart`

- IPFSPeer
- toProto and fromProto
- toKadPeer and fromKadPeer

## `test/core/unixfs/unixfs_builder_test.dart`

- UnixFSBuilder
- should chunk stream and produce blocks
- should handle small stream efficiently

## `test/core/unixfs/unixfs_hamt_integration_test.dart`

- UnixFS HAMT sharding integration
- createDirectory produces plain directory for small entry count
- createDirectory auto-shards when entry count exceeds threshold
- sharded directory uses CIDv1 dag-pb
- buildAutoSharded falls back to plain directory when below threshold
- round-trip: build sharded directory -> resolve all entries
- HAMT builder produces consistent CIDs for same entries
- addChildToDirectory supports auto-sharding
- UnixFSHAMTBuilder with fanout 256 produces valid shard

## `test/core/unixfs/unixfs_test.dart`

- UnixFS File Sharding
- should shard large file into multiple blocks
- should construct directory DAG
- UnixFS Directory Builder
- createDirectory computes correct cumulative Tsize
- computeTsize for nested directory
- computeTsize detects DAG cycles
- addChildToDirectory replaces existing entry
- UnixFS Path Resolver
- resolves a simple path
- resolves nested path
- rejects . segments
- rejects .. segments
- ignores empty segments from consecutive slashes
- throws on missing link
- detects DAG cycle during resolution
- UnixFS Symlinks
- creates a symlink node
- resolves a relative symlink
- resolves an absolute symlink
- resolves symlink target containing ..
- rejects symlink target that escapes root
- detects symlink cycle
- UnixFS HAMT Sharded Directory
- builds a HAMT shard node
- resolves paths through HAMT shards
- throws on missing HAMT path
- murmur3X64Hash64 matches reference vectors
- HAMT root CID matches spec reference for two entries
- HAMT root CID matches spec reference for 257 entries

## `test/core/utils/utils_test.dart`

- Base58
- encode encodes bytes correctly
- decode decodes string correctly
- encode/decode cycle preserves data
- handles empty input
- EncodingUtils
- toBase58 adds z prefix
- fromBase58 handles z prefix
- fromBase58 throws on invalid prefix
- isValidCIDBytes validates CIDv0
- isValidCIDBytes fails invalid length CIDv0
- supportedCodecs returns list
- getCodecFromCode returns correct strings

