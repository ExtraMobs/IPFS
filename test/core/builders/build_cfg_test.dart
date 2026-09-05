import 'package:test/test.dart';
import 'package:transpiled_ipfs/transpiled_ipfs.dart';

void main() {
  test('zero BuildCfg is offline like Kubo', () {
    final cfg = BuildCfg();
    expect(cfg.online, isFalse);
    expect(cfg.config.offline, isTrue);
    expect(cfg.shutdownTimeout, Duration.zero);
  });

  test('online and ExtraOpts preserve Kubo field semantics', () {
    final options = <String, bool>{'pubsub': true};
    final cfg = BuildCfg(online: true, extraOpts: options);
    options['ipnsps'] = true;
    expect(cfg.config.offline, isFalse);
    expect(cfg.extraOpts, {'pubsub': true, 'ipnsps': true});
  });

  test('fromBuildCfg creates and closes an offline node once', () async {
    final node = await IPFSNode.fromBuildCfg(BuildCfg());
    expect(node.isOnline, isFalse);
    final first = node.close();
    final second = node.close();
    expect(identical(first, second), isTrue);
    await first;
  });
}
