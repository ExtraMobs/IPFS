// Port of go-libp2p/core/discovery/options.go.

/// A discovery option applied to [DiscoveryOptions].
typedef DiscoveryOption = void Function(DiscoveryOptions options);

/// Options shared by service advertisement and peer discovery.
class DiscoveryOptions {
  /// Creates the zero-valued options, matching Go's `Options{}`.
  DiscoveryOptions();

  /// Hint for how long an advertisement should remain valid.
  Duration ttl = Duration.zero;

  /// Upper bound on peers returned by discovery. Zero means no bound.
  int limit = 0;

  /// Implementation-specific options.
  Map<Object, Object>? other;

  /// Applies options in order.
  void apply(Iterable<DiscoveryOption> options) {
    for (final option in options) {
      option(this);
    }
  }
}

/// Provides a hint for the duration of an advertisement.
DiscoveryOption ttl(Duration value) =>
    (options) => options.ttl = value;

/// Provides an upper bound on the peer count for discovery.
DiscoveryOption limit(int value) =>
    (options) => options.limit = value;
