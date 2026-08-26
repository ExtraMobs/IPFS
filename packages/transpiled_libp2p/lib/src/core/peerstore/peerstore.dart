/// Time-to-live values used by libp2p peer address books.
///
/// Go's [time.Duration] is nanoseconds; Dart's [Duration] stores
/// microseconds, so the permanent values are rounded down to that precision.
/// Address expiration time.
const Duration addressTtl = Duration(hours: 1);
/// Short-lived address expiration time.
const Duration tempAddrTtl = Duration(minutes: 2);
/// Expiration time after a recent connection.
const Duration recentlyConnectedAddrTtl = Duration(minutes: 15);
/// Expiration time for externally observed addresses.
const Duration ownObservedAddrTtl = Duration(minutes: 30);

/// Permanent TTLs are distinct, as in go-libp2p (`math.MaxInt64 - iota`).
const Duration permanentAddrTtl = Duration(microseconds: 9223372036854775);
const Duration connectedAddrTtl = Duration(microseconds: 9223372036854774);

/// Go-exported spelling retained for source-level parity.
const AddressTTL = addressTtl;
/// Go-exported spelling retained for source-level parity.
const TempAddrTTL = tempAddrTtl;
/// Go-exported spelling retained for source-level parity.
const RecentlyConnectedAddrTTL = recentlyConnectedAddrTtl;
/// Go-exported spelling retained for source-level parity.
const OwnObservedAddrTTL = ownObservedAddrTtl;
/// Go-exported spelling retained for source-level parity.
const PermanentAddrTTL = permanentAddrTtl;
/// Go-exported spelling retained for source-level parity.
const ConnectedAddrTTL = connectedAddrTtl;
