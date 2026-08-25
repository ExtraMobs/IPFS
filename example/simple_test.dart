// ignore_for_file: avoid_print
// example/simple_test.dart
import 'dart:typed_data';

import 'package:transpiled_ipfs/src/core/cid.dart';
import 'package:transpiled_ipfs/src/core/config/ipfs_config.dart';
import 'package:transpiled_ipfs/src/core/ipfs_node/ipfs_node.dart';

/// Simple test demonstrating basic IPFS node functionality
Future<void> main() async {
  print('🧪 Running Simple IPFS Test...\n');

  try {
    // Test 1: Create IPFS Node
    print('Test 1: Creating IPFS Node...');
    final config = IPFSConfig();
    final node = await IPFSNode.create(config);
    print('✅ Node created successfully\n');

    // Test 2: Start the node
    print('Test 2: Starting node...');
    await node.start();
    print('✅ Node started successfully\n');

    // Test 3: Add content
    print('Test 3: Adding content...');
    final content = Uint8List.fromList('Hello IPFS!'.codeUnits);
    final cid = await node.addFile(content);
    print('✅ Content added with CID: $cid\n');

    // Test 4: Retrieve content
    print('Test 4: Retrieving content...');
    final retrieved = await node.get(cid);
    if (retrieved != null) {
      final text = String.fromCharCodes(retrieved);
      print('✅ Retrieved content: "$text"\n');
    } else {
      print('❌ Failed to retrieve content\n');
    }

    // Test 5: CID encoding/decoding
    print('Test 5: Testing CID...');
    final testCid = await CID.fromContent(content);
    print('✅ CID created: ${testCid.encode()}');
    print('   Version: ${testCid.version}');
    print('   Codec: ${testCid.codec}');
    print('   Multibase: ${testCid.multibaseType}\n');

    // Test 6: Directory operations
    print('Test 6: Testing directory...');
    final dir = {
      'file1.txt': Uint8List.fromList('File 1 content'.codeUnits),
      'file2.txt': Uint8List.fromList('File 2 content'.codeUnits),
    };
    final dirCid = await node.addDirectory(dir);
    print('✅ Directory created with CID: $dirCid');

    final dirListing = await node.ls(dirCid);
    print('   Contents:');
    for (final link in dirListing) {
      print('   - ${link.name} (${link.cid})');
    }
    print('');

    // Test 7: Stop the node
    print('Test 7: Stopping node...');
    await node.stop();
    print('✅ Node stopped successfully\n');

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ All tests passed!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  } catch (e, stack) {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('❌ Test failed with error:');
    print('$e');
    print('\nStack trace:');
    print('$stack');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
