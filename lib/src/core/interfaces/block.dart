// src/core/interfaces/block.dart
//
// Re-export shim: IBlock's real, canonical implementation lives directly
// in the umbrella now -- see ../data_structures/block.dart (not a Go-module
// port, dissolved back into transpiled_ipfs; see
// doc/transpilation/PROGRESS.md) -- and ../block_proto_codec.dart for the
// protobuf-specific extension this interface used to require
// (toProto/toBitswapProto), which don't belong on a protocol-agnostic
// interface.
//
// IBlockFactory (the sibling interface that used to live here) had zero
// implementors anywhere in lib/src/ or test/ and was removed rather than
// adapted -- same precedent as the Phase 0 dead-code cleanup.
export '../data_structures/block.dart' show IBlock;
