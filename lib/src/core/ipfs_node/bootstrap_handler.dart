// src/core/ipfs_node/bootstrap_handler.dart
import 'dart:async';

import 'package:dart_ipfs_core/dart_ipfs_core.dart'
    show BasicResolver, Multiaddr, Resolver, dnsMatches;

import '../../transport/dns/dns_bootstrap_resolver.dart';
import '../../utils/logger.dart';
import '../config/ipfs_config.dart';
import '../data_structures/peer.dart';
import '../interfaces/i_lifecycle.dart';
import 'network_handler.dart';

/// How many chained DNS redirects (e.g. bootstrap.libp2p.io's TXT records
/// pointing at per-node dnsaddr aliases, which in turn resolve to concrete
/// addresses) to follow before giving up on one bootstrap address. Not part
/// of go-multiaddr-dns's own `Resolver` -- its docs leave looping until
/// DNS-free to the caller -- this bounds it defensively against a
/// misbehaving or malicious TXT chain.
const int _maxDnsRedirects = 8;

/// Handles bootstrap peer connections for an IPFS node.
class BootstrapHandler implements ILifecycle {
  /// Creates a bootstrap handler with the given config and network handler.
  ///
  /// [dnsResolver] resolves `/dnsaddr/`, `/dns4/`, `/dns6/`, and `/dns/`
  /// bootstrap components against real DNS; defaults to [createDnsResolver]
  /// (`null` on web, where there's no raw-socket API to resolve TXT records
  /// with -- see dns_bootstrap_resolver_web.dart). Override it with a
  /// [BasicResolver] such as `MockResolver` for deterministic, offline
  /// tests.
  BootstrapHandler(this._config, this._networkHandler, {BasicResolver? dnsResolver})
    : _dnsResolver = _wrapDnsResolver(dnsResolver ?? createDnsResolver()) {
    _logger = Logger(
      'BootstrapHandler',
      debug: _config.debug,
      verbose: _config.verboseLogging,
    );
    _logger.debug('Creating new BootstrapHandler instance');
  }
  final IPFSConfig _config;
  final NetworkHandler _networkHandler;
  late final Logger _logger;
  final Set<Peer> _connectedBootstrapPeers = {};
  Timer? _reconnectionTimer;
  bool _isRunning = false;
  final Resolver? _dnsResolver;

  static Resolver? _wrapDnsResolver(BasicResolver? basic) =>
      basic == null ? null : Resolver(defaultResolver: basic);

  // Default reconnection interval
  static const Duration _reconnectionInterval = Duration(minutes: 5);

  /// Starts the bootstrap handler
  @override
  Future<void> start() async {
    if (_isRunning) {
      _logger.warning('BootstrapHandler already running');
      return;
    }

    try {
      _logger.debug('Starting BootstrapHandler...');
      _isRunning = true;

      // Initial connection to bootstrap peers
      await _connectToBootstrapPeers();

      // Set up periodic reconnection
      _setupReconnectionTimer();

      _logger.info('BootstrapHandler started successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to start BootstrapHandler', e, stackTrace);
      _isRunning = false;
      rethrow;
    }
  }

  /// Stops the bootstrap handler
  @override
  Future<void> stop() async {
    if (!_isRunning) {
      _logger.warning('BootstrapHandler already stopped');
      return;
    }

    try {
      _logger.debug('Stopping BootstrapHandler...');

      // Cancel reconnection timer
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;

      // Clear connected peers set
      _connectedBootstrapPeers.clear();

      _isRunning = false;
      _logger.info('BootstrapHandler stopped successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to stop BootstrapHandler', e, stackTrace);
      rethrow;
    }
  }

  void _setupReconnectionTimer() {
    _logger.verbose('Setting up bootstrap peer reconnection timer');
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer.periodic(_reconnectionInterval, (_) {
      _connectToBootstrapPeers();
    });
  }

  Future<void> _connectToBootstrapPeers() async {
    _logger.debug('Connecting to bootstrap peers...');

    for (final configuredAddress in _config.network.bootstrapPeers) {
      final resolvedAddresses = await _resolveBootstrapAddress(configuredAddress);
      for (final peerAddress in resolvedAddresses) {
        await _connectToOneBootstrapPeer(peerAddress);
      }
    }
  }

  /// Resolves `configuredAddress` to one or more concrete (DNS-free)
  /// multiaddr strings. Returns `[configuredAddress]` unchanged if it has
  /// no DNS component to begin with. Returns an empty list (logging why)
  /// if it does but resolution isn't possible on this platform or fails.
  Future<List<String>> _resolveBootstrapAddress(String configuredAddress) async {
    final Multiaddr parsed;
    try {
      parsed = Multiaddr.parse(configuredAddress);
    } on FormatException catch (e) {
      _logger.error('Invalid bootstrap multiaddr: $configuredAddress', e);
      return const [];
    }
    if (!dnsMatches(parsed)) return [configuredAddress];

    final resolver = _dnsResolver;
    if (resolver == null) {
      _logger.verbose(
        'Skipping DNS bootstrap address (no DNS resolver on this platform): '
        '$configuredAddress',
      );
      return const [];
    }

    var toResolve = [parsed];
    final resolved = <String>[];
    for (var hop = 0; hop < _maxDnsRedirects && toResolve.isNotEmpty; hop++) {
      final next = <Multiaddr>[];
      for (final addr in toResolve) {
        List<Multiaddr> results;
        try {
          results = await resolver.resolve(addr);
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to resolve bootstrap DNS address: $configuredAddress',
            e,
            stackTrace,
          );
          continue;
        }
        for (final r in results) {
          if (dnsMatches(r)) {
            next.add(r);
          } else {
            resolved.add(r.toAddrString());
          }
        }
      }
      toResolve = next;
    }
    if (toResolve.isNotEmpty) {
      _logger.verbose(
        'Gave up resolving bootstrap DNS address after $_maxDnsRedirects '
        'redirects: $configuredAddress',
      );
    }
    return resolved;
  }

  Future<void> _connectToOneBootstrapPeer(String peerAddress) async {
    try {
      _logger.verbose(
        'Attempting to connect to bootstrap peer: $peerAddress',
      );

      // Create peer instance from multiaddr
      final peer = await Peer.fromMultiaddr(peerAddress);

      if (_connectedBootstrapPeers.contains(peer)) {
        _logger.verbose('Already connected to bootstrap peer: $peerAddress');
        return;
      }

      // Connection logic handled by NetworkHandler
      await _networkHandler.connectToPeer(peerAddress);

      // We just track the successful connections here
      _connectedBootstrapPeers.add(peer);
      _logger.debug('Successfully connected to bootstrap peer: $peerAddress');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to connect to bootstrap peer: $peerAddress',
        e,
        stackTrace,
      );
    }
  }

  /// Gets the current status of the bootstrap handler
  Future<Map<String, dynamic>> getStatus() async {
    return {
      'running': _isRunning,
      'connected_peers': _connectedBootstrapPeers.length,
      'total_bootstrap_peers': _config.network.bootstrapPeers.length,
      'reconnection_interval': _reconnectionInterval.inMinutes,
    };
  }
}
