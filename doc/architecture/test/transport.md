---
test-group: transport
generated: 2026-08-25T08:39:35.507874
---

# `test/transport/`

## `test/transport/browser_transports_test.dart`

- NetworkConfig browser transport settings
- defaults have no hardcoded STUN/TURN servers
- stunServers and turnServers round-trip through JSON
- empty stun/turn lists produce empty ice servers
- buildIceServersFromNetworkConfig creates STUN and TURN entries
- WebTransport multiaddr certhash parsing
- decodes a valid multibase certhash into 32 bytes
- decodes multiple certhashes
- WebRTC transport ICE configuration
- WebRTCTransport uses configurable ICE servers
- WebRTCDirectTransport uses configurable ICE servers
- transports default to no ICE servers when no config is provided

## `test/transport/circuit_relay_client_test.dart`

- CircuitRelayConfig
- defaults are correct
- toJson / fromJson round-trip
- NetworkConfig includes circuitRelay
- HopMessage encode/decode
- RESERVE round-trips with limit
- CONNECT round-trips with peer
- STATUS round-trips with OK and FAILED
- Reservation parsing
- Reservation expiry is calculated correctly
- Reservation carries relayAddr
- CircuitRelayClient reservation
- reserve sends RESERVE and parses reservation
- reserve returns null when disabled
- activeRelayAddrs returns non-expired reservations
- reserve timeout returns null
- CircuitRelayClient connectThroughRelay
- connects through relay and exposes target peer
- builds relayed multiaddr with /p2p-circuit segment
- builds relayed multiaddr when /p2p-circuit is omitted
- emits created event on success
- throws when disabled
- throws when CONNECT is rejected
- emits failure event on CONNECT rejection
- throws on timeout waiting for CONNECT status
- maxCircuits enforcement
- queues additional attempts until a slot is freed
- times out queued attempts when no slot is freed
- disconnect and cleanup
- disconnect removes relayed peer
- router disconnection event emits closed event
- CircuitRelayClient STOP handling
- incoming STOP CONNECT replies with STATUS OK and emits event

## `test/transport/circuit_relay_test.dart`

- CircuitRelayClient
- start and stop
- reserve success
- reserve rejection
- connect and disconnect
- event streams
- reservation timeout
- connect emits event on success
- disconnect emits event on success
- connect emits failure event on error
- disconnect emits failure event on error
- connectionEvents getter returns stream
- CircuitRelayConnectionEvent with dataSize
- emitCircuitRelayEvent does nothing when closed
- reserve with custom parameters
- reserve when not started returns null
- connect when not started does not throw
- disconnect when not started does not throw
- Reservation isExpired returns correct value
- CircuitRelayConnectionEvent with all parameters
- CircuitRelayConnectionEvent default dataSize is zero
- start when already started is idempotent
- stop when not started is safe
- reserve with malformed response handles error
- reserve with silent router times out
- connect with failing router emits failure event
- Reservation with zero limitData
- Reservation with zero limitDuration
- Reservation toString returns default string
- CircuitRelayConnectionEvent with empty parameters
- connect with empty peerId does not throw
- disconnect with empty peerId does not throw
- reserve with empty relayPeerId handles gracefully
- multiple start/stop cycles are safe
- event stream handles multiple listeners
- CircuitRelayConnectionEvent with negative dataSize

## `test/transport/dns/dns_message_test.dart`

- encodeDnsQuery
- matches the real query bytes sent for a TXT lookup
- rejects a label over 63 bytes
- decodeDnsMessage -- real captured responses
- TXT: parses 4 dnsaddr records via name-compressed answers
- A: parses two IPv4 addresses
- AAAA: parses two IPv6 addresses in canonical compressed form
- NXDOMAIN: rcode is 3 with no answer records (SOA is authority-only)
- decodeDnsMessage -- structural validation
- rejects a message shorter than the 12-byte header
- rejects a forward-pointing compression pointer
- rejects RDATA that overruns the message

## `test/transport/dns/system_resolver_network_test.dart`

- SystemResolver + dart_ipfs_core Resolver (live network)
- resolves a real /dnsaddr/ bootstrap multiaddr
- resolves a plain dns4 hostname to real IPv4 addresses

## `test/transport/dns/udp_dns_client_network_test.dart`

- UdpDnsClient
- falls back to the next resolver when the first one times out
- a nonexistent domain resolves to an empty list, not an error
- TXT lookup matches the real bootstrap.libp2p.io records

## `test/transport/http_gateway_client_test.dart`

- HttpGatewayClient
- get returns data when gateway succeeds
- get returns null when all gateways fail
- get uses specific baseUrl if provided
- get handles fallback correctly
- isReachable returns true on success
- isReachable returns false on failure
- close closes internal client
- close does not close external client
- get handles 404 from gateway
- fetchRawBlock uses ?format=raw endpoint
- fetchRawBlock returns null on 404
- fetchRawBlock respects maxBlockSize

## `test/transport/libp2p_router_coverage_test.dart`

- Libp2pRouter Coverage
- initialize should handle seed
- initialize should not re-initialize
- start should handle empty listen addresses
- start should handle invalid port in listen addresses
- start should not re-start
- stop should handle not started
- connect should throw on invalid multiaddress
- disconnect should handle multiaddress and peerId
- broadcastMessage should send to multiple peers
- sendRequest should receive response
- getters and basic methods
- broadcastMessage should handle failure for some peers
- sendMessage should handle large messages
- stop should handle multiple calls
- receiveMessages should return same stream
- event methods management
- parseMultiaddr and resolvePeerId
- methods should throw if not started
- protocol management

## `test/transport/libp2p_router_test.dart`

- Libp2pRouter Integration
- should start and stop successfully
- should connect to another peer
- should send and receive messages

## `test/transport/libp2p_transport_test.dart`

- Libp2pTransport Protocol ID
- p2plib protocol ID is correct
- Libp2pTransport Frame Protocol
- frame length is encoded as 4 bytes big-endian
- frame length decoding extracts correct value
- frame length handles larger values
- Libp2pTransport Address Handling
- MultiAddr format is correct
- MultiAddr parses IPv4 correctly
- Libp2pTransport State
- isStarted logic is correct
- stream cache cleanup on stop
- Identity Derivation
- seed presence determines identity type
- PeerId Conversion
- extracts first 32 bytes for Ed25519 public key

## `test/transport/noise/noise_state_test.dart`

- Noise_XX_25519_ChaChaPoly_SHA256 -- real flynn/noise vector
- every handshake and transport message matches byte-for-byte
- HandshakeState -- self-interop sanity
- two fresh sessions complete a handshake and exchange data

## `test/transport/pnet/pnet_test.dart`

- Swarm key loader
- decodeV1Psk parses the test swarm key
- decodeV1Psk rejects an invalid version marker
- decodeV1Psk rejects a wrong-length hex key
- PNET handshake and cipher state
- handshake produces matching keystreams and round-trips data
- mismatched PSKs fail the handshake or corrupt data
- PNET transport wrapper round-trip over TCP
- wrapped TCP transport round-trips data

## `test/transport/quic_transport_test.dart`

- QUIC transport
- NetworkConfig QUIC defaults are correct
- NetworkConfig parses QUIC fields from JSON
- NetworkConfig serializes QUIC fields to JSON
- supportsQuic is true when QUIC is enabled and available
- supportsQuic is false when enableQuic is false
- does not log fallback warning when QUIC is enabled and available
- does not log fallback warning when QUIC is disabled
- synthesizes QUIC listen addresses when QUIC is available
- does not synthesize QUIC listen addresses when QUIC is disabled

## `test/transport/router_events_test.dart`

- NetworkMessage
- stores data correctly
- fromBytes creates message
- NetworkPacket
- stores srcPeerId and datagram
- ConnectionEvent
- connected event has correct type
- disconnected event has correct type
- MessageEvent
- stores peerId and message
- DHTEvent
- valueFound event with data
- providerFound event
- PubSubEvent
- stores all fields
- ErrorEvent
- connectionError type
- all error types exist
- StreamEvent
- opened event
- data event with payload
- closed event

## `test/transport/router_polymorphism_test.dart`

- PingHandler succeeds with a valid RTT against a 

## `test/transport/stream_controller_lifecycle_test.dart`

- Libp2pRouter StreamController lifecycle
- receiveMessages creates a stream for a peer
- disconnect closes the peer message stream controller
- stop closes all peer message stream controllers
- receiveMessages returns streams backed by same controller for same peer
- receiveMessages returns different streams for different peers
- disconnect removes the controller so a new stream is created on 
- NetworkManager dispose
- dispose closes the event stream controller

## `test/transport/webrtc_signaling_test.dart`

- SignalingMessage
- should encode and decode offer message
- should encode and decode candidate message
- should fail decoding invalid bytes

## `test/transport/webrtc_transport_test.dart`

- WebRTCConnection
- lifecycle
- close is idempotent
- newStream
- newStream throws when closed
- incoming data channels are tracked
- stat and scope return sensible values
- DataChannelStream
- basic properties
- read and write
- read waits for data
- close and reset
- onClosed completes pending reads
- WebRTCTransport
- canDial
- canListen
- dial success
- WebRTCListener
- lifecycle
- accept returns null
- signaling stream handling

## `test/transport/webrtc_transport_test.mocks.dart`


## `test/transport/webtransport/webtransport_datagram_test.dart`

- WebTransportDatagram
- should initialize with correct default state
- should send a datagram
- should send multiple datagrams
- should throw on oversized datagram
- should throw on empty datagram
- should throw when sending on closed channel
- should return false when backend rejects datagram
- should trySend without throwing
- should trySend oversized datagram without throwing
- should trySend empty datagram without throwing
- should receive datagrams via stream
- should receive multiple datagrams
- should not receive datagrams after close
- should close the datagram channel
- should close idempotently
- should handle backend stream done
- should forward receive errors to stream
- should use minimum of config and backend max size
- should use config max size when backend has no size function
- should apply backpressure when queue is full
- should track stats correctly
- should reset stats
- WebTransportDatagramStats
- should have a string representation
- DatagramSizeNegotiator
- should return local max when remote is unknown
- should return minimum of local and remote
- should return local when local is smaller
- should update remote max size
- should update local max size
- should validate datagram size
- WebTransportDatagramEvent
- should expose size
- should store timestamp

## `test/transport/webtransport/webtransport_session_test.dart`

- WebTransportSession
- should initialize with correct default state
- should open a bidirectional stream
- should open multiple bidirectional streams with incrementing IDs
- should open a unidirectional stream
- should throw when opening stream on closed session
- should throw when opening stream on draining session
- should send a datagram
- should throw when sending oversized datagram
- should throw when sending datagram on closed session
- should close session gracefully
- should close session with error code and reason
- should close session idempotently
- should close all open streams when session closes
- should initiate drain
- should throw when initiating drain on closed session
- should handle peer close
- should handle peer drain
- should handle GOAWAY from peer
- should receive incoming datagrams
- should receive incoming bidirectional streams
- should receive incoming unidirectional streams
- should not receive datagrams after close
- should remove stream from tracking
- should enforce max bidirectional stream limit
- should enforce max unidirectional stream limit
- should track session duration
- WebTransportBidiStream
- should write and read data
- should close gracefully
- should reset abruptly
- should close idempotently
- WebTransportUniStream
- should write data
- should close gracefully
- should reset abruptly
- should throw when writing to closed stream
- WebTransportSessionManager
- should initialize with correct defaults
- should register a session
- should throw when registering duplicate session
- should enforce max sessions limit
- should remove a session
- should close all sessions
- should cleanup inactive sessions
- WebTransportSettings
- should build server settings
- should build server settings without datagrams
- should build client settings
- should parse settings correctly
- should detect WebTransport support
- should detect lack of WebTransport support
- should detect datagram support
- should detect lack of datagram support
- should default wtMaxSessions to wtInitialMaxStreamsBidi
- should default wtMaxSessions to 100 when not specified

## `test/transport/webtransport/webtransport_transport_test.dart`

- WebTransportTransport
- should initialize with default config
- should initialize with custom max sessions
- should initialize with custom max datagram size
- canDial should return true for webtransport multiaddr
- canDial should return false for non-webtransport multiaddr
- canListen should match canDial
- should register and retrieve sessions
- should enforce max sessions limit
- should throw on duplicate session registration
- should close all sessions on dispose
- should build server settings
- should build client settings
- should validate peer settings with WebTransport support
- should reject peer settings without WebTransport support
- should reject peer settings without Extended CONNECT
- should reject peer settings without WT enabled
- config should return a TransportConfig
- WebTransportTransport integration
- should support full session lifecycle through transport
- should enforce max sessions across multiple registrations

## `test/transport/webtransport_parser_test.dart`

- WebTransportMultiaddrParser
- should parse valid WebTransport multiaddr
- should parse multiaddr with multiple certhashes
- should return null for non-WebTransport multiaddr

