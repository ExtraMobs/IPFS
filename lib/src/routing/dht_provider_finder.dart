import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ipfs_libp2p/core/network/context.dart';
import 'package:ipfs_libp2p/core/network/stream.dart';
import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';

import '../network/libp2p_host.dart';
import '../protocols/dht/dht_message.dart';

/// Kademlia DHT protocol identifier.
const String dhtProtocol = '/ipfs/kad/1.0.0';

/// Queries the Kademlia DHT for providers of a CID.
final class DHTClient implements ContentDiscovery {
  /// Creates a DHT provider finder using [router] and [bootstrapPeers].
  DHTClient({
    required this.router,
    required this.bootstrapPeers,
    this.timeout = const Duration(seconds: 10),
  });

  /// Router used to query DHT peers.
  final Libp2pRouter router;

  /// Initial peers from which provider lookup begins.
  final List<AddrInfo> bootstrapPeers;

  /// Maximum time allowed for each DHT query.
  final Duration timeout;

  @override
  /// Finds up to [count] providers for [cid]. A non-positive count streams all
  /// providers discovered by the lookup.
  Stream<AddrInfo> findProvidersAsync(CID cid, int count) {
    if (count < 0) throw RangeError.value(count, 'count');
    late StreamController<AddrInfo> controller;
    var cancelled = false;
    controller = StreamController<AddrInfo>(
      onListen: () => _lookup(cid, count, controller, () => cancelled),
      onCancel: () => cancelled = true,
    );
    return controller.stream;
  }

  Future<void> _lookup(
    CID cid,
    int count,
    StreamController<AddrInfo> output,
    bool Function() cancelled,
  ) async {
    final target = Uint8List.fromList(cid.multihash.toBytes());
    final peers = <PeerId, AddrInfo>{for (final p in bootstrapPeers) p.id: p};
    final queried = <PeerId>{};
    final emitted = <PeerId, AddrInfo>{};
    Object? lastError;
    try {
      while (!cancelled()) {
        final candidates =
            peers.values.where((p) => !queried.contains(p.id)).toList()..sort(
              (a, b) =>
                  _distance(target, a.id).compareTo(_distance(target, b.id)),
            );
        if (candidates.isEmpty) break;
        final batch = candidates.take(10).toList();
        for (final peer in batch) {
          queried.add(peer.id);
        }
        final responses = await Future.wait([
          for (final peer in batch) _safeQuery(peer, cid),
        ]);
        for (final result in responses) {
          final response = result.response;
          if (response == null) {
            lastError = result.error;
            continue;
          }
          if (cancelled()) continue;
          for (final peer in response.closerPeers.take(40)) {
            final old = peers[peer.id];
            if (old == null || (old.addrs.isEmpty && peer.addrs.isNotEmpty)) {
              peers[peer.id] = _merge(old, peer);
            }
          }
          for (final provider in response.providerPeers) {
            final old = emitted[provider.id];
            if (old == null ||
                (old.addrs.isEmpty && provider.addrs.isNotEmpty)) {
              final complete = _merge(peers[provider.id], provider);
              emitted[provider.id] = complete;
              output.add(complete);
              if (count > 0 && emitted.length >= count) return;
            }
          }
        }
        final closest = peers.values.toList()
          ..sort(
            (a, b) =>
                _distance(target, a.id).compareTo(_distance(target, b.id)),
          );
        if (closest.take(3).every((p) => queried.contains(p.id))) break;
      }
      if (emitted.isEmpty && lastError != null && !cancelled()) {
        output.addError(lastError);
      }
    } finally {
      await output.close();
    }
  }

  Future<DhtResponse> _query(AddrInfo peer, CID cid) async {
    await router.connect(peer);
    final stream = await router.host.newStream(
      router.runtimePeerId(peer.id),
      const [dhtProtocol],
      Context(timeout: timeout),
    );
    try {
      await stream.setDeadline(DateTime.now().add(timeout));
      await stream.write(encodeGetProviders(cid));
      return DhtResponse.fromBytes(await _readFrame(stream));
    } finally {
      await stream.close();
    }
  }

  Future<({DhtResponse? response, Object? error})> _safeQuery(
    AddrInfo peer,
    CID cid,
  ) async {
    try {
      return (response: await _query(peer, cid), error: null);
    } catch (error) {
      return (response: null, error: error);
    }
  }
}

AddrInfo _merge(AddrInfo? known, AddrInfo received) => AddrInfo(
  id: received.id,
  addrs: {...?known?.addrs, ...received.addrs}.toList(),
);

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
