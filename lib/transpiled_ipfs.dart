/// Production-ready IPFS (InterPlanetary File System) implementation in Dart.
///
/// This library provides a complete IPFS implementation with support for:
/// - Full IPFS protocol compliance (CID, UnixFS, DAG-PB, Bitswap, DHT)
/// - P2P networking with production-grade cryptography
/// - Multiple deployment modes (offline, gateway, full P2P)
/// - HTTP Gateway and RPC API
/// - Mobile (Flutter) and web platform support
///
/// ## Quick Start
///
/// ### Offline Mode (Local Storage)
/// ```dart
/// import 'package:transpiled_ipfs/transpiled_ipfs.dart';
///
/// void main() async {
///   final node = await IPFSNode.create(
///     IPFSConfig(offline: true),
///   );
///   await node.start();
///
///   // Add content
///   final cid = await node.addFile(data);
///   // print('Added: $cid');
///
///   // Retrieve content
///   final content = await node.get(cid);
///
///   await node.stop();
/// }
/// ```
///
/// ### Gateway Mode (HTTP Server)
/// ```dart
/// final node = await IPFSNode.create(
///   IPFSConfig(
///     offline: true,
///     gateway: GatewayConfig(
///       enabled: true,
///       port: 8080,
///     ),
///   ),
/// );
/// await node.start();
/// // Access at `http://localhost:8080/ipfs/<CID>`

/// ```
///
/// ### Full P2P Mode
/// ```dart
/// final node = await IPFSNode.create(
///   IPFSConfig(offline: false),
/// );
/// await node.start();
/// // print('Peer ID: ${node.peerID}');
/// ```
///
/// ## Features
///
/// ### Core IPFS
/// - **CID v0/v1**: Content identifier support
/// - **UnixFS**: File system with chunking
/// - **DAG-PB**: MerkleDAG operations
/// - **Pinning**: Content persistence
/// - **CAR Files**: Import/export
///
/// ### Networking
/// - **Bitswap 1.2.0**: Block exchange protocol
/// - **Kademlia DHT**: Distributed routing
/// - **PubSub**: Real-time messaging
/// - **MDNS**: Local peer discovery
/// - **Circuit Relay**: NAT traversal
///
/// ### Services
/// - **HTTP Gateway**: Content serving
/// - **RPC API**: go-ipfs compatible
/// - **IPNS**: Mutable naming
/// - **DNSLink**: Domain resolution
/// - **Metrics**: Prometheus compatible
///
/// ## Architecture
///
/// The library is organized into layers:
/// - **Core**: CID, blocks, data structures
/// - **Protocols**: Bitswap, DHT, PubSub
/// - **Services**: Gateway, RPC, IPNS
/// - **Transport**: P2P networking
/// - **Storage**: Local datastore
///
/// ## Security
///
/// Production-grade cryptography:
/// - **secp256k1**: Elliptic curve (128-bit security)
/// - **ChaCha20-Poly1305**: AEAD encryption
/// - **SHA-256**: Content hashing
///
/// ## Platform Support
///
/// - ✅ Mobile (Flutter iOS/Android)
/// - ✅ Web (Dart Web)
/// - ✅ Desktop (Windows/macOS/Linux)
/// - ✅ Server (Dart VM)
///
/// ## Examples
///
/// See the `example/` directory for:
/// - Offline content publishing
/// - P2P networking
/// - HTTP gateway
/// - Full node operation
///
/// ## Learn More
///
/// - [GitHub Repository](https://github.com/jxoesneon/IPFS)
/// - [IPFS Specifications](https://specs.ipfs.tech/)
/// - [API Documentation](https://pub.dev/documentation/dart_ipfs/latest/)
library;

// Multiformats primitives, now their own per-Go-module packages (see
// doc/transpilation/PROGRESS.md).
export 'package:transpiled_cid/transpiled_cid.dart' show CID;
export 'package:transpiled_multibase/transpiled_multibase.dart' show MultibaseUtils;
export 'package:transpiled_multicodec/transpiled_multicodec.dart' show Multicodec;
export 'package:transpiled_multihash/transpiled_multihash.dart'
    show MultihashInfo, MultihashUtils;

// go-libp2p crypto/peer/Noise primitives.
export 'package:transpiled_libp2p/transpiled_libp2p.dart'
    show CryptoUtils, EncryptedData, Ed25519Signer, KeyPairExtensions;

// Original dart_ipfs infrastructure (not a port of any specific Go
// module -- see doc/transpilation/PROGRESS.md's note on dart_ipfs_core's
// dissolution).
export 'src/core/data_structures/block.dart' show Block, IBlock;
export 'src/core/data_structures/block_store.dart' show BlockStoreResult, IBlockStore;
export 'src/core/data_structures/memory_block_store.dart' show InMemoryBlockStore;
export 'src/core/ipld/codecs/ipld_codec.dart' show IPLDCodec;
export 'src/core/ipld/codecs/standard_codecs.dart'
    show DagCborCodec, DagJsonCodec, DagPbCodec, RawCodec;
export 'src/utils/immutable_bytes.dart' show ImmutableBytes;
export 'src/utils/typed_map.dart' show TypedMap;

// Optional pure-Dart QUIC transport (integration glue over the quic_lib
// dependency, not a port of any specific Go module -- see
// doc/transpilation/PROGRESS.md). Only active when NetworkConfig.enableQuic
// is true. On the web a stub is exported so that importing transpiled_ipfs
// does not pull the non-web-compatible quic_lib bundle.
export 'src/transport/quic/quic.dart'
    if (dart.library.html) 'src/transport/quic_stub_public.dart'
    show QuicTransport, QuicConnection, QuicListener;

export 'src/core/config/ipfs_config.dart';
export 'src/core/data_structures/car.dart';
export 'src/core/ipfs_node/ipfs_node.dart';
export 'src/core/ipfs_node/ipfs_web_node.dart';
export 'src/ipfs.dart';
export 'src/protocols/pubsub/pubsub_message.dart';
