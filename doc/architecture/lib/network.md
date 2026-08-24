---
module: network
kind: lib/src audit
generated: 2026-08-24T07:44:28.495387
---

# Módulo `network` (`lib/src/network/`)

_Gerado por `tool/generate_module_index.dart` via AST não-resolvida (`package:analyzer`). "Chama"/"referenciado por" casam por nome de identificador, não por tipo resolvido -- ver aviso no topo do script. Não editar à mão._

Depende de: [core](core.md), [transport](transport.md), [utils](utils.md)

## `lib/src/network/mdns_client.dart`

Base class for mDNS resource records.

_Testado diretamente._

### abstract class `ResourceRecord`

- **name** (field)
  - referenciado por (por nome): `lib/src/core/data_structures/directory.dart` (IPFSDirectoryEntry.toLink), `lib/src/core/data_structures/directory.dart` (IPFSDirectoryManager.build), `lib/src/core/data_structures/link.dart` (Link.toProto), `lib/src/core/data_structures/operation_log.dart` (OperationLogEntry.toString), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.start), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.stop), `lib/src/core/ipfs_node/ipld_handler.dart` (IPLDHandler.registerSchema), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.rm), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.ls), `lib/src/core/plugins/plugin_host.dart` (PluginHost.loadPluginFromYaml), `lib/src/core/unixfs/unixfs_directory.dart` (UnixFSDirectoryBuilder.build), `lib/src/core/unixfs/unixfs_directory.dart` (createDirectory), `lib/src/core/unixfs/unixfs_directory.dart` (addChildToDirectory), `lib/src/core/unixfs/unixfs_hamt.dart` (UnixFSHAMTBuilder.build), `lib/src/core/unixfs/unixfs_hamt.dart` (resolveHAMTSegment), `lib/src/core/unixfs/unixfs_node.dart` (findLinkByName), `lib/src/network/mdns_client_io.dart` (MDnsClientIO.lookup), `lib/src/services/gateway/adaptive_compression_handler.dart` (AdaptiveCompressionHandler.compressBlock), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.storeCompressedData), `lib/src/services/gateway/directory_parser.dart` (DirectoryParser.parseDirectoryBlock), `lib/src/services/gateway/directory_parser.dart` (DirectoryParser.generateHtmlListing), `lib/src/services/gateway/gateway_directory_handler.dart` (GatewayDirectoryHandler.renderDirectory), `lib/src/services/pinning/remote_pinning_service.dart` (RemotePinningService.syncPin), `lib/src/services/pinning/remote_pinning_service.dart` (RemotePinningService.load), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleLs)
- **ttl** (field)
  - referenciado por (por nome): `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.publishIPNS), `lib/src/protocols/ipns/ipns_record.dart` (IPNSRecord.toIpnsEntry), `lib/src/protocols/ipns/ipns_record.dart` (IPNSRecord.fromIpnsEntry)

### class `PtrResourceRecord` extends ResourceRecord

- **domainName** (field)

### class `SrvResourceRecord` extends ResourceRecord

- **target** (field)
- **port** (field)
  - referenciado por (por nome): `lib/src/core/data_structures/peer.dart` (multiaddrToBytes), `lib/src/platform/http_server_adapter_io.dart` (IpfsHttpServerInstanceIO.port), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.url), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.url), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportDialerWeb.dial)
- **priority** (field)
  - referenciado por (por nome): `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.wantBlock), `lib/src/protocols/bitswap/message.dart` (Message.fromBytes), `lib/src/protocols/bitswap/message.dart` (Message.toBytes), `lib/src/protocols/connection_manager/cuttlefish_connection_manager.dart` (CuttlefishConnectionManager.tag), `lib/src/protocols/connection_manager/cuttlefish_connection_manager.dart` (CuttlefishConnectionManager.untag), `lib/src/protocols/graphsync/graphsync_protocol.dart` (GraphsyncProtocol.createRequest)
- **weight** (field)

### class `TxtResourceRecord` extends ResourceRecord

- **text** (field)

### class `ResourceRecordQuery`

- **name** (field)
  - referenciado por (por nome): `lib/src/core/data_structures/directory.dart` (IPFSDirectoryEntry.toLink), `lib/src/core/data_structures/directory.dart` (IPFSDirectoryManager.build), `lib/src/core/data_structures/link.dart` (Link.toProto), `lib/src/core/data_structures/operation_log.dart` (OperationLogEntry.toString), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.start), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.stop), `lib/src/core/ipfs_node/ipld_handler.dart` (IPLDHandler.registerSchema), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.rm), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.ls), `lib/src/core/plugins/plugin_host.dart` (PluginHost.loadPluginFromYaml), `lib/src/core/unixfs/unixfs_directory.dart` (UnixFSDirectoryBuilder.build), `lib/src/core/unixfs/unixfs_directory.dart` (createDirectory), `lib/src/core/unixfs/unixfs_directory.dart` (addChildToDirectory), `lib/src/core/unixfs/unixfs_hamt.dart` (UnixFSHAMTBuilder.build), `lib/src/core/unixfs/unixfs_hamt.dart` (resolveHAMTSegment), `lib/src/core/unixfs/unixfs_node.dart` (findLinkByName), `lib/src/network/mdns_client_io.dart` (MDnsClientIO.lookup), `lib/src/services/gateway/adaptive_compression_handler.dart` (AdaptiveCompressionHandler.compressBlock), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.storeCompressedData), `lib/src/services/gateway/directory_parser.dart` (DirectoryParser.parseDirectoryBlock), `lib/src/services/gateway/directory_parser.dart` (DirectoryParser.generateHtmlListing), `lib/src/services/gateway/gateway_directory_handler.dart` (GatewayDirectoryHandler.renderDirectory), `lib/src/services/pinning/remote_pinning_service.dart` (RemotePinningService.syncPin), `lib/src/services/pinning/remote_pinning_service.dart` (RemotePinningService.load), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleLs)
- **type** (field)
  - referenciado por (por nome): `lib/src/core/crypto/ecdsa_signer.dart` (EcdsaSigner.decodePublicKeyPb), `lib/src/core/crypto/rsa_signer.dart` (RsaSigner.decodePublicKeyPb), `lib/src/core/data_structures/merkle_dag_node.dart` (MerkleDAGNode.fromBytes), `lib/src/core/data_structures/pin.dart` (Pin.toProto), `lib/src/core/ipfs_node/ipld_handler.dart` (IPLDHandler.executeSelector), `lib/src/core/messages/message_factory.dart` (MessageFactory.createBaseMessage), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.rm), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.ls), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.stat), `lib/src/core/peer/peer_record.dart` (PeerRecordVerifier.verifyEnvelope), `lib/src/core/peer/peer_record_pb.dart` (PublicKeyPb.==), `lib/src/core/plugins/plugin_manifest.dart` (PluginManifest.verifySignature), `lib/src/core/unixfs/unixfs_node.dart` (UnixFSNode.isFile), `lib/src/core/unixfs/unixfs_node.dart` (UnixFSNode.isDirectory), `lib/src/core/unixfs/unixfs_node.dart` (UnixFSNode.isSymlink), `lib/src/core/unixfs/unixfs_node.dart` (UnixFSNode.isHAMTShard), `lib/src/core/validation/message_validator.dart` (MessageValidator.validateMessage), `lib/src/network/mdns_client_io.dart` (MDnsClientIO.lookup), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.delete), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.sendDontHave), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.sendHave), `lib/src/protocols/bitswap/message.dart` (Message.fromBytes), `lib/src/protocols/bitswap/message.dart` (Message.toBytes), `lib/src/protocols/dht/dht_client.dart` (DHTClient.initialize), `lib/src/protocols/dht/dht_client.dart` (DHTClient.findProviders), `lib/src/protocols/dht/dht_client.dart` (DHTClient.findPeer), `lib/src/protocols/dht/dht_client.dart` (DHTClient.addProvider), `lib/src/protocols/dht/dht_client.dart` (DHTClient.addProviders), `lib/src/protocols/dht/dht_client.dart` (DHTClient.storeValue), `lib/src/protocols/dht/dht_client.dart` (DHTClient.storeValueToPeer), `lib/src/protocols/dht/dht_client.dart` (DHTClient.getValue), `lib/src/protocols/dht/dht_client.dart` (DHTClient.storeValueRaw), `lib/src/protocols/dht/dht_client.dart` (DHTClient.getValueRaw), `lib/src/protocols/dht/dht_client.dart` (DHTClient.checkValueOnPeer), `lib/src/protocols/dht/kademlia_routing_table.dart` (KademliaRoutingTable.pingPeer), `lib/src/protocols/dht/kademlia_tree/protocol_messages.dart` (PingMessage.toDHTMessage), `lib/src/protocols/dht/kademlia_tree/protocol_messages.dart` (StoreMessage.toDHTMessage), `lib/src/protocols/dht/kademlia_tree/protocol_messages.dart` (FindNodeMessage.toDHTMessage), `lib/src/protocols/dht/kademlia_tree/protocol_messages.dart` (FindValueMessage.toDHTMessage), `lib/src/protocols/dht/kademlia_tree/protocol_messages.dart` (AddProviderMessage.toDHTMessage), `lib/src/protocols/dht/kademlia_tree/protocol_messages.dart` (GetProvidersMessage.toDHTMessage), `lib/src/protocols/dht/kademlia_tree.dart` (KademliaTree.handleIncomingMessage), `lib/src/protocols/dht/kademlia_tree.dart` (KademliaTree.findProviders), `lib/src/protocols/dht/kademlia_tree.dart` (KademliaTree.sendPing), `lib/src/protocols/dht/kademlia_tree.dart` (KademliaTree.storeValue), `lib/src/protocols/dht/kademlia_tree.dart` (KademliaTree.findValue), `lib/src/protocols/dht/optimistic_provider.dart` (OptimisticProvider.provide), `lib/src/services/gateway/directory_parser.dart` (DirectoryParser.parseDirectoryBlock), `lib/src/services/gateway/gateway_content_handler.dart` (GatewayContentHandler.serveContent), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.start), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.reserve), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.connectThroughRelay), `lib/src/transport/webrtc/peer_connection_web.dart` (PeerConnectionWeb.createOffer), `lib/src/transport/webrtc/peer_connection_web.dart` (PeerConnectionWeb.createAnswer), `lib/src/transport/webrtc/peer_connection_web.dart` (PeerConnectionWeb.setLocalDescription), `lib/src/transport/webrtc/webrtc_transport.dart` (WebRTCTransport.dial)
- **serverPointer** (method) — chama: ResourceRecordQuery, ptr
- **service** (method) — chama: ResourceRecordQuery, srv
- **text** (method) — chama: ResourceRecordQuery, txt

### abstract class `MDnsClient`

- **start** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/auto_nat_handler.dart` (AutoNATHandler.start), `lib/src/core/ipfs_node/content_routing_handler.dart` (ContentRoutingHandler.start), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.restart), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.start), `lib/src/core/ipfs_node/lifecycle_manager.dart` (LifecycleManager.startAll), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.start), `lib/src/core/ipfs_node/network_manager.dart` (NetworkManager.start), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.start), `lib/src/core/ipfs_node/routing_handler.dart` (RoutingHandler.start), `lib/src/core/ipld/selectors/selector_ast.dart` (ExploreRange.==), `lib/src/network/mdns_client_io.dart` (MDnsClientIO.start), `lib/src/network/router.dart` (Router.start), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.start), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.start), `lib/src/protocols/dht/dht_client.dart` (DHTClient.initialize), `lib/src/protocols/dht/dht_client.dart` (DHTClient.start), `lib/src/protocols/dht/dht_client.dart` (DHTClient.reprovide), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.start), `lib/src/protocols/dht/optimistic_provider.dart` (OptimisticProvider.provide), `lib/src/protocols/ipns/ipns_handler.dart` (IPNSHandler.start), `lib/src/protocols/ping/ping_handler.dart` (PingHandler.ping), `lib/src/protocols/protocol_coordinator.dart` (ProtocolCoordinator.initialize), `lib/src/protocols/pubsub/gossipsub/gossipsub_pubsub_adapter.dart` (GossipsubPubSubAdapter.start), `lib/src/routing/content_routing.dart` (ContentRouting.start), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.start), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.start)
- **stop** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/auto_nat_handler.dart` (AutoNATHandler.stop), `lib/src/core/ipfs_node/content_routing_handler.dart` (ContentRoutingHandler.stop), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.restart), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.stop), `lib/src/core/ipfs_node/lifecycle_manager.dart` (LifecycleManager.stopAll), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.stop), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.stop), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.stop), `lib/src/core/ipfs_node/routing_handler.dart` (RoutingHandler.stop), `lib/src/network/mdns_client_io.dart` (MDnsClientIO.stop), `lib/src/network/router.dart` (Router.stop), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.stop), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.stop), `lib/src/protocols/dht/dht_client.dart` (DHTClient.reprovide), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.stop), `lib/src/protocols/dht/optimistic_provider.dart` (OptimisticProvider.provide), `lib/src/protocols/ping/ping_handler.dart` (PingHandler.ping), `lib/src/protocols/protocol_coordinator.dart` (ProtocolCoordinator.stop), `lib/src/protocols/pubsub/gossipsub/gossipsub_pubsub_adapter.dart` (GossipsubPubSubAdapter.stop), `lib/src/routing/content_routing.dart` (ContentRouting.stop)
- **lookup** (method)
  - referenciado por (por nome): `lib/src/network/mdns_client_io.dart` (MDnsClientIO.lookup), `lib/src/services/gateway/content_type_handler.dart` (ContentTypeHandler.detectContentType)
- **startServer** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start)
- **announce** (method)
- **isRunning** (method)
  - referenciado por (por nome): `lib/src/core/services/health_check_service.dart` (HealthCheckService.checkHealth)

## `lib/src/network/mdns_client_io.dart`

IO implementation of the mDNS client.

_Sem teste direto conhecido._

### class `MDnsClientIO` implements MDnsClient

- **start** (method) — chama: MDnsClient, start
  - referenciado por (por nome): `lib/src/core/ipfs_node/auto_nat_handler.dart` (AutoNATHandler.start), `lib/src/core/ipfs_node/content_routing_handler.dart` (ContentRoutingHandler.start), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.restart), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.start), `lib/src/core/ipfs_node/lifecycle_manager.dart` (LifecycleManager.startAll), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.start), `lib/src/core/ipfs_node/network_manager.dart` (NetworkManager.start), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.start), `lib/src/core/ipfs_node/routing_handler.dart` (RoutingHandler.start), `lib/src/core/ipld/selectors/selector_ast.dart` (ExploreRange.==), `lib/src/network/router.dart` (Router.start), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.start), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.start), `lib/src/protocols/dht/dht_client.dart` (DHTClient.initialize), `lib/src/protocols/dht/dht_client.dart` (DHTClient.start), `lib/src/protocols/dht/dht_client.dart` (DHTClient.reprovide), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.start), `lib/src/protocols/dht/optimistic_provider.dart` (OptimisticProvider.provide), `lib/src/protocols/ipns/ipns_handler.dart` (IPNSHandler.start), `lib/src/protocols/ping/ping_handler.dart` (PingHandler.ping), `lib/src/protocols/protocol_coordinator.dart` (ProtocolCoordinator.initialize), `lib/src/protocols/pubsub/gossipsub/gossipsub_pubsub_adapter.dart` (GossipsubPubSubAdapter.start), `lib/src/routing/content_routing.dart` (ContentRouting.start), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.start), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.start)
- **stop** (method) — chama: stop
  - referenciado por (por nome): `lib/src/core/ipfs_node/auto_nat_handler.dart` (AutoNATHandler.stop), `lib/src/core/ipfs_node/content_routing_handler.dart` (ContentRoutingHandler.stop), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.restart), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.stop), `lib/src/core/ipfs_node/lifecycle_manager.dart` (LifecycleManager.stopAll), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.stop), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.stop), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.stop), `lib/src/core/ipfs_node/routing_handler.dart` (RoutingHandler.stop), `lib/src/network/router.dart` (Router.stop), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.stop), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.stop), `lib/src/protocols/dht/dht_client.dart` (DHTClient.reprovide), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.stop), `lib/src/protocols/dht/optimistic_provider.dart` (OptimisticProvider.provide), `lib/src/protocols/ping/ping_handler.dart` (PingHandler.ping), `lib/src/protocols/protocol_coordinator.dart` (ProtocolCoordinator.stop), `lib/src/protocols/pubsub/gossipsub/gossipsub_pubsub_adapter.dart` (GossipsubPubSubAdapter.stop), `lib/src/routing/content_routing.dart` (ContentRouting.stop)
- **lookup** (method) — chama: ResourceRecordQuery, _getResourceRecordType, type, name, timeout, lookup, _transformRecord
  - referenciado por (por nome): `lib/src/services/gateway/content_type_handler.dart` (ContentTypeHandler.detectContentType)
- **isRunning** (method)
  - referenciado por (por nome): `lib/src/core/services/health_check_service.dart` (HealthCheckService.checkHealth)
- **startServer** (method) — chama: bind, anyIPv4, joinMulticast, listen, read, receive, _handlePacket
  - referenciado por (por nome): `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start)
- **announce** (method) — chama: _sendResponse

### class `_Pair`

- **item1** (field)
- **item2** (field)

### top-level `createMDnsClient` (function)

- **createMDnsClient** (function) — chama: MDnsClientIO

## `lib/src/network/mdns_client_stub.dart`

Stub implementation of the mDNS client for platforms where it's not supported.

_Sem teste direto conhecido._

### class `MDnsClientStub` implements MDnsClient

- **start** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/auto_nat_handler.dart` (AutoNATHandler.start), `lib/src/core/ipfs_node/content_routing_handler.dart` (ContentRoutingHandler.start), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.restart), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.start), `lib/src/core/ipfs_node/lifecycle_manager.dart` (LifecycleManager.startAll), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.start), `lib/src/core/ipfs_node/network_manager.dart` (NetworkManager.start), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.start), `lib/src/core/ipfs_node/routing_handler.dart` (RoutingHandler.start), `lib/src/core/ipld/selectors/selector_ast.dart` (ExploreRange.==), `lib/src/network/mdns_client_io.dart` (MDnsClientIO.start), `lib/src/network/router.dart` (Router.start), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.start), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.start), `lib/src/protocols/dht/dht_client.dart` (DHTClient.initialize), `lib/src/protocols/dht/dht_client.dart` (DHTClient.start), `lib/src/protocols/dht/dht_client.dart` (DHTClient.reprovide), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.start), `lib/src/protocols/dht/optimistic_provider.dart` (OptimisticProvider.provide), `lib/src/protocols/ipns/ipns_handler.dart` (IPNSHandler.start), `lib/src/protocols/ping/ping_handler.dart` (PingHandler.ping), `lib/src/protocols/protocol_coordinator.dart` (ProtocolCoordinator.initialize), `lib/src/protocols/pubsub/gossipsub/gossipsub_pubsub_adapter.dart` (GossipsubPubSubAdapter.start), `lib/src/routing/content_routing.dart` (ContentRouting.start), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.start), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.start)
- **stop** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/auto_nat_handler.dart` (AutoNATHandler.stop), `lib/src/core/ipfs_node/content_routing_handler.dart` (ContentRoutingHandler.stop), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.restart), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.stop), `lib/src/core/ipfs_node/lifecycle_manager.dart` (LifecycleManager.stopAll), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.stop), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.stop), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.stop), `lib/src/core/ipfs_node/routing_handler.dart` (RoutingHandler.stop), `lib/src/network/mdns_client_io.dart` (MDnsClientIO.stop), `lib/src/network/router.dart` (Router.stop), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.stop), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.stop), `lib/src/protocols/dht/dht_client.dart` (DHTClient.reprovide), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.stop), `lib/src/protocols/dht/optimistic_provider.dart` (OptimisticProvider.provide), `lib/src/protocols/ping/ping_handler.dart` (PingHandler.ping), `lib/src/protocols/protocol_coordinator.dart` (ProtocolCoordinator.stop), `lib/src/protocols/pubsub/gossipsub/gossipsub_pubsub_adapter.dart` (GossipsubPubSubAdapter.stop), `lib/src/routing/content_routing.dart` (ContentRouting.stop)
- **lookup** (method)
  - referenciado por (por nome): `lib/src/network/mdns_client_io.dart` (MDnsClientIO.lookup), `lib/src/services/gateway/content_type_handler.dart` (ContentTypeHandler.detectContentType)
- **startServer** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start)
- **announce** (method)
- **isRunning** (method)
  - referenciado por (por nome): `lib/src/core/services/health_check_service.dart` (HealthCheckService.checkHealth)

### top-level `createMDnsClient` (function)

- **createMDnsClient** (function) — chama: MDnsClientStub

## `lib/src/network/mdns_client_web.dart`

Creates an mDNS client for the Web platform (throws UnsupportedError).

_Sem teste direto conhecido._

### top-level `createMDnsClient` (function)

- **createMDnsClient** (function) — chama: UnsupportedError

## `lib/src/network/nat_traversal_service.dart`

Manages NAT traversal and port forwarding operations.

_Testado diretamente._

### class `NatTraversalService`

- **mapPort** (method) — chama: info, debug, _gatewayDiscoverer, warning, openPort, tcp, inSeconds, add, udp, error
- **unmapPort** (method) — chama: info, closePort, tcp, udp, warning
  - referenciado por (por nome): `lib/src/core/ipfs_node/auto_nat_handler.dart` (AutoNATHandler.stop)

## `lib/src/network/router.dart`

High-level network router for IPFS peer communication.

_Testado diretamente._

### class `Router`

- **peerID** (method) — chama: peerID
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.peerID), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.start), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.peerID), `lib/src/core/ipfs_node/network_handler_web.dart` (NetworkHandler.peerID), `lib/src/core/ipfs_node/network_manager.dart` (NetworkManager.peerId), `lib/src/core/services/health_check_service.dart` (HealthCheckService.checkHealth), `lib/src/protocols/dht/dht_client.dart` (DHTClient.initialize), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.provide), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.provideAll)
- **onPeerDiscovered** (method) — chama: stream
- **connectedPeers** (method) — chama: unmodifiable
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.connectedPeers), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.get), `lib/src/core/services/health_check_service.dart` (HealthCheckService.checkHealth), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.want), `lib/src/protocols/dht/dht_client.dart` (DHTClient.findProviders), `lib/src/protocols/dht/dht_client.dart` (DHTClient.storeValueRaw), `lib/src/protocols/dht/dht_client.dart` (DHTClient.getValueRaw), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleSwarmPeers)
- **isInitialized** (method) — chama: isInitialized
  - referenciado por (por nome): `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.getStatus)
- **start** (method) — chama: start
  - referenciado por (por nome): `lib/src/core/ipfs_node/auto_nat_handler.dart` (AutoNATHandler.start), `lib/src/core/ipfs_node/content_routing_handler.dart` (ContentRoutingHandler.start), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.restart), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.start), `lib/src/core/ipfs_node/lifecycle_manager.dart` (LifecycleManager.startAll), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.start), `lib/src/core/ipfs_node/network_manager.dart` (NetworkManager.start), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.start), `lib/src/core/ipfs_node/routing_handler.dart` (RoutingHandler.start), `lib/src/core/ipld/selectors/selector_ast.dart` (ExploreRange.==), `lib/src/network/mdns_client_io.dart` (MDnsClientIO.start), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.start), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.start), `lib/src/protocols/dht/dht_client.dart` (DHTClient.initialize), `lib/src/protocols/dht/dht_client.dart` (DHTClient.start), `lib/src/protocols/dht/dht_client.dart` (DHTClient.reprovide), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.start), `lib/src/protocols/dht/optimistic_provider.dart` (OptimisticProvider.provide), `lib/src/protocols/ipns/ipns_handler.dart` (IPNSHandler.start), `lib/src/protocols/ping/ping_handler.dart` (PingHandler.ping), `lib/src/protocols/protocol_coordinator.dart` (ProtocolCoordinator.initialize), `lib/src/protocols/pubsub/gossipsub/gossipsub_pubsub_adapter.dart` (GossipsubPubSubAdapter.start), `lib/src/routing/content_routing.dart` (ContentRouting.start), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.start), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.start)
- **stop** (method) — chama: stop, close
  - referenciado por (por nome): `lib/src/core/ipfs_node/auto_nat_handler.dart` (AutoNATHandler.stop), `lib/src/core/ipfs_node/content_routing_handler.dart` (ContentRoutingHandler.stop), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.restart), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.stop), `lib/src/core/ipfs_node/lifecycle_manager.dart` (LifecycleManager.stopAll), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.start), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.stop), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.stop), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.stop), `lib/src/core/ipfs_node/routing_handler.dart` (RoutingHandler.stop), `lib/src/network/mdns_client_io.dart` (MDnsClientIO.stop), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.stop), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.stop), `lib/src/protocols/dht/dht_client.dart` (DHTClient.reprovide), `lib/src/protocols/dht/dht_handler.dart` (DHTHandler.stop), `lib/src/protocols/dht/optimistic_provider.dart` (OptimisticProvider.provide), `lib/src/protocols/ping/ping_handler.dart` (PingHandler.ping), `lib/src/protocols/protocol_coordinator.dart` (ProtocolCoordinator.stop), `lib/src/protocols/pubsub/gossipsub/gossipsub_pubsub_adapter.dart` (GossipsubPubSubAdapter.stop), `lib/src/routing/content_routing.dart` (ContentRouting.stop)
- **sendMessage** (method) — chama: sendMessage
  - referenciado por (por nome): `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.sendMessage), `lib/src/network/router.dart` (Router.broadcast), `lib/src/protocols/bitswap/bitswap.dart` (Bitswap.send), `lib/src/protocols/dht/dht_client.dart` (DHTClient.storeValueRaw), `lib/src/protocols/graphsync/graphsync_handler.dart` (GraphsyncHandler.pauseRequest), `lib/src/protocols/graphsync/graphsync_handler.dart` (GraphsyncHandler.resumeRequest), `lib/src/protocols/graphsync/graphsync_handler.dart` (GraphsyncHandler.cancelRequest), `lib/src/protocols/identify/identify_push_handler.dart` (IdentifyPushHandler.pushUpdate), `lib/src/protocols/identify/identify_push_handler.dart` (IdentifyPushHandler.pushToPeer), `lib/src/protocols/pubsub/pubsub_client.dart` (PubSubClient.publish), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.reserve), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.connectThroughRelay), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.broadcastMessage), `lib/src/transport/webrtc/webrtc_transport.dart` (WebRTCTransport.dial)
- **broadcast** (method) — chama: sendMessage, encode, Base58, value, id
- **connectToPeer** (method) — chama: connect
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.connectToPeer), `lib/src/core/ipfs_node/network_manager.dart` (NetworkManager.connectToPeer), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleSwarmConnect)
- **disconnectFromPeer** (method) — chama: disconnect
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.disconnectFromPeer), `lib/src/core/ipfs_node/network_manager.dart` (NetworkManager.disconnectFromPeer), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleSwarmDisconnect)

