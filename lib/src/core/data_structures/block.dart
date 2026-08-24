// src/core/data_structures/block.dart
//
// Re-export shim: Block moved to dart_ipfs_core (protobuf-free), matching
// the CID shim (see ../cid.dart). Protobuf/Bitswap-protobuf serialization
// -- Block.fromProto/fromBitswapProto/toProto/toBitswapProto -- did NOT
// move to dart_ipfs_core; see ../block_proto_codec.dart for that half.
export 'package:dart_ipfs_core/dart_ipfs_core.dart' show Block;
