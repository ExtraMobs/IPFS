import 'dart:typed_data';

import 'package:base32/base32.dart' as base32;
import 'package:transpiled_block_format/transpiled_block_format.dart' as blocks;
import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_datastore/transpiled_datastore.dart';

/// Returned when a requested block is absent.
final class BlockstoreNotFoundException implements Exception {
  /// Creates a missing-block error.
  const BlockstoreNotFoundException(this.cid);

  /// Missing CID.
  final CID cid;

  @override
  String toString() => 'blockstore: block not found: $cid';
}

/// Returned when bytes do not match their content identifier.
final class BlockstoreHashMismatchException implements Exception {
  /// Creates a hash-mismatch error.
  const BlockstoreHashMismatchException(this.cid);

  /// Expected CID.
  final CID cid;

  @override
  String toString() => 'blockstore: data did not match $cid';
}

/// Minimal Boxo-compatible blockstore over a go-datastore port.
final class Blockstore {
  /// Creates an in-memory blockstore unless [datastore] is supplied.
  Blockstore({Datastore? datastore}) : _datastore = datastore ?? MapDatastore();

  final Datastore _datastore;

  /// Reports whether [cid] is stored.
  Future<bool> has(CID cid) => _datastore.has(_key(cid));

  /// Returns the encoded block size without loading its bytes.
  Future<int> getSize(CID cid) async {
    try {
      return await _datastore.getSize(_key(cid));
    } on NotFoundException {
      throw BlockstoreNotFoundException(cid);
    }
  }

  /// Returns the block named by [cid], validating its bytes before returning.
  Future<blocks.Block> get(CID cid) async {
    final List<int> value;
    try {
      value = await _datastore.get(_key(cid));
    } on NotFoundException {
      throw BlockstoreNotFoundException(cid);
    }
    final data = Uint8List.fromList(value);
    _validate(cid, data);
    return blocks.BasicBlock(data, cid);
  }

  /// Stores [block] after validating its CID.
  Future<void> put(blocks.Block block) async {
    final cid = block.cid();
    final data = Uint8List.fromList(block.rawData());
    _validate(cid, data);
    if (await has(cid)) return;
    await _datastore.put(_key(cid), data);
  }

  /// Stores all [values], validating every CID before any write.
  Future<void> putMany(Iterable<blocks.Block> values) async {
    final pending = <({CID cid, Uint8List data})>[];
    for (final block in values) {
      final cid = block.cid();
      final data = Uint8List.fromList(block.rawData());
      _validate(cid, data);
      pending.add((cid: cid, data: data));
    }
    for (final value in pending) {
      if (!await has(value.cid)) {
        await _datastore.put(_key(value.cid), value.data);
      }
    }
  }

  /// Releases the underlying datastore.
  Future<void> close() => _datastore.close();

  static Key _key(CID cid) {
    final encoded = base32.base32
        .encode(cid.multihash.toBytes())
        .replaceAll('=', '')
        .toUpperCase();
    return Key('/blocks/$encoded');
  }

  static void _validate(CID cid, Uint8List data) {
    if (cid.prefix.sum(data) != cid) {
      throw BlockstoreHashMismatchException(cid);
    }
  }
}
