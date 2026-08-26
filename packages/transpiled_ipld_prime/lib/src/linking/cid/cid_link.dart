import 'dart:typed_data';

import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_ipld_prime/src/datamodel/link.dart';
import 'package:transpiled_multihash/transpiled_multihash.dart';

/// IPLD link backed by a CID, equivalent to Go's `linking/cid.Link`.
final class CidLink implements Link {
  /// Creates a link for [cid].
  const CidLink(this.cid);

  /// The CID represented by this link.
  final CID cid;

  @override
  LinkPrototype prototype() => CidLinkPrototype(cid.prefix);

  @override
  String toString() => cid.toString();

  @override
  List<int> binary() => cid.toBytes();
}

/// Builds CID links with a fixed CID prefix.
final class CidLinkPrototype implements LinkPrototype {
  /// Creates a prototype for [prefix].
  const CidLinkPrototype(this.prefix);

  /// The CID shape used for links built by this prototype.
  final Prefix prefix;

  @override
  Link buildLink(List<int> hashsum) {
    if (prefix.version != 0 && prefix.version != 1) {
      throw const FormatException('invalid cid version');
    }
    if (prefix.version == 0 &&
        (prefix.mhType != 'sha2-256' ||
            (prefix.mhLength != 32 && prefix.mhLength != -1))) {
      throw const FormatException('invalid cid v0 prefix');
    }
    var digest = Uint8List.fromList(hashsum);
    if (prefix.mhLength >= 0 && digest.length > prefix.mhLength) {
      digest = Uint8List.fromList(digest.sublist(0, prefix.mhLength));
    }
    final multihash = MultihashUtils.encode(prefix.mhType, digest);
    final cid = prefix.version == 0
        ? CID.v0(digest)
        : CID.v1(prefix.codec, multihash);
    return CidLink(cid);
  }
}
