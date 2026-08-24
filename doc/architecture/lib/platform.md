---
module: platform
kind: lib/src audit
generated: 2026-08-24T07:44:28.499639
---

# Módulo `platform` (`lib/src/platform/`)

_Gerado por `tool/generate_module_index.dart` via AST não-resolvida (`package:analyzer`). "Chama"/"referenciado por" casam por nome de identificador, não por tipo resolvido -- ver aviso no topo do script. Não editar à mão._

Depende de: —

## `lib/src/platform/http_server.dart`

_Testado diretamente._

## `lib/src/platform/http_server_adapter.dart`

Abstract interface for a running HTTP server instance.

_Sem teste direto conhecido._

### abstract class `IpfsHttpServerInstance`

- **close** (method)
  - referenciado por (por nome): `lib/src/core/data_structures/node.dart` (IPFSDataNode.dispose), `lib/src/core/events/event_bus.dart` (EventBus.dispose), `lib/src/core/ipfs_node/datastore_handler.dart` (DatastoreHandler.stop), `lib/src/core/ipfs_node/datastore_handler.dart` (DatastoreHandler.exportCAR), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.stop), `lib/src/core/ipfs_node/ipfs_node_network_events.dart` (IpfsNodeNetworkEvents.dispose), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.stop), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.stop), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.stop), `lib/src/core/metrics/metrics_collector.dart` (MetricsCollector.stop), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.read), `lib/src/core/peering/peering_service.dart` (PeeringService.stop), `lib/src/core/security/denylist_service.dart` (DenylistService.stop), `lib/src/network/router.dart` (Router.stop), `lib/src/platform/http_server_adapter_io.dart` (IpfsHttpServerInstanceIO.close), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.stop), `lib/src/protocols/bitswap/bitswap_session.dart` (BitswapSessionManager.closeSession), `lib/src/protocols/bitswap/bitswap_session.dart` (BitswapSessionManager.stop), `lib/src/protocols/dht/delegate_dht_handler.dart` (DelegateDHTHandler.stop), `lib/src/protocols/graphsync/graphsync_handler.dart` (_ClientRequestContext.complete), `lib/src/protocols/graphsync/graphsync_handler.dart` (_ClientRequestContext.error), `lib/src/protocols/identify/identify_push_handler.dart` (IdentifyPushHandler.stop), `lib/src/protocols/pubsub/gossipsub/gossipsub_handler.dart` (GossipsubHandler.stop), `lib/src/protocols/pubsub/pubsub_client.dart` (PubSubClient.stop), `lib/src/routing/delegated_routing.dart` (DelegatedRoutingHandler.dispose), `lib/src/routing/ipni_client.dart` (IPNIClient.dispose), `lib/src/routing/reframe_routing.dart` (ReframeRoutingClient.dispose), `lib/src/services/gateway/acme_client.dart` (AcmeClient.dispose), `lib/src/services/gateway/domain_validator.dart` (DomainValidator.getPublicIp), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.stop), `lib/src/services/pinning/cluster_client.dart` (IPFSClusterClient.dispose), `lib/src/services/pinning/pinning_service_api.dart` (PinningServiceAPIClient.dispose), `lib/src/services/rpc/rpc_server.dart` (RPCServer.stop), `lib/src/storage/hive_datastore.dart` (HiveDatastore.close), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.stop), `lib/src/transport/circuit_relay_client_web.dart` (CircuitRelayClient.stop), `lib/src/transport/http_gateway_client.dart` (HttpGatewayClient.close), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.stop), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.disconnect), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.sendMessage), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.sendRequest), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.sendMessageWithResponse), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.registerProtocolHandler), `lib/src/transport/pnet/pnet_listener.dart` (PnetListener.close), `lib/src/transport/pnet/pnet_transport_conn.dart` (PnetTransportConn.close), `lib/src/transport/webrtc/data_channel_stream.dart` (DataChannelStream.closeWrite), `lib/src/transport/webrtc/peer_connection_web.dart` (PeerConnectionWeb.close), `lib/src/transport/webrtc/peer_connection_web.dart` (_WebDataChannelStream.close), `lib/src/transport/webrtc/signaling_protocol.dart` (SignalingProtocol.handleStream), `lib/src/transport/webrtc/webrtc_transport.dart` (WebRTCConnection.close), `lib/src/transport/webrtc/webrtc_transport.dart` (WebRTCListener.close), `lib/src/transport/webtransport/webtransport_datagram.dart` (WebTransportDatagram.close), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportDialerWeb.dial), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportConnectionWeb.close), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportStreamWeb.close), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportStreamWeb.closeWrite), `lib/src/transport/webtransport/webtransport_listener.dart` (WebTransportListener.close), `lib/src/transport/webtransport/webtransport_session.dart` (WebTransportSession.close), `lib/src/transport/webtransport/webtransport_session.dart` (WebTransportSessionManager.closeAll)
- **host** (method)
  - referenciado por (por nome): `lib/src/platform/http_server_adapter_io.dart` (IpfsHttpServerInstanceIO.host), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.url), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.url), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.start)
- **port** (method)
  - referenciado por (por nome): `lib/src/core/data_structures/peer.dart` (multiaddrToBytes), `lib/src/platform/http_server_adapter_io.dart` (IpfsHttpServerInstanceIO.port), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.url), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.url), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportDialerWeb.dial)

### abstract class `HttpServerAdapter`

- **serve** (method)
  - referenciado por (por nome): `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start)
- **serveSecure** (method)
  - referenciado por (por nome): `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start)

## `lib/src/platform/http_server_adapter_io.dart`

IO implementation of HTTP server instance.

_Sem teste direto conhecido._

### class `IpfsHttpServerInstanceIO` implements IpfsHttpServerInstance

- **close** (method) — chama: close
  - referenciado por (por nome): `lib/src/core/data_structures/node.dart` (IPFSDataNode.dispose), `lib/src/core/events/event_bus.dart` (EventBus.dispose), `lib/src/core/ipfs_node/datastore_handler.dart` (DatastoreHandler.stop), `lib/src/core/ipfs_node/datastore_handler.dart` (DatastoreHandler.exportCAR), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.stop), `lib/src/core/ipfs_node/ipfs_node_network_events.dart` (IpfsNodeNetworkEvents.dispose), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.stop), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.stop), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.stop), `lib/src/core/metrics/metrics_collector.dart` (MetricsCollector.stop), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.read), `lib/src/core/peering/peering_service.dart` (PeeringService.stop), `lib/src/core/security/denylist_service.dart` (DenylistService.stop), `lib/src/network/router.dart` (Router.stop), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.stop), `lib/src/protocols/bitswap/bitswap_session.dart` (BitswapSessionManager.closeSession), `lib/src/protocols/bitswap/bitswap_session.dart` (BitswapSessionManager.stop), `lib/src/protocols/dht/delegate_dht_handler.dart` (DelegateDHTHandler.stop), `lib/src/protocols/graphsync/graphsync_handler.dart` (_ClientRequestContext.complete), `lib/src/protocols/graphsync/graphsync_handler.dart` (_ClientRequestContext.error), `lib/src/protocols/identify/identify_push_handler.dart` (IdentifyPushHandler.stop), `lib/src/protocols/pubsub/gossipsub/gossipsub_handler.dart` (GossipsubHandler.stop), `lib/src/protocols/pubsub/pubsub_client.dart` (PubSubClient.stop), `lib/src/routing/delegated_routing.dart` (DelegatedRoutingHandler.dispose), `lib/src/routing/ipni_client.dart` (IPNIClient.dispose), `lib/src/routing/reframe_routing.dart` (ReframeRoutingClient.dispose), `lib/src/services/gateway/acme_client.dart` (AcmeClient.dispose), `lib/src/services/gateway/domain_validator.dart` (DomainValidator.getPublicIp), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.stop), `lib/src/services/pinning/cluster_client.dart` (IPFSClusterClient.dispose), `lib/src/services/pinning/pinning_service_api.dart` (PinningServiceAPIClient.dispose), `lib/src/services/rpc/rpc_server.dart` (RPCServer.stop), `lib/src/storage/hive_datastore.dart` (HiveDatastore.close), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.stop), `lib/src/transport/circuit_relay_client_web.dart` (CircuitRelayClient.stop), `lib/src/transport/http_gateway_client.dart` (HttpGatewayClient.close), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.stop), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.disconnect), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.sendMessage), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.sendRequest), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.sendMessageWithResponse), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.registerProtocolHandler), `lib/src/transport/pnet/pnet_listener.dart` (PnetListener.close), `lib/src/transport/pnet/pnet_transport_conn.dart` (PnetTransportConn.close), `lib/src/transport/webrtc/data_channel_stream.dart` (DataChannelStream.closeWrite), `lib/src/transport/webrtc/peer_connection_web.dart` (PeerConnectionWeb.close), `lib/src/transport/webrtc/peer_connection_web.dart` (_WebDataChannelStream.close), `lib/src/transport/webrtc/signaling_protocol.dart` (SignalingProtocol.handleStream), `lib/src/transport/webrtc/webrtc_transport.dart` (WebRTCConnection.close), `lib/src/transport/webrtc/webrtc_transport.dart` (WebRTCListener.close), `lib/src/transport/webtransport/webtransport_datagram.dart` (WebTransportDatagram.close), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportDialerWeb.dial), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportConnectionWeb.close), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportStreamWeb.close), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportStreamWeb.closeWrite), `lib/src/transport/webtransport/webtransport_listener.dart` (WebTransportListener.close), `lib/src/transport/webtransport/webtransport_session.dart` (WebTransportSession.close), `lib/src/transport/webtransport/webtransport_session.dart` (WebTransportSessionManager.closeAll)
- **host** (method) — chama: host, address
  - referenciado por (por nome): `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.url), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.url), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.start)
- **port** (method) — chama: port
  - referenciado por (por nome): `lib/src/core/data_structures/peer.dart` (multiaddrToBytes), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.url), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.url), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportDialerWeb.dial)

### class `HttpServerAdapterIO` implements HttpServerAdapter

- **serve** (method) — chama: bind, serveRequests, IpfsHttpServerInstanceIO
  - referenciado por (por nome): `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start)
- **serveSecure** (method) — chama: bindSecure, serveRequests, IpfsHttpServerInstanceIO
  - referenciado por (por nome): `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start)

### top-level `createHttpServerAdapter` (function)

- **createHttpServerAdapter** (function) — chama: HttpServerAdapterIO
  - referenciado por (por nome): `lib/src/services/rpc/rpc_server.dart` (RPCServer.start)

## `lib/src/platform/http_server_adapter_stub.dart`

Stub implementation of HTTP server adapter for unsupported platforms.

_Sem teste direto conhecido._

### class `HttpServerAdapterStub` implements HttpServerAdapter

- **serve** (method) — chama: UnimplementedError
  - referenciado por (por nome): `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start)
- **serveSecure** (method) — chama: UnimplementedError
  - referenciado por (por nome): `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start)

### top-level `createHttpServerAdapter` (function)

- **createHttpServerAdapter** (function) — chama: HttpServerAdapterStub
  - referenciado por (por nome): `lib/src/services/rpc/rpc_server.dart` (RPCServer.start)

## `lib/src/platform/http_server_adapter_web.dart`

Web stub implementation of HTTP server instance.

_Sem teste direto conhecido._

### class `IpfsHttpServerInstanceWeb` implements IpfsHttpServerInstance

- **close** (method)
  - referenciado por (por nome): `lib/src/core/data_structures/node.dart` (IPFSDataNode.dispose), `lib/src/core/events/event_bus.dart` (EventBus.dispose), `lib/src/core/ipfs_node/datastore_handler.dart` (DatastoreHandler.stop), `lib/src/core/ipfs_node/datastore_handler.dart` (DatastoreHandler.exportCAR), `lib/src/core/ipfs_node/ipfs_node.dart` (IPFSNode.stop), `lib/src/core/ipfs_node/ipfs_node_network_events.dart` (IpfsNodeNetworkEvents.dispose), `lib/src/core/ipfs_node/mdns_handler.dart` (MDNSHandler.stop), `lib/src/core/ipfs_node/network_handler_io.dart` (NetworkHandler.stop), `lib/src/core/ipfs_node/pubsub_handler.dart` (PubSubHandler.stop), `lib/src/core/metrics/metrics_collector.dart` (MetricsCollector.stop), `lib/src/core/mfs/mfs_manager.dart` (MFSManager.read), `lib/src/core/peering/peering_service.dart` (PeeringService.stop), `lib/src/core/security/denylist_service.dart` (DenylistService.stop), `lib/src/network/router.dart` (Router.stop), `lib/src/platform/http_server_adapter_io.dart` (IpfsHttpServerInstanceIO.close), `lib/src/protocols/bitswap/bitswap_handler.dart` (BitswapHandler.stop), `lib/src/protocols/bitswap/bitswap_session.dart` (BitswapSessionManager.closeSession), `lib/src/protocols/bitswap/bitswap_session.dart` (BitswapSessionManager.stop), `lib/src/protocols/dht/delegate_dht_handler.dart` (DelegateDHTHandler.stop), `lib/src/protocols/graphsync/graphsync_handler.dart` (_ClientRequestContext.complete), `lib/src/protocols/graphsync/graphsync_handler.dart` (_ClientRequestContext.error), `lib/src/protocols/identify/identify_push_handler.dart` (IdentifyPushHandler.stop), `lib/src/protocols/pubsub/gossipsub/gossipsub_handler.dart` (GossipsubHandler.stop), `lib/src/protocols/pubsub/pubsub_client.dart` (PubSubClient.stop), `lib/src/routing/delegated_routing.dart` (DelegatedRoutingHandler.dispose), `lib/src/routing/ipni_client.dart` (IPNIClient.dispose), `lib/src/routing/reframe_routing.dart` (ReframeRoutingClient.dispose), `lib/src/services/gateway/acme_client.dart` (AcmeClient.dispose), `lib/src/services/gateway/domain_validator.dart` (DomainValidator.getPublicIp), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.stop), `lib/src/services/pinning/cluster_client.dart` (IPFSClusterClient.dispose), `lib/src/services/pinning/pinning_service_api.dart` (PinningServiceAPIClient.dispose), `lib/src/services/rpc/rpc_server.dart` (RPCServer.stop), `lib/src/storage/hive_datastore.dart` (HiveDatastore.close), `lib/src/transport/circuit_relay_client_io.dart` (CircuitRelayClient.stop), `lib/src/transport/circuit_relay_client_web.dart` (CircuitRelayClient.stop), `lib/src/transport/http_gateway_client.dart` (HttpGatewayClient.close), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.stop), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.disconnect), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.sendMessage), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.sendRequest), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.sendMessageWithResponse), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.registerProtocolHandler), `lib/src/transport/pnet/pnet_listener.dart` (PnetListener.close), `lib/src/transport/pnet/pnet_transport_conn.dart` (PnetTransportConn.close), `lib/src/transport/webrtc/data_channel_stream.dart` (DataChannelStream.closeWrite), `lib/src/transport/webrtc/peer_connection_web.dart` (PeerConnectionWeb.close), `lib/src/transport/webrtc/peer_connection_web.dart` (_WebDataChannelStream.close), `lib/src/transport/webrtc/signaling_protocol.dart` (SignalingProtocol.handleStream), `lib/src/transport/webrtc/webrtc_transport.dart` (WebRTCConnection.close), `lib/src/transport/webrtc/webrtc_transport.dart` (WebRTCListener.close), `lib/src/transport/webtransport/webtransport_datagram.dart` (WebTransportDatagram.close), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportDialerWeb.dial), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportConnectionWeb.close), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportStreamWeb.close), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportStreamWeb.closeWrite), `lib/src/transport/webtransport/webtransport_listener.dart` (WebTransportListener.close), `lib/src/transport/webtransport/webtransport_session.dart` (WebTransportSession.close), `lib/src/transport/webtransport/webtransport_session.dart` (WebTransportSessionManager.closeAll)
- **host** (method)
  - referenciado por (por nome): `lib/src/platform/http_server_adapter_io.dart` (IpfsHttpServerInstanceIO.host), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.url), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.url), `lib/src/transport/libp2p_router.dart` (Libp2pRouter.start)
- **port** (method)
  - referenciado por (por nome): `lib/src/core/data_structures/peer.dart` (multiaddrToBytes), `lib/src/platform/http_server_adapter_io.dart` (IpfsHttpServerInstanceIO.port), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/gateway/gateway_server.dart` (GatewayServer.url), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.url), `lib/src/transport/webtransport/webtransport_dialer_web.dart` (WebTransportDialerWeb.dial)

### class `HttpServerAdapterWeb` implements HttpServerAdapter

- **serve** (method) — chama: IpfsHttpServerInstanceWeb
  - referenciado por (por nome): `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start), `lib/src/services/rpc/rpc_server.dart` (RPCServer.start)
- **serveSecure** (method) — chama: UnimplementedError
  - referenciado por (por nome): `lib/src/services/gateway/gateway_server.dart` (GatewayServer.start)

### top-level `createHttpServerAdapter` (function)

- **createHttpServerAdapter** (function) — chama: HttpServerAdapterWeb
  - referenciado por (por nome): `lib/src/services/rpc/rpc_server.dart` (RPCServer.start)

## `lib/src/platform/libsodium_setup.dart`

_Sem teste direto conhecido._

## `lib/src/platform/libsodium_setup_io.dart`

Helper for ensuring libsodium is available before P2P initialization.

_Sem teste direto conhecido._

### class `LibsodiumSetup`

- **ensureAvailable** (method) — chama: isWindows, _checkNonWindows, _isInstalled, writeln, _printInstallInstructions, _attemptInstall

## `lib/src/platform/libsodium_setup_stub.dart`

Helper for ensuring libsodium is available before P2P initialization.

_Sem teste direto conhecido._

### class `LibsodiumSetup`

- **ensureAvailable** (method)

## `lib/src/platform/platform.dart`

_Testado diretamente._

## `lib/src/platform/platform_io.dart`

IO implementation of the IPFS platform interface.

_Testado diretamente._

### class `IpfsPlatformIO` implements IpfsPlatform

- **isWeb** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.addFile)
- **isIO** (method)
- **pathSeparator** (method) — chama: pathSeparator
- **operatingSystem** (method) — chama: operatingSystem
  - referenciado por (por nome): `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleVersion)
- **version** (method) — chama: version
  - referenciado por (por nome): `lib/src/core/cid.dart` (CID.==), `lib/src/core/cid.dart` (CID.toProto), `lib/src/core/cid.dart` (CID.fromProto), `lib/src/core/data_structures/car.dart` (CarHeader.==), `lib/src/protocols/bitswap/message.dart` (Message.toBytes), `lib/src/services/content_service.dart` (ContentService.storeContent), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleVersion)
- **writeBytes** (method) — chama: File, create, parent, writeAsBytes
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.putBlock), `lib/src/core/data_structures/pin_manager.dart` (PinManager.save), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.pin), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.putBlock), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.put), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.writeString), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.cachePreview)
- **writeString** (method) — chama: File, create, parent, writeAsString
- **readBytes** (method) — chama: File, exists, readAsBytes
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.getBlock), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.getBlock), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.hasBlock), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.getAllBlocks), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.get), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.query), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.readString), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.getLength), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressedData), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.getPreview)
- **readString** (method) — chama: File, exists, readAsString
  - referenciado por (por nome): `lib/src/core/config/ipfs_config.dart` (IPFSConfig.fromFile), `lib/src/core/data_structures/pin_manager.dart` (PinManager.load), `lib/src/transport/pnet/swarm_key_loader.dart` (loadSwarmKey)
- **exists** (method) — chama: exists, File, Directory
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.getBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.putBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.removeBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.hasBlock), `lib/src/core/data_structures/pin_manager.dart` (PinManager.load), `lib/src/core/plugins/plugin_host.dart` (PluginHost.loadPluginFromDirectory), `lib/src/core/security/denylist_service.dart` (DenylistService.loadFromPath), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.init), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.has), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.delete), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.readBytes), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.readString), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.listDirectory), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressedData), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.getPreview), `lib/src/services/pinning/remote_pinning_service.dart` (RemotePinningService.load)
- **delete** (method) — chama: type, file, delete, File, directory, Directory
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.removeBlock), `lib/src/core/ipfs_node/content_manager.dart` (ContentManager.unpin), `lib/src/core/ipfs_node/datastore_handler.dart` (DatastoreHandler.persistPinnedCIDs), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.unpin), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.removeBlock), `lib/src/core/repository/repository.dart` (Repository.removeBlock), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.delete), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.delete), `lib/src/services/content_service.dart` (ContentService.removeContent), `lib/src/services/content_service.dart` (ContentService.unpinContent), `lib/src/services/gateway/acme_persistence.dart` (AcmePersistence.deleteAll), `lib/src/services/gateway/gateway_tls_manager.dart` (LetsEncryptAutoTlsProvider.obtainCertificate), `lib/src/services/pinning/cluster_client.dart` (IPFSClusterClient.unpin), `lib/src/services/pinning/pinning_service_api.dart` (PinningServiceAPIClient.removePin), `lib/src/storage/hive_datastore.dart` (HiveDatastore.delete)
- **createDirectory** (method) — chama: create, Directory
  - referenciado por (por nome): `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.init), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.createTempDirectory)
- **createTempDirectory** (method) — chama: createTemp, systemTemp, path
- **listDirectory** (method) — chama: Directory, exists, toList, list, map, replaceAll, path
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.listPins), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.getAllBlocks), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.query), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressionStats)
- **getLength** (method) — chama: length, File
- **promptPassword** (method) — chama: hasTerminal, write, echoMode, readLineSync, writeln
  - referenciado por (por nome): `lib/src/utils/password_prompt.dart` (PasswordPrompt.prompt)

### top-level `getPlatform` (function)

- **getPlatform** (function) — chama: IpfsPlatformIO
  - referenciado por (por nome): `lib/src/core/config/ipfs_config.dart` (IPFSConfig.fromFile), `lib/src/core/data_structures/blockstore.dart` (BlockStore.getBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.putBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.removeBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.hasBlock), `lib/src/core/data_structures/pin_manager.dart` (PinManager.load), `lib/src/core/data_structures/pin_manager.dart` (PinManager.save), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressedData), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressionStats), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.getPreview), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.cachePreview), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleVersion), `lib/src/transport/pnet/swarm_key_loader.dart` (loadSwarmKey), `lib/src/utils/password_prompt.dart` (PasswordPrompt.prompt)

## `lib/src/platform/platform_stub.dart`

Abstract class representing platform-specific operations.

_Testado diretamente._

### abstract class `IpfsPlatform`

- **isWeb** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.addFile)
- **isIO** (method)
- **writeBytes** (method)
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.putBlock), `lib/src/core/data_structures/pin_manager.dart` (PinManager.save), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.pin), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.putBlock), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.put), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.writeString), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.cachePreview)
- **writeString** (method)
- **readBytes** (method)
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.getBlock), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.getBlock), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.hasBlock), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.getAllBlocks), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.get), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.query), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.readString), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.getLength), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressedData), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.getPreview)
- **readString** (method)
  - referenciado por (por nome): `lib/src/core/config/ipfs_config.dart` (IPFSConfig.fromFile), `lib/src/core/data_structures/pin_manager.dart` (PinManager.load), `lib/src/transport/pnet/swarm_key_loader.dart` (loadSwarmKey)
- **exists** (method)
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.getBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.putBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.removeBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.hasBlock), `lib/src/core/data_structures/pin_manager.dart` (PinManager.load), `lib/src/core/plugins/plugin_host.dart` (PluginHost.loadPluginFromDirectory), `lib/src/core/security/denylist_service.dart` (DenylistService.loadFromPath), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.init), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.has), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.delete), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.readBytes), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.readString), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.exists), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.listDirectory), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressedData), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.getPreview), `lib/src/services/pinning/remote_pinning_service.dart` (RemotePinningService.load)
- **delete** (method)
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.removeBlock), `lib/src/core/ipfs_node/content_manager.dart` (ContentManager.unpin), `lib/src/core/ipfs_node/datastore_handler.dart` (DatastoreHandler.persistPinnedCIDs), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.unpin), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.removeBlock), `lib/src/core/repository/repository.dart` (Repository.removeBlock), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.delete), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.delete), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.delete), `lib/src/services/content_service.dart` (ContentService.removeContent), `lib/src/services/content_service.dart` (ContentService.unpinContent), `lib/src/services/gateway/acme_persistence.dart` (AcmePersistence.deleteAll), `lib/src/services/gateway/gateway_tls_manager.dart` (LetsEncryptAutoTlsProvider.obtainCertificate), `lib/src/services/pinning/cluster_client.dart` (IPFSClusterClient.unpin), `lib/src/services/pinning/pinning_service_api.dart` (PinningServiceAPIClient.removePin), `lib/src/storage/hive_datastore.dart` (HiveDatastore.delete)
- **createDirectory** (method)
  - referenciado por (por nome): `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.init), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.createTempDirectory)
- **createTempDirectory** (method)
- **listDirectory** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.listPins), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.getAllBlocks), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.query), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressionStats)
- **getLength** (method)
- **operatingSystem** (method)
  - referenciado por (por nome): `lib/src/platform/platform_io.dart` (IpfsPlatformIO.operatingSystem), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleVersion)
- **version** (method)
  - referenciado por (por nome): `lib/src/core/cid.dart` (CID.==), `lib/src/core/cid.dart` (CID.toProto), `lib/src/core/cid.dart` (CID.fromProto), `lib/src/core/data_structures/car.dart` (CarHeader.==), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.version), `lib/src/protocols/bitswap/message.dart` (Message.toBytes), `lib/src/services/content_service.dart` (ContentService.storeContent), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleVersion)
- **promptPassword** (method)
  - referenciado por (por nome): `lib/src/utils/password_prompt.dart` (PasswordPrompt.prompt)
- **pathSeparator** (method)
  - referenciado por (por nome): `lib/src/platform/platform_io.dart` (IpfsPlatformIO.pathSeparator)

### top-level `getPlatform` (function)

- **getPlatform** (function) — chama: UnsupportedError
  - referenciado por (por nome): `lib/src/core/config/ipfs_config.dart` (IPFSConfig.fromFile), `lib/src/core/data_structures/blockstore.dart` (BlockStore.getBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.putBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.removeBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.hasBlock), `lib/src/core/data_structures/pin_manager.dart` (PinManager.load), `lib/src/core/data_structures/pin_manager.dart` (PinManager.save), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressedData), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressionStats), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.getPreview), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.cachePreview), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleVersion), `lib/src/transport/pnet/swarm_key_loader.dart` (loadSwarmKey), `lib/src/utils/password_prompt.dart` (PasswordPrompt.prompt)

## `lib/src/platform/platform_web.dart`

Web implementation of the IPFS platform interface using IndexedDB.

_Sem teste direto conhecido._

### class `IpfsPlatformWeb` implements IpfsPlatform

- **isWeb** (method)
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.addFile)
- **isIO** (method)
- **pathSeparator** (method)
  - referenciado por (por nome): `lib/src/platform/platform_io.dart` (IpfsPlatformIO.pathSeparator)
- **operatingSystem** (method)
  - referenciado por (por nome): `lib/src/platform/platform_io.dart` (IpfsPlatformIO.operatingSystem), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleVersion)
- **version** (method)
  - referenciado por (por nome): `lib/src/core/cid.dart` (CID.==), `lib/src/core/cid.dart` (CID.toProto), `lib/src/core/cid.dart` (CID.fromProto), `lib/src/core/data_structures/car.dart` (CarHeader.==), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.version), `lib/src/protocols/bitswap/message.dart` (Message.toBytes), `lib/src/services/content_service.dart` (ContentService.storeContent), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleVersion)
- **writeBytes** (method) — chama: _getDb, transaction, objectStore, put, completed
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.putBlock), `lib/src/core/data_structures/pin_manager.dart` (PinManager.save), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.pin), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.putBlock), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.put), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.writeString), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.cachePreview)
- **writeString** (method) — chama: fromList, codeUnits, writeBytes
- **readBytes** (method) — chama: _getDb, transaction, objectStore, getObject, fromList
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.getBlock), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.getBlock), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.hasBlock), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.getAllBlocks), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.get), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.query), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.readString), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.getLength), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressedData), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.getPreview)
- **readString** (method) — chama: readBytes, fromCharCodes
  - referenciado por (por nome): `lib/src/core/config/ipfs_config.dart` (IPFSConfig.fromFile), `lib/src/core/data_structures/pin_manager.dart` (PinManager.load), `lib/src/transport/pnet/swarm_key_loader.dart` (loadSwarmKey)
- **exists** (method) — chama: _getDb, transaction, objectStore, count, lowerBound, Completer, listen, openCursor, startsWith, toString, key, complete, isCompleted, future
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.getBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.putBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.removeBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.hasBlock), `lib/src/core/data_structures/pin_manager.dart` (PinManager.load), `lib/src/core/plugins/plugin_host.dart` (PluginHost.loadPluginFromDirectory), `lib/src/core/security/denylist_service.dart` (DenylistService.loadFromPath), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.init), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.has), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.delete), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.readBytes), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.readString), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.exists), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.listDirectory), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressedData), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.getPreview), `lib/src/services/pinning/remote_pinning_service.dart` (RemotePinningService.load)
- **delete** (method) — chama: _getDb, transaction, objectStore, delete, lowerBound, Completer, listen, openKeyCursor, startsWith, toString, key, next, complete, isCompleted, future, completed
  - referenciado por (por nome): `lib/src/core/data_structures/blockstore.dart` (BlockStore.removeBlock), `lib/src/core/ipfs_node/content_manager.dart` (ContentManager.unpin), `lib/src/core/ipfs_node/datastore_handler.dart` (DatastoreHandler.persistPinnedCIDs), `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.unpin), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.removeBlock), `lib/src/core/repository/repository.dart` (Repository.removeBlock), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.delete), `lib/src/platform/platform_io.dart` (IpfsPlatformIO.delete), `lib/src/services/content_service.dart` (ContentService.removeContent), `lib/src/services/content_service.dart` (ContentService.unpinContent), `lib/src/services/gateway/acme_persistence.dart` (AcmePersistence.deleteAll), `lib/src/services/gateway/gateway_tls_manager.dart` (LetsEncryptAutoTlsProvider.obtainCertificate), `lib/src/services/pinning/cluster_client.dart` (IPFSClusterClient.unpin), `lib/src/services/pinning/pinning_service_api.dart` (PinningServiceAPIClient.removePin), `lib/src/storage/hive_datastore.dart` (HiveDatastore.delete)
- **createDirectory** (method)
  - referenciado por (por nome): `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.init), `lib/src/platform/platform_web.dart` (IpfsPlatformWeb.createTempDirectory)
- **createTempDirectory** (method) — chama: millisecondsSinceEpoch, now, createDirectory
- **listDirectory** (method) — chama: _getDb, transaction, objectStore, endsWith, Completer, lowerBound, listen, openKeyCursor, toString, key, startsWith, add, next, complete, isCompleted, future
  - referenciado por (por nome): `lib/src/core/ipfs_node/ipfs_web_node.dart` (IPFSWebNode.listPins), `lib/src/core/ipfs_node/web_block_store.dart` (WebBlockStore.getAllBlocks), `lib/src/core/storage/flat_file_datastore.dart` (FlatFileDatastore.query), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressionStats)
- **getLength** (method) — chama: readBytes, length
- **promptPassword** (method)
  - referenciado por (por nome): `lib/src/utils/password_prompt.dart` (PasswordPrompt.prompt)

### top-level `getPlatform` (function)

- **getPlatform** (function) — chama: IpfsPlatformWeb
  - referenciado por (por nome): `lib/src/core/config/ipfs_config.dart` (IPFSConfig.fromFile), `lib/src/core/data_structures/blockstore.dart` (BlockStore.getBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.putBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.removeBlock), `lib/src/core/data_structures/blockstore.dart` (BlockStore.hasBlock), `lib/src/core/data_structures/pin_manager.dart` (PinManager.load), `lib/src/core/data_structures/pin_manager.dart` (PinManager.save), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressedData), `lib/src/services/gateway/compressed_cache_store.dart` (CompressedCacheStore.getCompressionStats), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.getPreview), `lib/src/services/gateway/persistent_preview_cache.dart` (PersistentPreviewCache.cachePreview), `lib/src/services/rpc/rpc_handlers.dart` (RPCHandlers.handleVersion), `lib/src/transport/pnet/swarm_key_loader.dart` (loadSwarmKey), `lib/src/utils/password_prompt.dart` (PasswordPrompt.prompt)

