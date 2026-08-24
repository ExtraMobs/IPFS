// src/core/interfaces/block.dart
//
// Re-export shim: IBlock moved to dart_ipfs_core (protobuf-free) -- see
// ../data_structures/block.dart for the Block shim and
// ../block_proto_codec.dart for the protobuf-specific extension this
// interface used to require (toProto/toBitswapProto), which don't belong
// on a protocol-agnostic interface.
//
// IBlockFactory (the sibling interface that used to live here) had zero
// implementors anywhere in lib/src/ or test/ and was removed rather than
// adapted -- same precedent as the Phase 0 dead-code cleanup.
export 'package:dart_ipfs_core/dart_ipfs_core.dart' show IBlock;
