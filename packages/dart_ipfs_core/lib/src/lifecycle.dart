// lib/src/lifecycle.dart

/// Interface for services that require explicit startup and shutdown.
///
/// Canonical home for the lifecycle contract used across dart_ipfs's
/// Manager/Handler pattern. The umbrella package's copy
/// (`lib/src/core/interfaces/i_lifecycle.dart`) becomes a re-export shim of
/// this one once `lib/src/` is migrated to consume dart_ipfs_core.
abstract class ILifecycle {
  /// Starts the service.
  Future<void> start();

  /// Stops the service.
  Future<void> stop();
}
