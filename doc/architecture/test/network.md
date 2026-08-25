---
test-group: network
generated: 2026-08-25T01:38:20.167468
---

# `test/network/`

## `test/network/connection_manager_test.mocks.dart`


## `test/network/mdns_client_test.dart`

- ResourceRecordQuery
- static helpers create correct queries
- MDnsClient
- Lifecycle
- start and stop
- start already running
- stop when not running
- Lookup
- throws StateError when not running
- transforms PTR record
- transforms SRV record
- transforms TXT record
- filters out incompatible record types
- handles timeout
- rethrows non-timeout exceptions
- returns null for A and AAAA records (unsupported transformation)
- Server / Responder Errors
- startServer handles bind error
- announce handles error
- Packet Parsing Edge Cases
- handles multiple questions in one packet
- ignores packet with malformed question name
- ignores packet with compression pointer (not supported)
- handles question at the end of packet buffer
- Server / Responder
- startServer sets up socket
- announce sends response
- announce does nothing if server not started
- handles matching query packet
- handles matching instance query packet
- ignores non-matching query
- ignores response packets
- ignores short packets
- Record Transformations (Edge Cases)
- _transformRecord returns null for unknown combination
- PTR record construction
- SRV record construction
- TXT record construction
- ResourceRecordType
- enum values exist

## `test/network/mdns_client_test.mocks.dart`


## `test/network/nat_traversal_service_improved_test.dart`

- NatTraversalService mapPort
- successfully maps both TCP and UDP
- successfully maps only TCP when UDP fails
- successfully maps only UDP when TCP fails
- returns empty list when both fail
- respects lease duration
- handles null gateway and discovery failure
- NatTraversalService unmapPort
- successfully unmaps both TCP and UDP
- handles exceptions during unmap
- does nothing if gateway is null
- NatTraversalService Error Handling
- handles top-level exception in mapPort

## `test/network/nat_traversal_service_improved_test.mocks.dart`


## `test/network/nat_traversal_service_test.dart`

- NatTraversalService Port Types
- supports TCP protocol
- supports UDP protocol
- NatTraversalService mapPort Logic
- returns empty list when no gateway found
- returns list of mapped protocols on success
- partial success returns only successful protocols
- NatTraversalService unmapPort Logic
- skips when gateway is null
- attempts to close both TCP and UDP
- NatTraversalService Lease Duration
- default lease duration is 0 (permanent)
- custom lease duration is respected
- NatTraversalService Gateway Discovery
- lazy discovery on first mapPort call

## `test/network/router_test.mocks.dart`


