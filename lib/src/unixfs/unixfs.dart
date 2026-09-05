import 'dart:typed_data';

import 'package:transpiled_block_format/transpiled_block_format.dart' as blocks;
import 'package:transpiled_boxo/transpiled_boxo.dart';
import 'package:transpiled_cid/transpiled_cid.dart';

/// Statistics equivalent to the reusable UnixFS/DAG fields exposed by Kubo.
final class UnixFsStat {
  /// Creates UnixFS statistics for [cid].
  const UnixFsStat({
    required this.cid,
    required this.size,
    required this.blockSize,
    required this.cumulativeSize,
    required this.numLinks,
    required this.numBlocks,
  });

  /// CID of the UnixFS node.
  final CID cid;

  /// Logical file size in bytes.
  final int size;

  /// Size of the node's data block in bytes.
  final int blockSize;

  /// Cumulative size of this node and its descendants.
  final int cumulativeSize;

  /// Number of links in this node.
  final int numLinks;

  /// Number of blocks in this node's DAG.
  final int numBlocks;
}

/// Decodes the child CIDs of a raw or DAG-PB block.
List<CID> unixFsLinks(CID cid, Uint8List data) {
  if (cid.codec == 'raw') return const [];
  if (cid.codec != 'dag-pb') {
    throw FormatException('unsupported UnixFS CID codec: ${cid.codec}');
  }
  return [
    for (final link in DagPbNode.fromBytes(data).links)
      CID.fromBytes(link.hash),
  ];
}

/// Streams file bytes in UnixFS link order without materializing the file.
Stream<Uint8List> readUnixFs(
  CID root,
  Future<blocks.Block> Function(CID cid) getBlock,
) async* {
  final block = await getBlock(root);
  final bytes = block.rawData();
  if (root.codec == 'raw') {
    yield bytes;
    return;
  }
  if (root.codec != 'dag-pb') {
    throw FormatException('unsupported UnixFS CID codec: ${root.codec}');
  }
  final dag = DagPbNode.fromBytes(bytes);
  final fs = UnixFsData.fromBytes(dag.data);
  if (fs.type != UnixFsDataType.file && fs.type != UnixFsDataType.raw) {
    throw FormatException('UnixFS root is not a regular file: ${fs.type}');
  }
  if (fs.data.isNotEmpty) yield fs.data;
  for (final link in dag.links) {
    yield* readUnixFs(CID.fromBytes(link.hash), getBlock);
  }
}

/// Walks a UnixFS DAG depth-first, deduplicating blocks by CID.
Stream<CID> walkUnixFs(
  CID root,
  Future<blocks.Block> Function(CID cid) getBlock,
) async* {
  final seen = <CID>{};
  Stream<CID> walk(CID cid) async* {
    if (!seen.add(cid)) return;
    yield cid;
    final block = await getBlock(cid);
    for (final child in unixFsLinks(cid, block.rawData())) {
      yield* walk(child);
    }
  }

  yield* walk(root);
}
