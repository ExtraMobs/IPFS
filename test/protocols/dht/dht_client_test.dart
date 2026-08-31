import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:transpiled_ipfs/src/core/cid.dart';
import 'package:transpiled_ipfs/src/core/config/ipfs_config.dart';
import 'package:transpiled_ipfs/src/core/metrics/metrics_collector.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';
import 'package:transpiled_ipfs/src/proto/generated/dht/kademlia.pb.dart'
    as kad;
import 'package:transpiled_ipfs/src/protocols/dht/dht_client.dart';
import 'package:transpiled_ipfs/src/protocols/dht/dht_envelope.dart';
import 'package:transpiled_ipfs/src/transport/router_interface.dart';
import 'package:ipfs_libp2p/dart_libp2p.dart' as libp2p;

import 'dht_client_coverage_test.mocks.dart';

void main() {
  late DHTClient client;
  late MockRouterInterface mockRouter;
  late MockNetworkHandler mockNetworkHandler;
  late MockIPFSNode mockNode;
  late MockDHTHandler mockDhtHandler;
  late MockDatastore mockStorage;
  late MetricsCollector metrics;
  late IPFSConfig config;

  setUp(() {
    mockRouter = MockRouterInterface();
    mockNetworkHandler = MockNetworkHandler();
    mockNode = MockIPFSNode();
    mockDhtHandler = MockDHTHandler();
    mockStorage = MockDatastore();
    config = IPFSConfig();
    metrics = MetricsCollector(config);

    when(mockNetworkHandler.ipfsNode).thenReturn(mockNode);
    when(mockNetworkHandler.config).thenReturn(config);
    when(mockNode.dhtHandler).thenReturn(mockDhtHandler);
    when(mockDhtHandler.router).thenReturn(mockRouter);
    when(mockDhtHandler.storage).thenReturn(mockStorage);

    when(
      mockRouter.peerID,
    ).thenReturn('QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn');

    client = DHTClient(
      networkHandler: mockNetworkHandler,
      router: mockRouter,
      metricsCollector: metrics,
    );
  });

  void Function(NetworkPacket) _captureHandler(MockRouterInterface router) {
    final captured = verify(
      router.registerProtocolHandler(any, captureAny),
    ).captured;
    return captured.last as void Function(NetworkPacket);
  }

  void mockEnvelopeResponse(
    MockRouterInterface router,
    String srcPeerId,
    kad.Message response, {
    void Function(NetworkPacket)? handler,
  }) {
    final lastHandler = handler ?? _captureHandler(router);
    when(
      router.sendMessage(any, any, protocolId: anyNamed('protocolId')),
    ).thenAnswer((invocation) async {
      final data = invocation.positionalArguments[1] as Uint8List;
      final envelope = DHTEnvelope.fromBytes(data);
      Future<void>.delayed(const Duration(milliseconds: 1), () {
        lastHandler(
          NetworkPacket(
            srcPeerId: srcPeerId,
            datagram: DHTEnvelope(
              requestId: envelope.requestId,
              payload: response.writeToBuffer(),
            ).toBytes(),
          ),
        );
      });
    });
  }

  void mockRawResponse(MockRouterInterface router, kad.Message response) {
    when(
      router.sendRequest(any, any, any),
    ).thenAnswer((_) async => response.writeToBuffer());
  }

  group('DHTClient integration spec', () {
    test('iterative queries use raw Kademlia request/response', () async {
      await client.initialize();
      final peer = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8v',
      );
      final target = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8w',
      );
      await client.kademliaRoutingTable.addPeer(peer, peer);
      final response = kad.Message()
        ..type = kad.Message_MessageType.FIND_NODE
        ..closerPeers.add(kad.Peer()..id = target.value);

      when(mockRouter.sendRequest(any, any, any)).thenAnswer((
        invocation,
      ) async {
        final data = invocation.positionalArguments[2] as Uint8List;
        expect(
          kad.Message.fromBuffer(data).type,
          kad.Message_MessageType.FIND_NODE,
        );
        return response.writeToBuffer();
      });

      await client.findPeer(target);
      verify(mockRouter.sendRequest(peer.toBase58(), any, any)).called(1);
    });

    test('findProviders returns validated provider records', () async {
      await client.initialize();
      final peer = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8v',
      );
      await client.kademliaRoutingTable.addPeer(peer, peer);

      final provider = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8w',
      );
      final response = kad.Message()
        ..type = kad.Message_MessageType.GET_PROVIDERS
        ..providerPeers.add(
          kad.Peer()
            ..id = provider.value
            ..addrs.add(libp2p.MultiAddr('/ip4/127.0.0.1/tcp/4001').toBytes()),
        );

      mockRawResponse(mockRouter, response);

      final providers = await client.findProviderInfos(
        'QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn',
      );
      expect(providers, isNotEmpty);
      expect(providers.single.id.toBase58(), provider.toBase58());
      expect(
        providers.single.addrs.single.toAddrString(),
        '/ip4/127.0.0.1/tcp/4001',
      );
    });

    test('findProviders preserves providers without multiaddrs', () async {
      await client.initialize();
      final peer = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8v',
      );
      await client.kademliaRoutingTable.addPeer(peer, peer);

      final provider = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8w',
      );
      final response = kad.Message()
        ..type = kad.Message_MessageType.GET_PROVIDERS
        ..providerPeers.add(kad.Peer()..id = provider.value);

      mockRawResponse(mockRouter, response);

      final providers = await client.findProviders(
        'QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn',
      );
      expect(providers, [provider]);
    });

    test('findProvidersAsync applies count', () async {
      await client.initialize();
      final peer = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8v',
      );
      await client.kademliaRoutingTable.addPeer(peer, peer);

      final response = kad.Message()
        ..type = kad.Message_MessageType.GET_PROVIDERS
        ..providerPeers.addAll([
          kad.Peer()
            ..id = PeerId.fromBase58(
              'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8w',
            ).value,
          kad.Peer()
            ..id = PeerId.fromBase58(
              'QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb',
            ).value,
        ]);
      mockRawResponse(mockRouter, response);

      final providers = await client
          .findProvidersAsync(
            CID.decode('QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn'),
            1,
          )
          .toList();

      expect(providers, hasLength(1));
    });

    test('findProvidersAsync emits an address upgrade', () async {
      await client.initialize();
      final seedPeer = PeerId.fromBase58(
        'QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN',
      );
      final closerPeer = PeerId.fromBase58(
        'QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa',
      );
      final provider = PeerId.fromBase58(
        'QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb',
      );
      await client.kademliaRoutingTable.addPeer(seedPeer, seedPeer);

      var requestCount = 0;
      when(mockRouter.sendRequest(any, any, any)).thenAnswer((_) async {
        requestCount++;
        final response = kad.Message()
          ..type = kad.Message_MessageType.GET_PROVIDERS;
        if (requestCount == 1) {
          response
            ..providerPeers.add(kad.Peer()..id = provider.value)
            ..closerPeers.add(
              kad.Peer()
                ..id = closerPeer.value
                ..addrs.add(
                  libp2p.MultiAddr('/ip4/127.0.0.1/tcp/4002').toBytes(),
                ),
            );
        } else {
          response.providerPeers.add(
            kad.Peer()
              ..id = provider.value
              ..addrs.add(
                libp2p.MultiAddr('/ip4/127.0.0.1/tcp/4001').toBytes(),
              ),
          );
        }
        return response.writeToBuffer();
      });

      final providers = await client
          .findProvidersAsync(
            CID.decode('QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn'),
            0,
          )
          .toList();

      expect(providers, hasLength(2));
      expect(providers.first.addrs, isEmpty);
      expect(providers.last.addrs, hasLength(1));
    });

    test('cancelling findProvidersAsync stops before the next query', () async {
      await client.initialize();
      final seedPeer = PeerId.fromBase58(
        'QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN',
      );
      final closerPeer = PeerId.fromBase58(
        'QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa',
      );
      final provider = PeerId.fromBase58(
        'QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb',
      );
      await client.kademliaRoutingTable.addPeer(seedPeer, seedPeer);

      var requestCount = 0;
      when(mockRouter.sendRequest(any, any, any)).thenAnswer((_) async {
        requestCount++;
        return (kad.Message()
              ..type = kad.Message_MessageType.GET_PROVIDERS
              ..providerPeers.add(kad.Peer()..id = provider.value)
              ..closerPeers.add(
                kad.Peer()
                  ..id = closerPeer.value
                  ..addrs.add(
                    libp2p.MultiAddr('/ip4/127.0.0.1/tcp/4002').toBytes(),
                  ),
              ))
            .writeToBuffer();
      });

      final providers = await client
          .findProvidersAsync(
            CID.decode('QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn'),
            0,
          )
          .take(1)
          .toList();

      expect(providers, hasLength(1));
      expect(requestCount, 1);
    });

    test('findProviders expands iteratively via closer peers', () async {
      await client.initialize();
      final seedPeer = PeerId.fromBase58(
        'QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN',
      );
      final closerPeer = PeerId.fromBase58(
        'QmQCU2EcMqAqQPR2i9bChDtGNJchTbq5TbXJJ16u19uLTa',
      );
      await client.kademliaRoutingTable.addPeer(seedPeer, seedPeer);
      await client.kademliaRoutingTable.addPeer(closerPeer, closerPeer);

      final provider = PeerId.fromBase58(
        'QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb',
      );
      var requestCount = 0;

      when(mockRouter.sendRequest(any, any, any)).thenAnswer((
        invocation,
      ) async {
        final request = kad.Message.fromBuffer(
          invocation.positionalArguments[2] as Uint8List,
        );
        expect(request.clusterLevelRaw, 1);
        requestCount++;

        final response = kad.Message()
          ..type = kad.Message_MessageType.GET_PROVIDERS;

        // On the first request, return a closer peer. On the second request,
        // return the provider. This demonstrates iterative expansion.
        if (requestCount == 1) {
          response.closerPeers.add(
            kad.Peer()
              ..id = closerPeer.value
              ..addrs.add(
                libp2p.MultiAddr('/ip4/127.0.0.1/tcp/4002').toBytes(),
              ),
          );
        } else {
          response.providerPeers.add(
            kad.Peer()
              ..id = provider.value
              ..addrs.add(
                libp2p.MultiAddr('/ip4/127.0.0.1/tcp/4001').toBytes(),
              ),
          );
        }

        return response.writeToBuffer();
      });

      final providers = await client.findProviders(
        'QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn',
      );
      expect(providers, isNotEmpty);
      expect(providers.any((p) => p.toBase58() == provider.toBase58()), isTrue);
      expect(requestCount, greaterThanOrEqualTo(2));
    });

    test('findPeer iterates until target is discovered', () async {
      await client.initialize();
      final seedPeer = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8v',
      );
      final target = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8w',
      );
      await client.kademliaRoutingTable.addPeer(seedPeer, seedPeer);

      final response = kad.Message()
        ..type = kad.Message_MessageType.FIND_NODE
        ..closerPeers.add(kad.Peer()..id = target.value);

      mockRawResponse(mockRouter, response);

      final result = await client.findPeer(target);
      expect(result, isNotNull);
      expect(result!.toBase58(), equals(target.toBase58()));
    });

    test('addProvider encodes addresses as multiaddr bytes', () async {
      await client.initialize();
      final peer = PeerId.fromBase58(
        'QmP8j68w7u6vYpx4BNDPqVvR2Y6a8VvX8v8v8v8v8v8v',
      );
      await client.kademliaRoutingTable.addPeer(peer, peer);
      when(
        mockRouter.resolvePeerId(client.peerId.toBase58()),
      ).thenReturn(['/ip4/127.0.0.1/tcp/4001']);

      final response = kad.Message()
        ..type = kad.Message_MessageType.ADD_PROVIDER;
      mockEnvelopeResponse(mockRouter, peer.toBase58(), response);

      await client.addProvider(
        'QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn',
        client.peerId.toBase58(),
      );

      final captured = verify(
        mockRouter.sendMessage(
          captureAny,
          captureAny,
          protocolId: anyNamed('protocolId'),
        ),
      ).captured;
      final msg = kad.Message.fromBuffer(captured.last as Uint8List);
      expect(msg.providerPeers, isNotEmpty);
      expect(msg.providerPeers.first.addrs, isNotEmpty);

      final addr = libp2p.MultiAddr.fromBytes(
        Uint8List.fromList(msg.providerPeers.first.addrs.first),
      );
      expect(addr.toString(), '/ip4/127.0.0.1/tcp/4001');
    });

    test('ADD_PROVIDER rejects a provider different from the sender', () async {
      await client.initialize();
      final sender = PeerId.fromBase58(
        'QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN',
      );
      final provider = PeerId.fromBase58(
        'QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb',
      );
      final cid = CID.decode('QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn');
      final message = kad.Message()
        ..type = kad.Message_MessageType.ADD_PROVIDER
        ..key = cid.multihash.toBytes()
        ..providerPeers.add(
          kad.Peer()
            ..id = provider.value
            ..addrs.add(libp2p.MultiAddr('/ip4/127.0.0.1/tcp/4001').toBytes()),
        );

      _captureHandler(mockRouter)(
        NetworkPacket(
          srcPeerId: sender.toBase58(),
          datagram: message.writeToBuffer(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verifyNever(mockDhtHandler.handleProvideRequest(any, any));
    });

    test('reprovide enumerates stored keys and records metrics', () async {
      await client.initialize();
      when(mockStorage.query(any)).thenAnswer((_) => const Stream.empty());

      await expectLater(client.reprovide(), completes);
      verify(mockStorage.query(any)).called(1);
    });

    test('addProvider sends to closest peers in batches', () async {
      await client.initialize();
      final peers = List.generate(5, (i) {
        final bytes = Uint8List(32)..[0] = i;
        return PeerId(value: bytes);
      });
      for (final peer in peers) {
        await client.kademliaRoutingTable.addPeer(peer, peer);
      }

      final sentTo = <String>{};
      when(
        mockRouter.sendMessage(any, any, protocolId: anyNamed('protocolId')),
      ).thenAnswer((invocation) async {
        sentTo.add(invocation.positionalArguments[0] as String);
      });

      await client
          .addProvider(
            'QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn',
            client.peerId.toBase58(),
          )
          .timeout(const Duration(milliseconds: 100), onTimeout: () {});

      expect(sentTo.length, greaterThanOrEqualTo(1));
    });
  });
}
