import 'dart:io';

import 'package:transpiled_ipfs/src/core/config/ipfs_config.dart';
import 'package:transpiled_ipfs/src/core/ipfs_node/ipfs_node.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/validate_public_p2p.dart <cid>');
    exitCode = 64;
    return;
  }

  final cid = args.single;
  final root =
      '.tmp-validation/public-p2p-${DateTime.now().microsecondsSinceEpoch}';
  final node = await IPFSNode.create(
    IPFSConfig(
      dataPath: root,
      datastorePath: '$root/datastore',
      keystorePath: '$root/keystore',
      blockStorePath: '$root/blocks',
      libp2pListenAddress: '/ip4/127.0.0.1/tcp/4412',
      enablePubSub: false,
      enableGraphsync: false,
      enableRPC: false,
      bitswap: const BitswapConfig(
        enableHttpFallback: false,
        p2pTimeout: Duration(minutes: 2),
      ),
    ),
  );

  try {
    await node.start();
    stdout.writeln('peer=${node.peerID}');
    final block = await node.bitswap!.getBlock(cid, useHttpFallback: false);
    if (block == null) throw StateError('P2P block not found: $cid');
    final cached = await node.blockStore.getBlock(cid);
    if (!cached.found) throw StateError('Block was not persisted: $cid');
    stdout.writeln(
      'cid=${block.cid.encode()} bytes=${block.data.length} persisted=true',
    );
  } finally {
    await node.stop();
  }
}
