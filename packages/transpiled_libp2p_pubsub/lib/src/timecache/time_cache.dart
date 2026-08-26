// lib/src/timecache/time_cache.dart
//
// Port of go-libp2p-pubsub's timecache/time_cache.go: a cache of recently
// seen message IDs, used by pubsub to deduplicate messages.
import 'first_seen_cache.dart';
import 'last_seen_cache.dart';

/// Which expiry strategy a [TimeCache] uses. Equivalent to
/// go-libp2p-pubsub's `Strategy`.
enum TimeCacheStrategy {
  /// Expires an entry from the time it was added. Equivalent to
  /// go-libp2p-pubsub's `Strategy_FirstSeen`.
  firstSeen,

  /// Expires an entry from the last time it was touched by [TimeCache.add]
  /// or [TimeCache.has]. Equivalent to go-libp2p-pubsub's
  /// `Strategy_LastSeen`.
  lastSeen,
}

/// A cache of recently seen ids. Equivalent to go-libp2p-pubsub's
/// `TimeCache`.
abstract class TimeCache {
  /// Adds [id] into the cache if not already present. Returns `true` if
  /// newly added. Depending on the strategy, may or may not update an
  /// existing entry's expiry.
  bool add(String id);

  /// Whether [id] is in the cache. Depending on the strategy, may or may
  /// not update an existing entry's expiry.
  bool has(String id);

  /// Signals this cache is no longer needed, stopping its background
  /// sweep and releasing resources.
  void done();
}

/// Creates a [TimeCache] using the default ("first seen") strategy.
/// Equivalent to go-libp2p-pubsub's `NewTimeCache`.
TimeCache newTimeCache(Duration ttl) => newTimeCacheWithStrategy(TimeCacheStrategy.firstSeen, ttl);

/// Creates a [TimeCache] using [strategy]. Equivalent to
/// go-libp2p-pubsub's `NewTimeCacheWithStrategy`.
TimeCache newTimeCacheWithStrategy(TimeCacheStrategy strategy, Duration ttl) {
  return switch (strategy) {
    TimeCacheStrategy.firstSeen => FirstSeenCache(ttl),
    TimeCacheStrategy.lastSeen => LastSeenCache(ttl),
  };
}

/// Creates a [FirstSeenCache] with an explicit sweep interval (for
/// testing). Equivalent to go-libp2p-pubsub's
/// `newFirstSeenCacheWithSweepInterval`.
TimeCache newFirstSeenCacheWithSweepInterval(Duration ttl, Duration sweepInterval) =>
    FirstSeenCache(ttl, sweepInterval);

/// Creates a [LastSeenCache] with an explicit sweep interval (for
/// testing). Equivalent to go-libp2p-pubsub's
/// `newLastSeenCacheWithSweepInterval`.
TimeCache newLastSeenCacheWithSweepInterval(Duration ttl, Duration sweepInterval) =>
    LastSeenCache(ttl, sweepInterval);
