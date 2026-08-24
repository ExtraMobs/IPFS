// lib/src/core/cid_proto_codec.dart
//
// Protobuf (de)serialization for CID, kept out of dart_ipfs_core (which
// stays protobuf-free) and out of CID itself now that CID is a re-export
// shim of dart_ipfs_core's CID (see lib/src/core/cid.dart).
//
// `cid.toProto()` keeps working unchanged for existing call sites via the
// extension below -- Dart extension methods use ordinary dot-call syntax.
// `CID.fromProto(proto)` cannot be an extension (Dart doesn't allow
// extending a class with a new static factory), so it becomes the
// top-level `cidFromProto(proto)` function; call sites update accordingly.
import 'dart:typed_data';

import 'package:dart_ipfs_core/dart_ipfs_core.dart';

import '../proto/generated/core/cid.pb.dart';

/// Adds protobuf serialization to [CID].
extension CIDProtoCodec on CID {
  /// Converts this CID to a Protobuf representation.
  IPFSCIDProto toProto() {
    return IPFSCIDProto()
      ..version = version == 0
          ? IPFSCIDVersion.IPFS_CID_VERSION_0
          : IPFSCIDVersion.IPFS_CID_VERSION_1
      ..multihash = multihash.toBytes()
      ..codec = codec ?? ''
      ..multibasePrefix = version == 0 ? '' : 'base32';
  }
}

/// Creates a [CID] from a Protobuf representation.
CID cidFromProto(IPFSCIDProto proto) {
  if (proto.version == IPFSCIDVersion.IPFS_CID_VERSION_0) {
    final mh = MultihashUtils.decode(Uint8List.fromList(proto.multihash));
    return CID.v0(Uint8List.fromList(mh.digest));
  }
  return CID.v1(
    proto.codec,
    MultihashUtils.decode(Uint8List.fromList(proto.multihash)),
  );
}

/// Converts a CID version index to the [IPFSCIDVersion] enum.
///
/// Moved from utils/encoding.dart: utils/ must not depend on generated
/// protobuf code (see test/architecture_boundary_test.dart).
IPFSCIDVersion cidVersionFromIndex(int index) {
  switch (index) {
    case 0:
      return IPFSCIDVersion.IPFS_CID_VERSION_UNSPECIFIED;
    case 1:
      return IPFSCIDVersion.IPFS_CID_VERSION_0;
    case 2:
      return IPFSCIDVersion.IPFS_CID_VERSION_1;
    default:
      throw UnsupportedError('Unsupported CID version index: $index');
  }
}
