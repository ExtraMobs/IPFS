# Changelog

All notable changes to this package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.12.0] - Unreleased

### Fixed
- `MultibaseUtils`'s base32 encode/decode no longer delegates to
  `package:multibase`, which was found to diverge from RFC 4648 for most
  inputs (107/123 cases in an empirical sweep), not just the previously
  suspected leading-zero-byte edge case. Routes through the same corrected
  algorithm the umbrella package already uses for this reason.

### Added
- `CID.validate()`, `CID.fromPrefixBytes()`, `CID.computeForData()`,
  `CID.computeForDataSync()`, and `hashType`/`version` parameters on
  `CID.fromContent()` -- closing the gap with the umbrella's `CID` for
  every method that doesn't require protobuf (`fromProto`/`toProto`
  intentionally remain umbrella-only).
- `ILifecycle`, the canonical `start()`/`stop()` contract, promoted from
  the umbrella package. `IBlockStore` now extends it instead of
  redeclaring `start()`/`stop()`.
- `IBlockStore.getStatus()` and `IBlockStore.gc()`, plus the
  `BlockStoreStatus` value class, for parity with the umbrella's
  proto-coupled block store interface's non-proto capabilities.

## [1.11.5] - Unreleased

### Added
- Initial extraction of `dart_ipfs_core` from the `dart_ipfs` umbrella package.
- Stable core primitives: `CID`, `MultibaseUtils`, `Multicodec`, `MultihashInfo`, `MultihashUtils`.
- Block abstractions: `Block`, `IBlock`, `IBlockStore`, `BlockStoreResult`, `InMemoryBlockStore`.
- Common codecs: `IPLDCodec`, `RawCodec`, `DagCborCodec`, `DagJsonCodec`.
- Cryptographic helpers: `CryptoUtils`, `EncryptedData`, `Ed25519Signer`, `KeyPairExtensions`.
- Small immutable data structures: `ImmutableBytes`, `TypedMap`.
