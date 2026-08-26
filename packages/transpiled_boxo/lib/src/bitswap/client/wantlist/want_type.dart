// lib/src/bitswap/client/wantlist/want_type.dart
//
// Port of the two `Message_Wantlist_WantType` enum values from
// boxo/bitswap/message/pb/message.pb.go (a generated protobuf file --
// `bitswap/message/pb` itself isn't ported yet). The Go enum has exactly these
// two values; the complete protobuf messages will reuse this wire mapping.
/// The Bitswap want type from `pb.Message_Wantlist_WantType`.
///
/// [code] preserves the exact protobuf wire values so the full message port
/// can replace this enum without changing persisted values.
enum WantType {
  /// Request the full block. Equivalent to
  /// `pb.Message_Wantlist_Block` (wire value 0).
  block(0),

  /// Request only a "have" (existence) response. Equivalent to
  /// `pb.Message_Wantlist_Have` (wire value 1).
  have(1);

  const WantType(this.code);

  /// The protobuf wire value for this want type.
  final int code;
}
