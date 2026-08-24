import 'package:fixnum/fixnum.dart';

import '../cid.dart';

/// A named link to another node in the DAG.
class NodeLink {
  /// Creates a node link.
  NodeLink({
    required this.name,
    required this.cid,
    required this.size,
    this.metadata = const {},
  });

  /// The link name (filename in directories).
  final String name;

  /// The CID of the linked node.
  final CID cid;

  /// The size of the linked content.
  final Int64 size;

  /// Custom metadata for this link.
  final Map<String, String> metadata;
}
