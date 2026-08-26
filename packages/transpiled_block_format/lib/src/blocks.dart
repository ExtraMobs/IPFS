import 'dart:typed_data';

import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_multihash/transpiled_multihash.dart';

/// Returned when block data does not match its supplied CID.
final class ErrWrongHash implements Exception {
  /// Creates the hash mismatch error.
  const ErrWrongHash();

  @override
  String toString() => 'data did not match given hash';
}

/// Common block interface.
abstract interface class Block {
  /// Raw block contents.
  Uint8List rawData();

  /// Content identifier for the block.
  CID cid();

  /// Human-readable block representation.
  @override
  String toString();

  /// Structured logging fields.
  Map<String, Object?> loggable();
}

/// A block containing opaque bytes and a CID.
final class BasicBlock implements Block {
  /// Creates a block from [data] and its [cid].
  BasicBlock(this._data, this._cid);

  final Uint8List _data;
  final CID _cid;

  @override
  Uint8List rawData() => _data;

  @override
  CID cid() => _cid;

  /// Multihash bytes contained in the CID.
  Uint8List multihash() => Uint8List.fromList(_cid.multihash.toBytes());

  @override
  String toString() => '[Block ${_cid.toString()}]';

  @override
  Map<String, Object?> loggable() => {'block': _cid.toString()};
}

/// Creates a block using the default CIDv0 SHA-256 format.
BasicBlock newBlock(Uint8List data) {
  final digest = MultihashUtils.sum('sha2-256', data).digest;
  return BasicBlock(data, CID.v0(Uint8List.fromList(digest)));
}

/// Creates a block using a CID prefix.
BasicBlock newBlockWithPrefix(Uint8List data, Prefix prefix) =>
    BasicBlock(data, prefix.sum(data));

/// Creates a block from a precomputed CID.
BasicBlock newBlockWithCid(Uint8List data, CID cid) {
  // Go validates only when boxo/util.Debug is enabled; its default is false.
  // Keep the normal runtime path allocation-free and accept trusted CIDs.
  return BasicBlock(data, cid);
}
