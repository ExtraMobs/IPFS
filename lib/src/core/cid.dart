// src/core/cid.dart
//
// Re-export shim: CID moved to dart_ipfs_core (protobuf-free, shared with
// the umbrella's public barrel). This file exists so the many existing
// `package:dart_ipfs/src/core/cid.dart` imports across lib/src/ keep
// working unchanged, and so callers of `lib/src/core/data_structures/car.dart`
// (which imports this file) get the exact same CID class the public barrel
// exports -- closing the two-different-CID-classes-same-name collision
// that existed before this shim (see doc/architecture/AGENTS.md and the
// Phase 2 plan for the full history).
//
// Protobuf (de)serialization -- CID.fromProto/toProto -- intentionally did
// NOT move to dart_ipfs_core (which stays protobuf-free); see
// cid_proto_codec.dart for that half.
export 'package:dart_ipfs_core/dart_ipfs_core.dart' show CID;
