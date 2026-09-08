import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ipfs_libp2p/core/network/context.dart';
import 'package:ipfs_libp2p/core/network/stream.dart';
import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';
import 'package:transpiled_multiaddr/transpiled_multiaddr.dart';

import '../network/libp2p_host.dart';
import '../protocols/dht/dht_message.dart';
import '../protocols/dht/query_peerset.dart';

/// Kademlia DHT protocol identifier.
const String dhtProtocol = '/ipfs/kad/1.0.0';

/// Queries the Kademlia DHT for providers of a Cid.
final class DhtClient implements ContentDiscovery {
  /// Creates a DHT provider finder using [router] and [bootstrapPeers].
  DhtClient({
    required this.router,
    required this.bootstrapPeers,
    this.timeout = const Duration(seconds: 10),
    this.lookupTimeout = const Duration(minutes: 1),
    this.alpha = 3,
    this.beta = 3,
    this.bucketSize = 20,
  });

  /// Router used to query DHT peers.
  final Libp2pRouter router;

  /// Initial peers from which provider lookup begins.
  final List<AddrInfo> bootstrapPeers;

  /// Maximum time allowed for each individual DHT RPC query.
  final Duration timeout;

  /// Maximum time allowed for the entire lookup operation.
  final Duration lookupTimeout;

  /// Concurrency factor (alpha), default 3.
  final int alpha;

  /// Concurrency termination threshold (beta), default 3.
  final int beta;

  /// Kademlia bucket size (K), default 20.
  final int bucketSize;

  bool _closed = false;
  final Set<P2PStream<dynamic>> _activeStreams = {};

  /// Closes the DHT client, aborting in-flight queries and resetting streams.
  Future<void> close() async {
    _closed = true;
    for (final stream in _activeStreams.toList()) {
      try {
        await stream.reset();
      } catch (_) {}
    }
    _activeStreams.clear();
  }

  @override
  /// Finds up to [count] providers for [cid]. A non-positive count streams all
  /// providers discovered by the lookup.
  Stream<AddrInfo> findProvidersAsync(Cid cid, int count) {
    if (count < 0) throw RangeError.value(count, 'count');
    if (_closed) throw StateError('DhtClient is closed');
    late StreamController<AddrInfo> controller;
    var cancelled = false;
    controller = StreamController<AddrInfo>(
      onListen: () => _lookup(
        cid,
        count,
        controller,
        () => cancelled || _closed,
      ),
      onCancel: () => cancelled = true,
    );
    return controller.stream;
  }

  Future<void> _lookup(
    Cid cid,
    int count,
    StreamController<AddrInfo> output,
    bool Function() isCancelled,
  ) async {
    final target = Uint8List.fromList(cid.multihash.toBytes());
    final targetPeer = PeerId(value: target);

    int compareDistance(PeerId target, PeerId a, PeerId b) =>
        _distance(target.value, a).compareTo(_distance(target.value, b));

    final queryPeers = QueryPeerset(targetPeer, compareDistance);
    final knownPeers = <PeerId, AddrInfo>{};
    final emitted = <PeerId, AddrInfo>{};
    final deadline = DateTime.now().add(lookupTimeout);

    PeerId? selfId;
    try {
      selfId = PeerId.decode(router.host.id.toBase58());
    } catch (_) {}

    for (final p in bootstrapPeers) {
      if (selfId != null && p.id == selfId) continue;
      knownPeers[p.id] = p;
      queryPeers.tryAdd(p.id, selfId ?? p.id);
    }

    bool isStopCondition() => count > 0 && emitted.length >= count;

    Object? lastError;

    try {
      while (!isCancelled()) {
        if (DateTime.now().isAfter(deadline)) break;
        if (isStopCondition()) break;

        // Termination condition: closest beta peers are all queried.
        final closestBeta = queryPeers.getClosestNInStates(
          beta,
          {PeerState.heard, PeerState.waiting, PeerState.queried},
        );
        final isBetaTerminated =
            closestBeta.length >= beta &&
            closestBeta.every((p) => queryPeers.getState(p) == PeerState.queried);

        if (isBetaTerminated) break;

        final heardPeers = queryPeers.getClosestNInStates(
          alpha,
          {PeerState.heard},
        );

        // Starvation termination: no heard peers and no outstanding queries.
        if (heardPeers.isEmpty) {
          if (queryPeers.numWaiting == 0) break;
        }

        final batch = heardPeers.take(alpha).toList();
        for (final p in batch) {
          queryPeers.setState(p, PeerState.waiting);
        }

        final responses = await Future.wait([
          for (final peerId in batch)
            _safeQuery(knownPeers[peerId]!, cid, isCancelled, deadline),
        ]);

        for (var i = 0; i < batch.length; i++) {
          final peerId = batch[i];
          final result = responses[i];
          final response = result.response;
          if (response == null) {
            queryPeers.setState(peerId, PeerState.unreachable);
            lastError = result.error;
            continue;
          }
          queryPeers.setState(peerId, PeerState.queried);

          if (isCancelled()) break;

          // Closer peers: limit to 2*bucketSize (40), discard self, persist in peerstore
          for (final peer in response.closerPeers.take(2 * bucketSize)) {
            if (selfId != null && peer.id == selfId) continue;

            final existing = knownPeers[peer.id];
            final merged = await _mergeWithPeerstore(existing, peer);
            knownPeers[peer.id] = merged;

            if (merged.addrs.isNotEmpty) {
              await router.addAddrs(merged, tempAddrTtl);
            }
            queryPeers.tryAdd(peer.id, peerId);
          }

          // Provider peers: preserve full AddrInfo, persist in peerstore, emit unique
          for (final provider in response.providerPeers) {
            if (selfId != null && provider.id == selfId) continue;

            final existing = knownPeers[provider.id];
            final complete = await _mergeWithPeerstore(existing, provider);
            knownPeers[provider.id] = complete;

            if (complete.addrs.isNotEmpty) {
              await router.addAddrs(complete, tempAddrTtl);
            }

            final prev = emitted[provider.id];
            if (prev == null ||
                (prev.addrs.isEmpty && complete.addrs.isNotEmpty)) {
              emitted[provider.id] = complete;
              output.add(complete);
              if (isStopCondition()) return;
            }
          }
        }
      }

      // Kademlia Follow-up: query unqueried heard peers in top K
      if (!isCancelled() &&
          !isStopCondition() &&
          !DateTime.now().isAfter(deadline)) {
        final topK = queryPeers.getClosestNInStates(
          bucketSize,
          {PeerState.heard, PeerState.waiting, PeerState.queried},
        );
        final followUpPeers = topK
            .where((p) => queryPeers.getState(p) == PeerState.heard)
            .toList();

        for (final peerId in followUpPeers) {
          if (isCancelled() ||
              isStopCondition() ||
              DateTime.now().isAfter(deadline)) {
            break;
          }
          queryPeers.setState(peerId, PeerState.waiting);
          final result = await _safeQuery(
            knownPeers[peerId]!,
            cid,
            isCancelled,
            deadline,
          );
          final response = result.response;
          if (response == null) {
            queryPeers.setState(peerId, PeerState.unreachable);
            lastError = result.error;
            continue;
          }
          queryPeers.setState(peerId, PeerState.queried);

          for (final peer in response.closerPeers.take(2 * bucketSize)) {
            if (selfId != null && peer.id == selfId) continue;
            final existing = knownPeers[peer.id];
            final merged = await _mergeWithPeerstore(existing, peer);
            knownPeers[peer.id] = merged;
            if (merged.addrs.isNotEmpty) {
              await router.addAddrs(merged, tempAddrTtl);
            }
          }

          for (final provider in response.providerPeers) {
            if (selfId != null && provider.id == selfId) continue;
            final existing = knownPeers[provider.id];
            final complete = await _mergeWithPeerstore(existing, provider);
            knownPeers[provider.id] = complete;
            if (complete.addrs.isNotEmpty) {
              await router.addAddrs(complete, tempAddrTtl);
            }
            final prev = emitted[provider.id];
            if (prev == null ||
                (prev.addrs.isEmpty && complete.addrs.isNotEmpty)) {
              emitted[provider.id] = complete;
              output.add(complete);
              if (isStopCondition()) return;
            }
          }
        }
      }

      if (emitted.isEmpty && lastError != null && !isCancelled()) {
        output.addError(lastError);
      }
    } finally {
      await output.close();
    }
  }

  Future<AddrInfo> _mergeWithPeerstore(
    AddrInfo? known,
    AddrInfo received,
  ) async {
    final fromPeerstore = await router.getAddrs(received.id);
    final allAddrs = <Multiaddr>{
      ...?known?.addrs,
      ...fromPeerstore,
      ...received.addrs,
    };
    return AddrInfo(id: received.id, addrs: allAddrs.toList());
  }

  Future<DhtResponse> _query(
    AddrInfo peer,
    Cid cid,
    bool Function() isCancelled,
    DateTime deadline,
  ) async {
    if (isCancelled()) throw StateError('DHT query cancelled');
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) {
      throw TimeoutException('DHT query deadline exceeded');
    }
    final rpcTimeout = timeout < remaining ? timeout : remaining;

    await router.connect(peer).timeout(rpcTimeout);
    if (isCancelled()) throw StateError('DHT query cancelled');

    final stream = await router.host.newStream(
      router.runtimePeerId(peer.id),
      const [dhtProtocol],
      Context(timeout: rpcTimeout),
    ).timeout(rpcTimeout);

    _activeStreams.add(stream);
    try {
      if (isCancelled()) {
        await stream.reset();
        throw StateError('DHT query cancelled');
      }
      await stream.setDeadline(DateTime.now().add(rpcTimeout));
      await stream.write(encodeGetProviders(cid)).timeout(rpcTimeout);
      final bytes = await _readFrame(stream).timeout(rpcTimeout);
      return DhtResponse.fromBytes(bytes);
    } catch (e) {
      try {
        await stream.reset();
      } catch (_) {}
      rethrow;
    } finally {
      _activeStreams.remove(stream);
      try {
        await stream.close();
      } catch (_) {}
    }
  }

  Future<({DhtResponse? response, Object? error})> _safeQuery(
    AddrInfo peer,
    Cid cid,
    bool Function() isCancelled,
    DateTime deadline,
  ) async {
    try {
      return (
        response: await _query(peer, cid, isCancelled, deadline),
        error: null,
      );
    } catch (error) {
      return (response: null, error: error);
    }
  }
}

BigInt _distance(Uint8List target, PeerId peer) {
  final a = sha256.convert(target).bytes;
  final b = sha256.convert(peer.value).bytes;
  var result = BigInt.zero;
  for (var i = 0; i < a.length; i++) {
    result = (result << 8) | BigInt.from(a[i] ^ b[i]);
  }
  return result;
}

Future<Uint8List> _readFrame(P2PStream<dynamic> stream) async {
  var length = 0;
  var shift = 0;
  for (var i = 0; i < 10; i++) {
    final byte = await stream.read(1);
    if (byte.isEmpty) {
      throw const FormatException('Unexpected EOF in DHT frame');
    }
    length |= (byte.first & 0x7f) << shift;
    if (byte.first & 0x80 == 0) {
      if (length > dhtMessageSizeMax) {
        throw const FormatException('DHT message exceeds 4 MiB');
      }
      final out = BytesBuilder(copy: false);
      while (out.length < length) {
        final chunk = await stream.read(length - out.length);
        if (chunk.isEmpty) {
          throw const FormatException('Unexpected EOF in DHT frame');
        }
        out.add(chunk);
      }
      return out.takeBytes();
    }
    shift += 7;
  }
  throw const FormatException('DHT frame varint is too long');
}
