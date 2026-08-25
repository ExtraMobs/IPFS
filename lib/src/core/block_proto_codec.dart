// lib/src/core/block_proto_codec.dart
//
// Protobuf and Bitswap-protobuf (de)serialization for Block, kept out of
// Block itself so a protocol-agnostic Block (now real, local content --
// see lib/src/core/data_structures/block.dart, dissolved back into
// transpiled_ipfs from the former dart_ipfs_core package (dissolved); see
// doc/transpilation/PROGRESS.md) doesn't need to depend on generated
// protobuf code.
//
// `block.toProto()`/`block.toBitswapProto()` keep working unchanged for
// existing call sites via the extension below -- Dart extension methods
// use ordinary dot-call syntax. `Block.fromProto(proto)` and
// `Block.fromBitswapProto(proto)` cannot be extensions (Dart doesn't allow
// extending a class with new static factories), so they become the
// top-level `blockFromProto(proto)` / `blockFromBitswapProto(proto)`
// functions; call sites update accordingly.
import 'dart:typed_data';

import '../proto/generated/bitswap/bitswap.pb.dart' as bitswap_pb;
import '../proto/generated/core/block.pb.dart';
import 'cid_proto_codec.dart';
import 'data_structures/block.dart';

/// Adds protobuf and Bitswap-protobuf serialization to [Block].
extension BlockProtoCodec on Block {
  /// Converts this block to its protobuf representation.
  BlockProto toProto() {
    return BlockProto()
      ..cid = cid.toProto()
      ..data = data
      ..format = format;
  }

  /// Converts this block to its Bitswap protobuf representation.
  bitswap_pb.Message_Block toBitswapProto() {
    return bitswap_pb.Message_Block()
      ..data = data
      ..prefix = cid.toBytes();
  }
}

/// Creates a [Block] from its protobuf representation.
Block blockFromProto(BlockProto proto) {
  return Block(
    cid: cidFromProto(proto.cid),
    data: Uint8List.fromList(proto.data),
    format: proto.format,
  );
}

/// Creates a [Block] from its Bitswap protobuf representation.
Future<Block> blockFromBitswapProto(
  bitswap_pb.Message_Block protoBlock,
) async {
  return Block.fromData(Uint8List.fromList(protoBlock.data));
}
