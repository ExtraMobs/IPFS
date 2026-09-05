---
test-group: protocols
generated: 2026-09-02T08:21:38.734373
---

# `test/protocols/`

## `test/protocols/autonat/autonat_protocol_test.dart`

- DialRequest
- encode/decode roundtrip
- decode empty message yields empty addrs
- decode skips unknown fields
- DialResponse
- encode/decode roundtrip with status text
- decode without status defaults to dialError
- decode skips unknown fields
- AutoNATService
- initial status is unknown
- updateObservedAddrs stores addresses
- performDialback returns unknown with no observed addresses
- performDialback returns unknown on exception
- performDialback updates status to public on ok
- performDialback updates status to private on dialError
- performDialback leaves status unchanged on dialRefused
- performDialback is rate limited within one minute
- resetStatus returns to unknown
- AutoNATServer
- start and stop register/unregister handler
- handle request with empty addrs returns dialError
- handle successful dialback returns ok
- handle failed dialback returns dialError
- rate limits concurrent requests
- handle malformed request returns dialError

## `test/protocols/bitswap/bitswap_handler_coverage_test.dart`

- BitswapHandler
- start/stop lifecycle
- wantBlock requests block and completes
- discovers and connects a provider before sending the want
- handlePacket processes incoming wantlist
- handlePacket processes incoming HAVE wantlist
- wantBlock timeout
- handleBlocks rejects invalid blocks
- want multiple blocks
- handleMessage with blocks updates ledger
- handleBlockPresences logging
- handleWantRequest broadcasts
- stop clears pending blocks with error
- handleWantlist rejects excessive entries
- want throws StateError if no peers
- handleWantlist sends DONT_HAVE if requested
- start when already running returns early
- stop when not running returns early
- start error handling
- stop error handling
- want when not running throws StateError
- want with duplicate CID
- handleWantRequest error handling
- wantBlock when not running throws StateError
- wantBlock error handling returns null
- handleWantlist with empty wantlist

## `test/protocols/bitswap/bitswap_handler_coverage_test.mocks.dart`


## `test/protocols/bitswap/bitswap_handler_test.dart`

- Wantlist
- add and contains
- remove removes entry
- getEntry returns correct entry
- length reflects entries
- clear removes all entries
- rejects negative priority
- BitLedger
- tracks sent bytes
- tracks received bytes
- calculates debt correctly
- rejects negative bytes
- stores and retrieves block data
- throws on missing block data
- LedgerManager
- getLedger creates new ledger if missing
- getLedger returns same instance for same peer
- clearLedger removes specific peer
- clearAllLedgers removes all
- getBandwidthStats aggregates all ledgers
- printLedgers iterates without throwing
- BitLedger.toString and receivedMessage
- toString includes ledger numbers
- Bitswap Message
- creates empty message
- addWantlistEntry adds to wantlist
- addBlockPresence adds presence info
- serialization produces valid bytes

## `test/protocols/bitswap/bitswap_http_fallback_test.dart`

- BitswapHandler HTTP fallback
- typed getBlock rejects requests while stopped
- typed getBlock returns the go-block-format surface over P2P
- returns cached block without P2P or HTTP
- uses P2P when available and skips HTTP
- falls back to HTTP gateway after P2P failure
- discards HTTP block that fails CID verification
- retries next gateway after first fails
- caches verified HTTP block and returns it on next request
- verifyHttpBlocks false skips verification and stores bad block
- rejects private gateway unless allowed
- rejects HTTP block larger than maxHttpBlockSize
- does not use HTTP fallback when disabled
- getBlock useHttpFallback=false skips HTTP after P2P failure

## `test/protocols/bitswap/bitswap_session_test.dart`

- BitswapSession
- creates session with unique id
- addInterest and isInterestedIn
- removeInterest removes CID
- addPeer and removePeer
- recordHave tracks provider for CID
- recordDontHave removes provider for CID
- markPeerHasAll and haveAllPeers
- unmarkPeerHasAll removes from have-all set
- targetPeersForWant returns have-all peers first
- targetPeersForWant returns known providers
- targetPeersForWant falls back to all session peers
- shouldBroadcast returns true when few session peers
- shouldBroadcast returns false when enough peers and provider known
- shouldBroadcast returns true when no provider known
- updatePeerLatency and getPeerLatency
- peersByLatency sorts by latency ascending
- close clears all state
- addInterest does nothing after close
- BitswapSessionManager
- createSession returns session with unique id
- getSession returns session by id
- getSession returns null for unknown id
- closeSession removes session
- activeSessions returns only active sessions
- activeSessionCount returns count of active sessions
- start and stop
- sessionsInterestedIn returns sessions interested in CID
- recordHave updates all interested sessions
- recordDontHave updates all interested sessions
- markPeerHasAll updates session
- stop closes all sessions

## `test/protocols/bitswap/ledger_test.dart`

- BitLedger
- constructor initializes with peerId
- addSentBytes updates sentBytes
- addSentBytes throws on negative bytes
- addReceivedBytes updates receivedBytes
- addReceivedBytes throws on negative bytes
- getDebt calculates difference
- storeBlockData and getBlockData
- getBlockData throws for non-existent block
- hasBlock returns false for non-existent block
- toString returns formatted string
- receivedMessage updates received bytes from blocks
- LedgerManager
- getLedger creates new ledger if not exists
- getLedger returns existing ledger
- clearLedger removes specific ledger
- clearAllLedgers removes all ledgers
- getBandwidthStats returns total stats
- getBandwidthStats returns zeros for no ledgers

## `test/protocols/bitswap/message_test.dart`

- Message
- constructor creates empty message
- addBlock and getBlocks
- addWantlistEntry and getWantlist
- addWantlistEntry with all parameters
- addBlockPresence and getBlockPresences
- pendingBytes can be set
- from can be set
- preserves Bitswap 1.2 want, payload, and presence fields
- uses the four-varint CIDv0 payload prefix and accepts legacy blocks
- matches the upstream block-presence CID protobuf vector
- merges repeated want entries like Boxo
- rejects invalid outbound CIDs instead of silently omitting them
- rejects CIDs with trailing bytes like cid.Cast
- follows Go identity-prefix length semantics
- rejects an invalid payload prefix and oversized inbound message
- a 2 MiB block fits the 4 MiB libp2p message limit
- toNet matches Boxo empty-message framing byte for byte
- fromNet decodes one frame and reports payload bytes read
- fromNet rejects truncation, overflow, and oversized payloads
- fromNetStream reads short chunks and preserves Boxo framing
- WantlistEntry
- constructor with defaults
- constructor with all parameters
- Wantlist
- addEntry and contains
- removeEntry
- addEntry updates existing entry
- BlockPresence
- constructor
- constructor with dontHave type
- WantType enum
- enum values exist
- BlockPresenceType enum
- enum values exist

## `test/protocols/bitswap/wantlist_test.dart`

- Wantlist
- add and remove entries
- add with negative priority throws ArgumentError
- getEntry returns entry for CID
- getEntry returns null for non-existent CID
- entries returns unmodifiable map
- clear removes all entries
- toString returns formatted string
- add with custom wantType and sendDontHave

## `test/protocols/connection_manager/cuttlefish_connection_manager_test.dart`

- CuttlefishConnectionManager
- starts and stops
- addConnection increases connection count
- removeConnection decreases connection count
- hasConnection returns correct value
- getConnection returns tagged connection
- tag adds tag and adjusts priority
- tag on unknown connection does nothing
- untag removes tag and adjusts priority
- protect prevents connection from being pruned
- unprotect allows connection to be pruned
- pruning respects priority - low priority pruned first
- grace period protects newly connected peers
- pruneNow forces immediate pruning
- connectionsByTag returns connections with given tag
- prunedConnections stream emits pruned peer IDs
- getStats returns connection summary
- default config has highWater 128 and lowWater 64
- connections list returns all connections
- stop clears all connections
- TaggedConnection
- creates with default values
- protect and unprotect
- addTag and removeTag

## `test/protocols/dcutr/dcutr_handler_test.dart`

- DCUtRHandler offline mode
- isAvailable is false before start
- start and stop lifecycle
- start and stop idempotency
- directConnect returns false when not running
- directConnect returns false without hole punch service
- directConnect returns false for invalid peer id

## `test/protocols/dht/connection_statistics_test.dart`

- ConnectionStatistics
- starts with zero values
- incrementTotalConnections increases count
- incrementDisconnections updates count and time
- updateConnectionDuration calculates simple moving average
- updateConnectionDuration maintains sliding window
- increments data transfer counters
- updateLatency uses exponential moving average
- updateFromPeerInfo updates status

## `test/protocols/dht/delegate_dht_handler_test.dart`

- DelegateDHTHandler
- start and stop
- findProviders returns providers from JSON stream
- getValue returns value from Type 5 response
- getValue throws on non-200 or missing value
- putValue and provide send POST requests
- findPeer currently returns empty list
- error handling
- handleRoutingTableUpdate and handleProvideRequest do nothing
- non-200 responses and other errors in DelegateDHTHandler

## `test/protocols/dht/dht_client_coverage_test.dart`

- DHTClient
- initialization
- getRoutingKey
- findProviders sends request to closest peers
- storeValueToPeer success
- listsEqual
- checkInitialized throws if not initialized
- findProviders iterative success
- getAllStoredKeys success
- updateKeyRepublishTime success
- handlePacket PING
- handlePacket FIND_NODE
- addProvider success
- checkValueOnPeer success
- storeValue success
- getValue success
- findPeer success
- start and stop success
- findProviders with empty routing table returns empty
- getValue with timeout returns null
- findPeer with no closer peers returns null
- handlePacket with unknown message type ignores
- getAllStoredKeys with empty storage returns empty
- resolveDNSLink with valid DNSLink returns CID
- checkValueOnPeer with no record returns false
- storeValue with no peers returns false
- addProvider with no peers does nothing
- updateKeyRepublishTime with storage error throws

## `test/protocols/dht/dht_client_coverage_test.mocks.dart`


## `test/protocols/dht/dht_client_test.dart`

- DHTClient integration spec
- stop cancels routing-table maintenance timers
- iterative queries use raw Kademlia request/response
- findProviders returns validated provider records
- findProvidersAsync preserves providers without multiaddrs
- findProvidersAsync applies count
- count zero exhausts and suppresses identical providers
- findProvidersAsync emits an address upgrade
- legacy provider wrapper waits for a dialable upgrade
- cancelling findProvidersAsync stops before the next query
- timeout drops a late fallback RPC response
- timed out fallback RPC leaves no cleanup timer
- stop cancels a pending fallback RPC
- findProviders expands iteratively via closer peers
- provider lookup never exceeds alpha concurrent queries
- beta termination follows up an unqueried top-k peer
- findPeer iterates until target is discovered
- addProvider encodes addresses as multiaddr bytes
- ADD_PROVIDER rejects a provider different from the sender
- ADD_PROVIDER accepts the sender with a valid address
- ADD_PROVIDER rejects an invalid address
- reprovide enumerates stored keys and records metrics
- addProvider sends to closest peers in batches

## `test/protocols/dht/dht_handler_coverage_test.dart`

- DHTHandler
- start/stop lifecycle
- findProviders delegates to client
- putValue/getValue operations
- resolveIPNS via DHT success
- resolveIPNS via HTTP fallback
- resolveIPNS fails all methods
- publishIPNS success
- publishIPNS with existing record increments sequence
- provide delegates to client
- findPeer delegates to client
- handleRoutingTableUpdate delegates to client
- handleProvideRequest with rate limiting
- handleProvideRequest max providers check
- getStatus returns correct info
- resolveDNSLink success
- resolveDNSLink DHT success but invalid CID format
- isValidCID validates CID format
- isValidPeerID validates peer ID format
- extractCIDFromResponse extracts CID from HTML
- extractCIDFromResponse returns null when no CID found
- router getter returns router
- storage getter returns storage
- getValue throws when storage returns null
- putValue handles storage errors
- findProviders handles client errors
- provide handles client errors
- findPeer handles client errors
- handleRoutingTableUpdate throws on client errors
- publishIPNS handles keystore errors gracefully
- resolveDNSLink handles storage errors
- resolveDNSLink with HTTP fallback when storage fails
- resolveIPNS with HTTP fallback when storage fails
- resolveIPNS with empty storage value returns empty string
- extractCIDFromResponse handles malformed HTML
- isValidCID handles empty string
- isValidPeerID handles empty string
- getStatus with inactive client
- handleProvideRequest with same provider is not idempotent

## `test/protocols/dht/dht_handler_coverage_test.mocks.dart`


## `test/protocols/dht/dht_handler_lifecycle_test.dart`

- stop closes the internally owned datastore

## `test/protocols/dht/dht_handler_test.dart`

- DHTHandler provider record validation
- valid provider record accepted
- invalid provider record rejected when address is unparseable
- provider record with empty peer id rejected
- provider record with expired ttl rejected
- handleProvideRequest rejects invalid provider records
- handleProvideRequest accepts valid provider records

## `test/protocols/dht/dht_protocol_handler_test.dart`

- DHTProtocolHandler
- responds to PING with PING
- rate limiter drops messages when queue is full
- rate limiter releases permit after handling

## `test/protocols/dht/dht_routing_integration_test.dart`

- DHT Routing Integration - Distance-based Peer Selection
- selects closest peers by XOR distance
- handles K closest peers selection
- distance metric is consistent across multiple calls
- peer selection is deterministic
- handles edge case of identical peer IDs

## `test/protocols/dht/dht_routing_test.dart`

- DHT Routing Logic
- getRoutingKey derives correct SHA-256 hash of Multihash
- getRoutingKey handles raw string fallback

## `test/protocols/dht/dht_validation_patterns_test.dart`

- DHT Validation Patterns
- Alphanumeric Pattern (CID/PeerID validation)
- matches valid alphanumeric strings
- rejects empty strings
- rejects strings with special characters
- rejects strings with only whitespace
- Qm CID Extraction Pattern
- extracts valid Qm-style CID from text
- extracts CID from JSON response
- returns null when no CID present
- extracts first CID when multiple present
- Integration with Actual DHT Patterns
- validates typical CID formats work with alphanumeric pattern
- validates typical PeerID formats work with alphanumeric pattern
- rejects invalid CID/PeerID formats

## `test/protocols/dht/interface_dht_handler_test.dart`

- Key
- constructor creates key from bytes
- fromString creates key from string
- fromBytes creates key from bytes
- toString returns base58 encoded string
- Value
- constructor creates value from bytes
- fromString creates value from string
- fromBytes creates value from bytes
- toString returns decoded string

## `test/protocols/dht/kademlia_bucket_management_test.dart`

- BucketManagement Extension Tests
- getBucketIndex returns correct indices for various distances
- canSplitBucket logic
- canMergeBuckets logic
- splitBucket moves nodes correctly
- mergeBuckets combines nodes
- findLeastRecentlySeenNode
- calculateConnectionStabilityScore with various states
- handleBucketFullness - split path
- handleBucketFullness - replacement path

## `test/protocols/dht/kademlia_routing_adapter_test.dart`

- KademliaRoutingAdapter
- exposes XOR distance metric
- findClosestPeers
- delegates to underlying routing table
- uses default k value
- findClosestPeersToKey
- converts key to PeerId and delegates
- uses default k value
- addPeer
- delegates to underlying routing table
- handles null address
- removePeer
- delegates to underlying routing table
- containsPeer
- delegates to underlying routing table
- peerCount
- delegates to underlying routing table
- clear
- delegates to underlying routing table

## `test/protocols/dht/kademlia_routing_adapter_test.mocks.dart`


## `test/protocols/dht/kademlia_routing_table_test.dart`

- KademliaRoutingTable
- initialization
- addPeer adds peers to correct bucket
- IP limit enforcement
- buckets management
- refresh and stale node coverage
- removePeer
- updatePeer coverage
- updatePeer failure path
- pingPeer failure
- findClosestPeers and internal bucket management
- stale threshold with different NodeStats
- findClosestPeers
- addKeyProvider and updateKeyProviderTimestamp
- xorDistanceComparator Tiebreakers
- addPeer with existing IP and removal
- refresh and generateRandomKeyInBucket
- nodeLookup and getAssociatedPeer
- clear
- distance sub-byte edge cases
- removePeer for non-existent peer
- update existing key provider
- stale node removal across multiple buckets
- distance and peersEqual edge cases
- IP count cleanup on removal
- stale node removal coverage
- addPeerToBucket on full bucket drops peer
- updatePeer on full bucket

## `test/protocols/dht/kademlia_test.dart`

- KademliaRoutingTable
- initialize correctly sets up root node
- addPeer adds a new peer
- removePeer removes an existing peer
- bucket capacity limits (no split on fixed buckets)
- clear removes all peers
- IP diversity check limits peers per IP

## `test/protocols/dht/kademlia_tree/bucket_management_enhanced_test.dart`

- BucketManagement Enhanced Coverage
- getBucketIndex edge cases
- canSplitBucket boundary
- canMergeBuckets boundary
- splitBucket with empty buckets handling
- mergeBuckets with wrong order or non-adjacent
- findLeastRecentlySeenNode with empty bucket
- findLeastRecentlySeenNode with missing lastSeen data
- handleBucketFullness split case
- handleBucketFullness no split, replacement case
- calculateConnectionStabilityScore with bonus and penalties

## `test/protocols/dht/kademlia_tree/bucket_management_test.dart`

- BucketManagement
- getBucketIndex returns expected values
- splitBucket increases bucket count if bucket not empty
- mergeBuckets decreases bucket count
- findLeastRecentlySeenNode returns oldest node
- calculateConnectionStabilityScore with different states
- calculateConnectionStabilityScore with failed requests
- calculateConnectionStabilityScore with RTT
- handleBucketFullness - unresponsive node replacement
- handleBucketFullness - better candidate replacement
- handleBucketFullness - recently active peer replacement

## `test/protocols/dht/kademlia_tree/bucket_management_test.mocks.dart`


## `test/protocols/dht/kademlia_tree/helpers_test.dart`

- DHT Helpers
- calculateDistance returns correct XOR distance
- getBucketIndex returns correct index
- findClosestNode finds the best node in subtree
- splitNode creates children correctly
- mergeNodes clears children
- findNode returns closer peers on success
- findNode returns empty list on failure

## `test/protocols/dht/kademlia_tree/helpers_test.mocks.dart`


## `test/protocols/dht/kademlia_tree/lru_cache_test.dart`

- LRUCache
- should store and retrieve values
- should return null for non-existent keys
- should evict least recently used item when capacity is reached
- should update existing key and move to front
- get() should move middle item to front
- getLRUNodes should return nodes in LRU order
- getLRUNodes should return fewer nodes if cache is smaller than count
- should work with capacity 1
- put same key multiple times should not increase size
- getLRUNodes on empty cache should return empty list
- should throw error for non-positive capacity

## `test/protocols/dht/kademlia_tree/protocol_messages_test.dart`

- PingMessage
- creates ping message
- converts to DHT message
- StoreMessage
- creates store message
- converts to DHT message
- FindNodeMessage
- creates find node message
- converts to DHT message
- FindValueMessage
- creates find value message
- converts to DHT message
- AddProviderMessage
- creates add provider message
- converts to DHT message
- GetProvidersMessage
- creates get providers message
- converts to DHT message

## `test/protocols/dht/kademlia_tree/refresh_test.dart`

- Refresh Extension
- refresh() updates lastSeen for recently seen peers
- refresh() removes stale peers
- refresh() handles peers with no entry in lastSeen

## `test/protocols/dht/kademlia_tree/refresh_test.mocks.dart`


## `test/protocols/dht/kademlia_tree/remove_peer_test.dart`

- RemovePeer Extension
- removePeer should remove an existing peer
- removePeer should handle non-existent peer
- removePeer should trigger merge when bucket becomes empty
- removePeer should NOT trigger merge for bucket 0
- removePeer should trigger merge for bucket 0 (closest peers)

## `test/protocols/dht/kademlia_tree/remove_peer_test.mocks.dart`


## `test/protocols/dht/kademlia_tree/value_store_test.dart`

- ValueStore
- store replicates and retrieves value
- retrieve returns null for expired value
- republishValues handles non-expired and expired items
- incrementReplicationCount and updateReplicationCount works
- replicateValue handles failure

## `test/protocols/dht/kademlia_tree/value_store_test.mocks.dart`


## `test/protocols/dht/kademlia_tree_coverage_test.dart`

- KademliaTree Coverage Tests
- Constructor initializes correctly
- findClosestPeers returns closest peers from buckets
- storeLocalValue and getValue delegate to ValueStore
- sendPing failure case
- storeValue failure case
- findValue basic flow with no peers
- handleIncomingMessage can be called
- refresh can be called
- provide announces content to closest peers
- findProviders returns providers for CID
- handleIncomingMessage with PING
- handleIncomingMessage with FIND_NODE
- handleIncomingMessage with GET_VALUE
- handleIncomingMessage with ADD_PROVIDER
- handleIncomingMessage with GET_PROVIDERS
- handleIncomingMessage with PUT_VALUE
- handleResponse completes pending request
- handleResponse with already completed request
- getAssociatedPeer returns null for unknown peer
- nodeLookup respects rate limiter
- findValue respects rate limiter
- storeValue respects rate limiter
- _republishKeys can be called
- refresh can be called multiple times
- findClosestPeers with empty buckets returns empty
- storeLocalValue and getValue work together
- getValue returns null for non-existent key
- nodeLookup with same target multiple times
- findValue with empty closestPeers
- provide with no closestPeers does not throw
- findProviders with no local providers returns empty
- nodeLookup with timeout returns empty
- handleResponse with unknown requestId does not throw
- sendPing success case
- updateConnectionStats
- getNodeStats returns stats for known peer
- getConnectionStats returns stats for known peer
- refresh with empty buckets does not throw
- findClosestPeers with count larger than available returns all
- handleIncomingMessage with unknown type logs and continues
- storeLocalValue with empty value
- findValue with local value returns value
- provide with multiple closestPeers
- findProviders with local providers returns them
- nodeLookup with same target respects rate limiter
- findClosestPeers with count larger than available returns all
- handleIncomingMessage with FIND_NODE handles missing key
- handleIncomingMessage with GET_VALUE handles missing key
- handleIncomingMessage with PUT_VALUE handles missing key
- handleIncomingMessage with ADD_PROVIDER handles missing key
- handleIncomingMessage with GET_PROVIDERS handles missing key
- handleResponse with already completed request does not throw
- getAssociatedPeer returns null for peer not in buckets
- refresh can be called multiple times
- storeLocalValue overwrites existing value
- findValue with local value returns value
- sendPing with timeout returns false
- storeValue with timeout returns false
- provide with timeout completes without error
- findProviders with timeout returns empty
- nodeLookup with timeout returns empty
- findValue with timeout returns null and empty

## `test/protocols/dht/kademlia_tree_coverage_test.mocks.dart`


## `test/protocols/dht/kademlia_tree_enhanced_test.dart`

- KademliaTree Enhanced Coverage
- nodeLookup iterative process with simulated responses
- Rate limiting integration
- Periodic tasks and republishing
- findValue with results
- findValue with no value but closer peers
- storeValue success
- sendPing success

## `test/protocols/dht/optimistic_provider_test.dart`

- OptimisticProvider
- provide returns error when no peers available
- provide succeeds with peers and returns optimistically
- provide handles send failures gracefully
- provide respects maxPeersToContact limit
- provideAll provides multiple CIDs
- provide catches unexpected exceptions
- waitForBackgroundCompletion completes
- OptimisticProvideResult toJson
- OptimisticProvideResult with error
- OptimisticProvideConfig defaults
- provide with single peer

## `test/protocols/dht/optimistic_provider_test.mocks.dart`


## `test/protocols/dht/provider_store_test.dart`

- ProviderStore
- addProvider stores provider for CID
- addProvider deduplicates providers per CID
- getProviders returns empty list for unknown CID
- gc removes nothing when no records are expired
- gc removes expired records
- multiple CIDs are tracked separately
- getProviders returns list copy

## `test/protocols/dht/query_peerset_test.dart`

- tracks state, referrer, uniqueness and XOR order
- matches the upstream qpeerset transition vector

## `test/protocols/dht/rate_limiter_overflow_test.dart`

- RateLimiter queue overflow
- queue is bounded by maxQueueSize
- oldest entry is dropped first (FIFO eviction)
- default maxQueueSize is 1000
- evicted waiter error is catchable and descriptive
- queueLength getter reflects current queue size
- release still works after overflow eviction

## `test/protocols/dht/rate_limiter_test.dart`

- RateLimiter
- Basic acquisition and release
- Window reset
- Multiple releases with queue
- Release when no operations active
- fromConfig
- fromConfig uses default queue size when not set
- Burst handling (all at once)

## `test/protocols/dht/red_black_tree_test.dart`

- RedBlackTree
- Initial tree is empty
- Single insertion
- Multiple insertions without rebalancing
- Insertion Case 1: Uncle is RED (Recoloring)
- Insertion Case 2 & 3: Uncle is BLACK (Rotations)
- Deletion: Simple red node
- Deletion: Black node with one red child
- Search operations
- Update existing key
- Clear tree
- Complex rebalancing after deletions
- Exhaustive Deletion Cases
- Deletion Case 1: Sibling is RED
- Case 2: Sibling is BLACK, both children are BLACK
- Case 3 & 4: Sibling BLACK, one or both children RED
- Mirror Cases (x is right child)
- Delete node with two children
- Delete non-existent node
- Delete all nodes one by one
- Rotation edge cases
- validateTree size mismatch

## `test/protocols/dht/reprovider_test.dart`

- Reprovider strategies
- pinned strategy reprovides recursive pins
- roots strategy reprovides only top-level recursive pins
- all strategy reprovides every block in the blockstore
- pinned+mfs strategy includes MFS root
- entities strategy includes root pins and MFS root
- Reprovider deduplication and status
- deduplicates repeated CIDs before providing
- getStatus reports running and last result
- Reprovider strategy validation
- setStrategy accepts supported strategies
- setStrategy rejects unsupported strategies
- Reprovider lifecycle
- start schedules periodic timer and stop cancels it
- disabled reprovider does not schedule timer

## `test/protocols/dht/xor_distance_metric_test.dart`

- XorDistanceMetric
- calculateDistance
- distance to self is zero
- distance is symmetric
- distance is non-negative
- calculates correct XOR distance for simple bytes
- calculates correct XOR distance for multi-byte values
- handles different length peer IDs
- handles empty peer IDs
- triangle inequality holds approximately
- calculateDistanceToKey
- distance to identical key is zero
- calculates correct XOR distance to key
- handles different length peer ID and key
- handles empty key
- symmetric with calculateDistance when key is peer ID
- distance ordering
- correctly orders peers by distance
- peers with similar IDs have small distances

## `test/protocols/graphsync/graphsync_bidirectional_test.dart`

- Graphsync bidirectional pause/resume
- server pauses traversal when peer sends pause update
- client sends pause, resume, and cancel updates to a peer

## `test/protocols/graphsync/graphsync_budget_test.dart`

- SelectorBudget
- initial state is zero
- tracks block and byte counts
- throws when block count exceeds limit
- throws when byte count exceeds limit
- tracks depth and throws when exceeded
- leaveDepth decrements and never goes below zero

## `test/protocols/graphsync/graphsync_handler_test.dart`

- GraphsyncHandler
- start registers protocol and handler
- getStatus returns correct info
- requestGraph falls back to Bitswap when no peers connected
- requestGraph sends Graphsync to first connected peer
- handleMessage processes new request and unicasts response
- handleMessage rejects invalid request via unicast
- handleMessage processes cancel request unicast
- handleMessage processes pause/unpause request unicast
- handleMessage rejects request when root block not found
- handleMessage enforces block-count budget
- fetchGraphFromPeer collects blocks from peer
- bidirectional pause pauses server-side request
- stop cleans up pending requests

## `test/protocols/graphsync/graphsync_handler_test.mocks.dart`


## `test/protocols/graphsync_test.dart`

- GraphsyncProtocol
- has correct protocol ID
- has default timeout
- createRequest creates valid request message
- createRequest with priority sets priority correctly
- createRequest with extensions includes extensions
- createCancelRequest creates cancel message
- createPauseRequest creates pause message
- createUnpauseRequest creates unpause message
- createResponse creates valid response message
- createResponse with metadata includes metadata
- createResponse with extensions includes extensions
- createResponse with blocks includes blocks
- createProgressResponse creates progress message
- GraphsyncPriority enum has correct values
- GraphsyncExtensions has standard keys
- GraphsyncMetadata has standard keys
- multiple requests can be created
- GraphsyncStatus enum has all standard statuses
- GraphsyncMessageType enum has all standard types

## `test/protocols/identify/identify_handler_test.dart`

- IdentifyHandler
- start registers protocol handler
- stop removes protocol handler
- response includes listen addresses
- response includes public key
- response includes signed peer record when signer provided
- response works without signed peer record
- addProtocol and removeProtocol modify supported list
- identify queries remote peer
- identify returns null on empty response
- identify returns null on null response
- buildIdentifyMessage returns valid message
- peerIdBytes getter returns copy
- IdentifyPushHandler
- start registers push protocol handler
- stop cleans up
- receives push from remote peer and emits event
- ignores empty push message
- pushUpdate sends to all connected peers
- pushUpdate does nothing when no connected peers
- pushUpdate warns when not started
- pushToPeer sends to single peer
- pushToPeer warns when not started
- IdentifyPb
- encode/decode roundtrip with all fields
- encode/decode with minimal fields
- encode/decode with empty message
- toString contains useful info

## `test/protocols/ipns/ipns_handler_integration_test.dart`

- IPNSHandler
- start/stop lifecycle
- start initializes handler and starts DHT
- start is idempotent
- stop clears cache and is idempotent
- getStatus
- returns running state
- returns cache info
- resolve
- resolves IPNS name to CID
- resolves IPNS name with valid base36 format
- publish validation
- publish throws for invalid CID format
- publish throws when keystore is locked
- without PubSub
- handler works without PubSub
- resolve works without PubSub
- createRecord (deprecated - maintain for compatibility)
- creates an unsigned Record
- publishRecord validation
- throws StateError on unsigned record
- resolve caching
- caches resolution and returns cached value

## `test/protocols/ipns/ipns_handler_test.dart`

- IPNSRecord
- create generates a signed record
- verify returns true for valid signed record
- verify returns false for expired record
- toCBOR serializes correctly
- fromCBOR deserializes correctly
- roundtrip preserves data and signature validity
- valueCID parses CID from value
- toString provides readable output
- sequence numbers can be incremented
- different key pairs produce different signatures
- fromCBOR throws on invalid data

## `test/protocols/ipns/ipns_pubsub_test.dart`

- IPNS over PubSub
- start() subscribes to PubSub topic when enabled
- publish() stores signed record via DHT

## `test/protocols/ipns/ipns_pubsub_test.mocks.dart`


## `test/protocols/ipns/ipns_record_test.dart`

- IPNSRecord
- create
- creates signed record with correct fields
- sets default validity and ttl
- uses custom validity and ttl
- verify
- verifies valid signature
- fails for tampered value
- fails for expired record
- toCBOR/fromCBOR
- serializes and deserializes correctly
- preserves signature through round-trip
- valueCID
- parses value as CID
- sign
- can re-sign record with different key

## `test/protocols/ipns/ipns_test.dart`

- IPNS name derivation
- deriveIpnsName produces a base36 multibase string
- PeerId roundtrip from base36
- IPNSRecord
- create signs a record that verifies
- toCBOR / fromCBOR roundtrip preserves fields
- verify fails for a tampered record
- IPNSHandler
- publishWithKeyPair stores a signed record to the DHT
- resolve returns the CID from a signed record
- getRecordBytes returns the signed CBOR record
- resolve throws when no record is found
- resolve rejects an unsigned record
- resolve rejects an expired record
- resolve rejects a name/public key mismatch
- publishRecord stores a pre-constructed signed record
- publishRecord throws for an unsigned record

## `test/protocols/ping/ping_handler_test.dart`

- PingHandler
- start registers protocol handler
- stop removes protocol handler
- server echoes 32-byte payload back
- server echoes even with wrong-size payload (lenient)
- ping succeeds with matching echo
- ping fails when handler not started
- ping fails on null response
- ping fails on wrong response size
- ping fails on mismatched payload
- ping fails on exception
- ping times out
- pingMultiple sends multiple pings
- generatePayload returns 32 bytes
- generatePayload returns different values each call
- PingResult toString for success
- PingResult toString for failure
- protocol constants are correct

## `test/protocols/protocol_coordinator_test.dart`

- ProtocolCoordinator Status Structure
- status contains expected keys
- status values are maps
- ProtocolCoordinator Coverage
- initialize starts all handlers
- initialize throws on handler failure
- stop stops all handlers
- retrieveData uses bitswap when no selector
- retrieveData falls back to IPLD on error
- retrieveData returns null on timeout
- getStatus returns handler statuses
- getStatus returns error on handler failure
- ProtocolCoordinator Fallback Strategy
- retrieval respects useGraphsync flag
- retrieval falls back on failure
- retrieval returns null when all methods fail
- ProtocolCoordinator Lifecycle
- initialize starts all handlers in correct order
- stop stops all handlers in correct order

## `test/protocols/protocol_coordinator_test.mocks.dart`


## `test/protocols/pubsub/gossipsub_pubsub_adapter_test.dart`

- GossipsubPubSubAdapter
- subscribes and publishes to a topic
- delivers decoded string messages to onMessage handlers
- unsubscribe cancels handler subscription

## `test/protocols/pubsub/gossipsub_test.dart`

- protobuf
- RPC round-trip
- message signing
- sign and verify with Ed25519
- verification fails with wrong public key
- MessageCache
- adds and deduplicates messages
- evicts oldest messages when capacity exceeded
- serves messages for IWANT
- PeerScore
- increases on first delivery and penalizes invalid
- score caps topic contributions
- GossipsubHandler lifecycle
- start and stop
- subscribe sends SUBSCRIBE RPC
- publish signs and sends message
- onMessage receives published message
- invalid signature is rejected and penalized
- control messages
- GRAFT adds peer to mesh
- PRUNE removes peer from mesh
- IHAVE triggers IWANT for unknown messages
- IWANT serves cached messages
- heartbeat
- mesh maintenance grafts new peers

## `test/protocols/pubsub/pubsub_client_coverage_test.dart`

- PubSubClient
- start and stop
- subscribe and unsubscribe
- publish success
- handle incoming publish message
- handle ihave message triggers iwant
- handle iwant message sends cached message
- graft and prune
- handle graft action
- handle prune action
- onMessage registers handler
- invalid signature rejection
- heartbeat maintains mesh
- decodeMessage
- encode requests
- message deduplication
- handle ihave with new topic
- getNodeStats throws when not available
- publish when not started throws
- duplicate subscribe is idempotent
- unsubscribe non-existent topic does nothing
- stop when not stopped is idempotent
- _handleIHave with null parameters
- _handleIWant with null parameters
- heartbeat maintains mesh
- heartbeat prunes low scoring peers
- encodePublishRequest includes signature
- decodeMessage handles empty bytes
- publish with empty mesh logs warning
- message without topic is rejected
- message without content is rejected
- message without sender is rejected
- message from unconnected peer is not added to stream
- handle unknown action logs warning
- handle invalid JSON logs error
- subscribe when already started is idempotent
- publish with null mesh peer does not throw
- encodeSubscribeRequest returns non-empty bytes
- encodeUnsubscribeRequest returns non-empty bytes
- decodeMessage handles null bytes
- message with empty topic is rejected
- message with empty content is rejected
- handleGraft with unknown peer adds to mesh
- handlePrune with unknown peer does not throw

## `test/protocols/pubsub/pubsub_client_coverage_test.mocks.dart`


## `test/protocols/pubsub/pubsub_message_test.dart`

- PubSubMessage
- constructs with provided fields
- toString includes all fields

