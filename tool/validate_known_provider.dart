import 'dart:io';

import 'package:transpiled_ipfs/transpiled_ipfs.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/validate_known_provider.dart '
      '<cid> <provider-multiaddr>',
    );
    exitCode = 64;
    return;
  }

  final cid = CID.decode(args[0]);
  final node = await IPFSNode.fromBuildCfg(
    BuildCfg(online: true, config: const IPFSConfig(offline: false)),
  );
  try {
    await node.connect(addrInfoFromString(args[1]));
    final block = await node.getBlock(cid);
    stdout.writeln(
      'cid=${block.cid()} bytes=${block.rawData().length} '
      'persisted=${await node.blockstore.has(cid)}',
    );
  } finally {
    await node.close();
  }
}
