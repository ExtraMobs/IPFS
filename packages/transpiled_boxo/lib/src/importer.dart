import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:transpiled_cid/transpiled_cid.dart';

import 'chunker.dart';
import 'dag_pb.dart';
import 'unixfs.dart';

const int defaultLinksPerBlock = 174;

/// A block emitted by the importer. [fileSize] is logical UnixFS file data;
/// [cumulativeSize] is the DAG-PB link Tsize value.
class UnixFsBlock {
  UnixFsBlock(
    this.cid,
    this.data, {
    required this.raw,
    required this.fileSize,
    required this.cumulativeSize,
  });
  final CID cid;
  final Uint8List data;
  final bool raw;
  final int fileSize;
  final int cumulativeSize;
}

/// The root CID and, when requested, retained emitted blocks.
class UnixFsImportResult {
  UnixFsImportResult(this.root, Iterable<UnixFsBlock> blocks)
    : blocks = List.unmodifiable(blocks);
  final CID root;
  final List<UnixFsBlock> blocks;
}

/// Imports a regular file into Boxo's balanced UnixFS layout.
class BalancedUnixFsImporter {
  BalancedUnixFsImporter({
    this.chunkSize = defaultBlockSize,
    this.maxLinks = defaultLinksPerBlock,
    this.cidVersion = 0,
    this.rawLeaves = false,
    this.retainBlocks = false,
    this.onBlock,
  }) : assert(chunkSize > 0),
       assert(maxLinks > 0 && maxLinks <= defaultLinksPerBlock),
       assert(cidVersion == 0 || cidVersion == 1) {
    if (chunkSize <= 0) throw ArgumentError.value(chunkSize, 'chunkSize');
    if (maxLinks <= 0 || maxLinks > defaultLinksPerBlock) {
      throw ArgumentError.value(maxLinks, 'maxLinks', 'must be 1..174');
    }
    if (cidVersion != 0 && cidVersion != 1) {
      throw ArgumentError.value(cidVersion, 'cidVersion', 'must be 0 or 1');
    }
  }

  final int chunkSize;
  final int maxLinks;
  final int cidVersion;
  final bool rawLeaves;
  final bool retainBlocks;
  final FutureOr<void> Function(UnixFsBlock block)? onBlock;

  int get _version => cidVersion == 1 || rawLeaves ? 1 : 0;

  Future<UnixFsImportResult> importStream(Stream<List<int>> input) async {
    final blocks = <UnixFsBlock>[];
    final reader = _LeafReader(
      FixedSizeChunker(input, size: chunkSize).chunks(),
      raw: rawLeaves,
      version: _version,
      retain: retainBlocks,
      blocks: blocks,
      onBlock: onBlock,
    );
    final first = await reader.next();
    if (first == null) {
      final root = await reader.make(
        Uint8List(0),
        raw: false,
        fileSize: 0,
        links: const [],
      );
      return UnixFsImportResult(root.cid, blocks);
    }
    var root = first;
    if (!await reader.ensure()) return UnixFsImportResult(root.cid, blocks);

    var depth = 1;
    while (await reader.ensure()) {
      root = await _fill(depth, reader, root);
      depth++;
    }
    return UnixFsImportResult(root.cid, blocks);
  }

  Future<UnixFsImportResult> importFile(String path) =>
      importStream(File(path).openRead());

  Future<UnixFsBlock> _fill(
    int depth,
    _LeafReader reader,
    UnixFsBlock initial,
  ) async {
    final children = <UnixFsBlock>[initial];
    final sizes = <int>[initial.fileSize];
    while (children.length < maxLinks && await reader.ensure()) {
      if (depth == 1) {
        final child = await reader.next();
        if (child == null) break;
        children.add(child);
        sizes.add(child.fileSize);
      } else {
        final child = await _fill(
          depth - 1,
          reader,
          await reader.nextInternal(),
        );
        children.add(child);
        sizes.add(child.fileSize);
      }
    }
    return _makeInternal(children, sizes, reader);
  }

  Future<UnixFsBlock> _makeInternal(
    List<UnixFsBlock> children,
    List<int> sizes,
    _LeafReader reader,
  ) async {
    final links = [
      for (final child in children)
        DagPbLink.fromCid(child.cid, tsize: child.cumulativeSize),
    ];
    final fileSize = sizes.fold(0, (a, b) => a + b);
    final data = UnixFsData(
      UnixFsDataType.file,
      filesize: fileSize,
      blocksizes: sizes,
    ).toBytes();
    final encoded = DagPbNode(data: data, links: links).toBytes();
    final cumulative = children.fold<int>(
      encoded.length,
      (total, child) => total + child.cumulativeSize,
    );
    return reader.make(
      data,
      raw: false,
      fileSize: fileSize,
      links: links,
      cumulativeSize: cumulative,
    );
  }
}

class _LeafReader {
  _LeafReader(
    this._chunks, {
    required this.raw,
    required this.version,
    required this.retain,
    required this.blocks,
    required this.onBlock,
  });

  final Stream<Uint8List> _chunks;
  final bool raw;
  final int version;
  final bool retain;
  final List<UnixFsBlock> blocks;
  final FutureOr<void> Function(UnixFsBlock block)? onBlock;
  late final StreamIterator<Uint8List> _iterator = StreamIterator(_chunks);
  Uint8List? _pending;

  bool get hasNext => _pending != null;

  Future<bool> ensure() async {
    if (_pending != null) return true;
    if (!await _iterator.moveNext()) return false;
    _pending = _iterator.current;
    return true;
  }

  Future<UnixFsBlock?> next() async {
    if (!await ensure()) return null;
    final bytes = _pending!;
    _pending = null;
    if (!raw) {
      final data = UnixFsData(
        UnixFsDataType.file,
        data: bytes,
        filesize: bytes.length,
      ).toBytes();
      return make(
        data,
        raw: false,
        fileSize: bytes.length,
        links: const [],
        cumulativeSize: null,
      );
    }
    return make(
      bytes,
      raw: true,
      fileSize: bytes.length,
      links: const [],
      cumulativeSize: bytes.length,
    );
  }

  Future<UnixFsBlock> nextInternal() async => (await next())!;

  Future<UnixFsBlock> make(
    Uint8List payload, {
    required bool raw,
    required int fileSize,
    required List<DagPbLink> links,
    int? cumulativeSize,
  }) async {
    final bytes = raw
        ? payload
        : DagPbNode(data: payload, links: links).toBytes();
    final cid = await CID.fromContent(
      bytes,
      codec: raw ? 'raw' : 'dag-pb',
      version: raw ? 1 : version,
    );
    final block = UnixFsBlock(
      cid,
      bytes,
      raw: raw,
      fileSize: fileSize,
      cumulativeSize: cumulativeSize ?? bytes.length,
    );
    if (retain) blocks.add(block);
    if (onBlock != null) await onBlock!(block);
    return block;
  }
}

/// Boxo's balanced reader importer with Dart stream input.
Future<UnixFsImportResult> buildDagFromReader(
  Stream<List<int>> input, {
  int chunkSize = defaultBlockSize,
  int maxLinks = defaultLinksPerBlock,
  int cidVersion = 0,
  bool rawLeaves = false,
  bool retainBlocks = false,
  FutureOr<void> Function(UnixFsBlock block)? onBlock,
}) => BalancedUnixFsImporter(
  chunkSize: chunkSize,
  maxLinks: maxLinks,
  cidVersion: cidVersion,
  rawLeaves: rawLeaves,
  retainBlocks: retainBlocks,
  onBlock: onBlock,
).importStream(input);
