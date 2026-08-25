// src/core/cid.dart
//
// Re-export shim: CID lives in the transpiled_cid package (go-cid port,
// protobuf-free, shared with the umbrella's public barrel). This file
// exists so the many existing `package:transpiled_ipfs/src/core/cid.dart`
// imports across lib/src/ keep working unchanged, and so callers of
// `lib/src/core/data_structures/car.dart` (which imports this file) get
// the exact same CID class the public barrel exports -- closing the
// two-different-CID-classes-same-name collision that existed before this
// shim (see doc/architecture/AGENTS.md and the Phase 2 plan for the full
// history).
//
// Protobuf (de)serialization -- CID.fromProto/toProto -- intentionally
// does NOT live in transpiled_cid (which stays protobuf-free); see
// cid_proto_codec.dart for that half.
export 'package:transpiled_cid/transpiled_cid.dart' show CID;
