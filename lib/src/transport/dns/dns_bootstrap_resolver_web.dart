// lib/src/transport/dns/dns_bootstrap_resolver_web.dart
import 'package:dart_ipfs_core/dart_ipfs_core.dart' show BasicResolver;

/// Browsers expose no raw-socket API, so there is no DNS resolver on web
/// (matching `network_handler_web.dart`'s `connectToPeer`, which is
/// already a no-op there). Callers should treat a `null` result as "skip
/// DNS-bearing bootstrap addresses on this platform".
BasicResolver? createDnsResolver() => null;
