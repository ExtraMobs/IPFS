// lib/src/bootstrap.dart
//
// Port of go-libp2p-routing-helpers's bootstrap.go.
import 'dart:async';

/// Implemented by any router wishing to be bootstrapped. Equivalent to
/// go-libp2p-routing-helpers's `Bootstrap` interface.
abstract class Bootstrap {
  /// Bootstraps the router.
  Future<void> bootstrap();
}
