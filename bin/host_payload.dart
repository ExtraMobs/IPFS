// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:transpiled_block_format/transpiled_block_format.dart' as blocks;
import 'package:transpiled_boxo/transpiled_boxo.dart' hide Blockstore;
import 'package:transpiled_ipfs/transpiled_ipfs.dart';

Future<void> main(List<String> args) async {
  print('============================================================');
  print('          DART IPFS - P2P SERVING NODE DAEMON              ');
  print('============================================================');

  // Generate a cryptographically secure random sequence
  final rng = Random.secure();
  final randomBytes = List<int>.generate(24, (_) => rng.nextInt(256));
  final randomHex = randomBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final timestamp = DateTime.now().toUtc().toIso8601String();
  final secretSequence = 'Dart-IPFS-Live-Proof-[$timestamp]-$randomHex';

  print('\n>>> SEQUENCIA ALEATORIA GERADA:');
  print(secretSequence);
  print('------------------------------------------------------------');

  final textBytes = utf8.encode(secretSequence);

  // Configure IPFS node on port 4002 (to avoid conflict with Kubo port 4001)
  const config = IpfsConfig(
    offline: false,
    network: NetworkConfig(
      listenAddresses: ['/ip4/0.0.0.0/tcp/4002'],
      bootstrapPeers: [
        // Public IPFS bootstrapper (mars.i.ipfs.io)
        '/ip4/104.131.131.82/tcp/4001/p2p/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ',
        // Local Kubo node
        '/ip4/127.0.0.1/tcp/4001/p2p/12D3KooWBvCyh8Vezjcwjhe2etkvjxw7g8hx9SW4jP5c94yXkyX1',
      ],
    ),
  );

  print('\nIniciando nó Dart IPFS...');
  final node = await IpfsNode.fromBuildCfg(
    BuildCfg(config: config, online: true),
  );

  final peerId = node.peerId.toBase58();
  print('Nó Dart IPFS online!');
  print('PeerId: $peerId');

  // Compute addresses
  final localAddrs = [
    '/ip4/127.0.0.1/tcp/4002/p2p/$peerId',
    '/ip4/192.168.1.4/tcp/4002/p2p/$peerId',
    '/ip4/187.62.8.47/tcp/4002/p2p/$peerId',
  ];

  print('\nSwarm Multiaddresses do nó Dart:');
  for (final addr in localAddrs) {
    print('  * $addr');
  }

  // 1. Store as UnixFS DAG (CIDv0 - Qm...) for `ipfs cat` and gateways
  final importResult = await buildDagFromReader(
    Stream.value(textBytes),
    cidVersion: 0,
    retainBlocks: true,
    onBlock: (block) async {
      await node.putBlock(blocks.BasicBlock.withCid(block.data, block.cid));
    },
  );
  final unixFsCid = importResult.root;

  // 2. Also store as Raw block for direct block retrieval
  final rawCid = await node.putRawBlock(Uint8List.fromList(textBytes));

  print('\n------------------------------------------------------------');
  print('>>> IDENTIFICADORES DE CONTEUDO (CIDs):');
  print('  * UnixFS CID (Arquivo de texto para `ipfs cat`):');
  print('    ${unixFsCid.encode()}');
  print('  * Raw Block CID (Bloco puro para `ipfs block get`):');
  print('    ${rawCid.encode()}');
  print('------------------------------------------------------------');

  // Connect to peers
  print('\nConectando aos pares de rede e bootstrap...');
  for (final boot in config.network.bootstrapPeers) {
    try {
      await node.connect(addrInfoFromString(boot));
      print('  Conectado: $boot');
    } catch (e) {
      print('  Aviso ao conectar em $boot: $e');
    }
  }

  // Announce CIDs
  Future<void> announceAll() async {
    print('\n[${DateTime.now()}] Anunciando CIDs na DHT e Swarm...');
    try {
      await node.provide(unixFsCid);
      print('  UnixFS CID anunciado com sucesso: ${unixFsCid.encode()}');
    } catch (e) {
      print('  Falha ao anunciar UnixFS CID: $e');
    }

    try {
      await node.provide(rawCid);
      print('  Raw CID anunciado com sucesso: ${rawCid.encode()}');
    } catch (e) {
      print('  Falha ao anunciar Raw CID: $e');
    }
  }

  await announceAll();

  // Periodic republishing every 10 minutes to maintain DHT freshness
  final timer = Timer.periodic(const Duration(minutes: 10), (_) => announceAll());

  print('\n============================================================');
  print('>>> NÓ DART ATIVO E HOSPEDANDO O ARQUIVO EM TEMPO REAL <<<');
  print('============================================================');
  print('\nPara verificar em outro terminal ou nó externo:');
  print('1) Se estiver na mesma máquina ou rede local (Kubo / IPFS Desktop):');
  print('   \$env:IPFS_PATH="B:\\IPFS\\.ipfs"; ipfs cat ${unixFsCid.encode()}');
  print('   OU: ipfs swarm connect /ip4/127.0.0.1/tcp/4002/p2p/$peerId');
  print('       ipfs cat ${unixFsCid.encode()}');
  print('\n2) Para buscar o bloco puro:');
  print('   ipfs block get ${rawCid.encode()}');
  print('\n3) Para consultar descoberta na DHT:');
  print('   ipfs routing findprovs ${unixFsCid.encode()}');
  print('\n(Aguardando conexoes e requisicoes de blocos Bitswap...)');

  // Keep daemon alive indefinitely
  final completer = Completer<void>();
  try {
    ProcessSignal.sigint.watch().listen((_) async {
      print('\nEncerrando daemon...');
      timer.cancel();
      await node.close();
      print('Nó Dart IPFS finalizado.');
      completer.complete();
      exit(0);
    });
  } catch (_) {}

  await completer.future;
}
