// lib/src/transport/dns/dns_bootstrap_resolver_io.dart
import 'package:dart_ipfs_core/dart_ipfs_core.dart' show BasicResolver;

import 'system_resolver.dart';

/// The native (`dart:io`) DNS resolver, backed by real UDP sockets.
BasicResolver? createDnsResolver() => SystemResolver();
