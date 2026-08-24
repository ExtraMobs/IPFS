// lib/src/block/block_store.dart
import 'dart:async';

import '../cid/cid.dart';
import '../lifecycle.dart';

import 'block.dart';

/// Point-in-time statistics for a block store.
class BlockStoreStatus {
  /// Creates a status snapshot.
  const BlockStoreStatus({required this.blockCount, required this.totalSize});

  /// Number of blocks currently held.
  final int blockCount;

  /// Combined size in bytes of all held blocks.
  final int totalSize;
}

/// A generic result returned by block store operations.
///
/// [succeeded] indicates whether the operation completed as expected. [value]
/// holds the payload, and [message] provides a human-readable description.
class BlockStoreResult<T> {
  /// Creates a result.
  const BlockStoreResult({
    required this.succeeded,
    required this.value,
    this.message,
  });

  /// Creates a successful result.
  factory BlockStoreResult.success(T value, {String? message}) =>
      BlockStoreResult<T>(succeeded: true, value: value, message: message);

  /// Creates a failed result.
  factory BlockStoreResult.failure(T value, {String? message}) =>
      BlockStoreResult<T>(succeeded: false, value: value, message: message);

  /// Whether the operation succeeded.
  final bool succeeded;

  /// The operation payload.
  final T value;

  /// Optional human-readable message.
  final String? message;
}

/// Interface for block storage operations.
///
/// Extends [ILifecycle] for `start()`/`stop()` rather than redeclaring them,
/// matching the rest of dart_ipfs's Manager/Handler pattern.
abstract class IBlockStore extends ILifecycle {
  /// Retrieves a block by its CID.
  Future<BlockStoreResult<Block?>> getBlock(CID cid);

  /// Stores a block.
  Future<BlockStoreResult<void>> putBlock(Block block);

  /// Removes a block by its CID.
  Future<BlockStoreResult<bool>> removeBlock(CID cid);

  /// Returns true if the block exists.
  Future<bool> hasBlock(CID cid);

  /// Returns all stored blocks.
  Future<List<Block>> getAllBlocks();

  /// Returns a point-in-time snapshot of block count and total size.
  Future<BlockStoreStatus> getStatus();

  /// Removes unreachable blocks and returns the number removed.
  ///
  /// What counts as "unreachable" (e.g. unpinned) is left to the
  /// implementation -- this interface is pin-agnostic by design, since
  /// pinning is a higher-level, protocol-data concern.
  Future<int> gc();
}
