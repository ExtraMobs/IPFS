# RFC: Native QUIC Transport for dart_ipfs

## Status

**Updated v1.2** — Investigated during the `refactor/core-module-split`
transpilation session (2026-08-25) after a real-node test surfaced a QUIC
dial failure. Found and fixed a small, real bug (`QuicTransport.canDial`/
`canListen` claimed `/quic-v1/webtransport` addresses that belong to
WebTransport, breaking WebTransport whenever QUIC was also enabled) — see
`packages/dart_ipfs_quic/lib/src/quic_transport.dart`'s `_isQuicAddr`.

That fix aside, **native QUIC dialing to a real peer is confirmed broken by
architecture, not by a fixable implementation gap**, and is being archived
here as a known, deliberately-unresolved limitation rather than worked
around. See "Architectural blocker (2026-08-25)" below for the full finding
before attempting further QUIC work — it changes what "finish QUIC" would
actually require.

**Updated v1.1** — The project now uses the pure-Dart `quic_lib` package as the
QUIC transport foundation. The previous quiche FFI foundation has been removed
from `packages/dart_ipfs_quic`. The conditional QUIC_SPEC requirements (config,
runtime probe, TCP fallback) remain implemented in
`lib/src/core/config/network_config.dart` and
`lib/src/transport/libp2p_router.dart`. This RFC records the rationale and
remaining work toward a Kubo/Helia-interoperable QUIC transport.

## Architectural blocker (2026-08-25)

Reproduced a QUIC-only dial (no TCP fallback available) against a real
bootstrap.libp2p.io peer and got:

```
Exception: Unsupported operation: QuicConnection does not support raw
transport writes; use streams.
```

Root cause: `package:ipfs_libp2p`'s `Swarm`/`BasicUpgrader`
(`lib/p2p/transport/basic_upgrader.dart`) unconditionally runs, for
**every** transport with no exceptions: multistream-select for a security
protocol → `SecurityProtocol.secureOutbound`/`secureInbound` (reading/
writing raw bytes on the `TransportConn`) → multistream-select for a stream
muxer → muxer negotiation over the now-secured connection. There is no
extension point in `Transport`, `Swarm`, or `BasicUpgrader` for a transport
that is already self-securing and self-multiplexing at the transport layer
— which is exactly what real libp2p-over-QUIC is (RFC: authentication lives
in the QUIC/TLS 1.3 handshake via a certificate extension, ​multiplexing is
QUIC's own native stream mechanism; there is no separate security or muxer
negotiation step at all). `QuicConnection.read()`/`write()`
(`packages/dart_ipfs_quic/lib/src/quic_transport.dart`) deliberately throw
`UnsupportedError` because there is no "raw byte stream" to speak of for a
spec-compliant QUIC connection — and that assumption crashes the instant
`BasicUpgrader` tries to run its hardcoded pipeline on top.

Worse: this isn't only a dialing problem. `Swarm.newStream()` — what
`Host.newStream()` calls, and therefore what **every** existing protocol
handler (DHT, Bitswap, Identify) goes through to open a stream to a peer —
hard-casts its connection to `SwarmConn`, an internal (non-exported) class
of `ipfs_libp2p`:

```dart
if (conn is! SwarmConn) {
  throw StateError('Connection from dialPeer is not a SwarmConn. ...');
}
```

So a QUIC connection can only ever be usable by dart_ipfs's *existing*
protocol stack if it is produced by `Swarm`'s own transport-dial path — the
exact path that forces the Noise+muxer negotiation QUIC doesn't use in
reality. Being both (a) spec-compliant/interoperable with real
go-libp2p/rust-libp2p QUIC peers and (b) usable by the DHT/Bitswap/Identify
code as written today are **mutually exclusive** without editing
`ipfs_libp2p` itself (a third-party pub.dev dependency, not editable in
this repo — same constraint documented for the Noise fix in
`doc/transpilation/PROGRESS.md`'s `p2p/security/noise` row).

Genuinely finishing QUIC therefore means one of:

1. A self-consistent-but-non-interoperable QUIC: keep running Noise+yamux
   (already built for TCP) over a QUIC-backed byte pipe. Works between two
   dart_ipfs nodes; does **not** work against real external QUIC peers,
   since they don't expect that extra negotiation on a QUIC connection at
   all. Moderate effort, fits the existing `Swarm`-based architecture.
2. Real libp2p-QUIC (TLS-cert auth via `quic_lib`'s already-partially-built
   `Libp2pTlsHandshakeVerifier`/`Libp2pCertificateGenerator`, native QUIC
   stream multiplexing, no extra negotiation) **plus** a parallel
   implementation of the DHT/Bitswap/Identify stream-opening paths that
   bypasses `Swarm` entirely for QUIC connections, since option (2) alone
   produces a connection nothing in the existing protocol stack can use.
   This is not "finish the QUIC transport" scope — it's closer to forking
   large parts of the protocol-handler layer for a second, QUIC-specific
   connection-management path. Multi-week scale, real regression risk to
   the working TCP stack if the duplication isn't kept carefully separate.

**Decision (2026-08-25): neither was pursued.** Given TCP already provides
proven real-network connectivity (see `p2p/security/noise` in
`doc/transpilation/PROGRESS.md` — bootstrap.libp2p.io peers connect and
stay connected), this is being left as a documented, deliberate gap rather
than committing to either path speculatively. Revisit only with a concrete
reason QUIC connectivity is needed (e.g. a peer reachable only over QUIC),
and re-read this section first — it changes the shape of "Recommended Next
Steps" below.

## Background

`package:ipfs_libp2p` 0.5.6 only exports `TCPTransport` and `UdxTransport`. No
`QuicTransport` class or `/quic` multiaddr support is exposed. The dart_ipfs
router therefore probes for QUIC availability at runtime and falls back to
TCP when QUIC is unavailable.

Goal: provide a native QUIC transport without requiring changes to
`package:ipfs_libp2p` and without native FFI build dependencies.

## Options Evaluated

| Option | License | Pros | Cons | Verdict |
|--------|---------|------|------|---------|
| `flutter_quic` | MIT | Pure Quinn Rust backend, desktop + mobile, full QUIC | Flutter-only plugin; dart_ipfs is a pure Dart/VM package; adds Rust build toolchain to consumers | Rejected for core package |
| `pure_dart_quic` | GPL-3.0 | Pure Dart, no native build | GPL copy-incompatible with MIT project; experimental | Rejected |
| `quic` (pub.dev) | GPL-3.0 | Pure Dart | GPL copy-incompatible; 5 years old, unlisted | Rejected |
| `Dusty-Quiche` | No license | FFI to quiche | No explicit license; stale; build issues reported | Rejected |
| quiche FFI (new bindings) | BSD-2 (quiche) | Battle-tested, Cloudflare maintained, C API | Requires native library build per platform; requires custom Dart transport wrapper | Replaced |
| **quic_lib (custom pure-Dart package)** | MIT | Full pure-Dart QUIC, HTTP/3, WebTransport, libp2p transport exports; no native build; license-compatible | libp2p `Transport`/`Conn`/`Listener` adapter layer required; Kubo interop not yet proven | **Selected** |
| **msquic FFI** | MIT (msquic) | Microsoft maintained, C API | C API is `msquic.h` (C headers) but bindings are C++/C# oriented; less Rust/Dart ecosystem precedent | Alternative |
| Implement QUIC from scratch in Dart | MIT | No native dependency | High security risk, high maintenance | Superseded by quic_lib |

## Maintainer Decision
The project maintainers deliberated on native QUIC strategy. After the user
provided the `quic_lib` package, the maintainers updated their verdict:

- **Coherence**: 9/10 for `quic_lib` — pure-Dart aligns with the project's
  goal of minimizing native build/toolchain dependencies for consumers.
- **Capability**: 7/10 for `quic_lib` — a full QUIC wire-format, HTTP/3,
  WebTransport, and libp2p transport layer exists; only the adapter to
  `package:ipfs_libp2p`'s `Transport`/`Conn`/`Listener` interfaces is needed.
- **Safety**: 7/10 for `quic_lib` — well-structured pure-Dart code with
  comprehensive tests; avoids FFI memory-safety risks and native binary
  distribution.
- **Efficiency**: 7/10 for `quic_lib` — removes the Rust build step and
  native-assets complexity, but requires adapter and interop testing.
- **Evolution**: 8/10 for `quic_lib` — creates a reusable pure-Dart QUIC
  stack that can be published independently.

**Outcome**: Replace the quiche FFI foundation in `packages/dart_ipfs_quic`
with a `quic_lib` adapter. The transport remains behind the `enableQuic`
flag and TCP fallback is preserved. Do not ship a half-integrated transport
that advertises `/quic-v1` without full libp2p security handshake support and
proven Kubo/Helia interop.

## Architecture

```
┌──────────────────────────────────────┐
│  dart_ipfs Libp2pRouter              │
│  (probes / enableQuic / fallback)    │
└────────────┬─────────────────────────┘
             │ imports package:dart_ipfs_quic
┌────────────▼─────────────────────────┐
│  packages/dart_ipfs_quic             │
│  ┌──────────────────────────────┐  │
│  │ QuicTransport                │  │
│  │ (implements                │  │
│  │ package:ipfs_libp2p Transport)│  │
│  ├──────────────────────────────┤  │
│  │ QuicConnection               │  │
│  │ QuicListener                 │  │
│  └──────────────────────────────┘  │
└────────────┬─────────────────────────┘
             │ imports package:quic_lib
┌────────────▼─────────────────────────┐
│  quic_lib (pure-Dart)                │
│  ┌──────────────────────────────┐  │
│  │ Libp2pQuicTransport          │  │
│  │ Libp2pQuicConnection         │  │
│  │ QuicEndpoint / QuicConnection│  │
│  │ libp2p TLS extension         │  │
│  └──────────────────────────────┘  │
└──────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Foundation (completed)

- `packages/dart_ipfs_quic` package created.
- `quic_lib` dependency added (pure-Dart QUIC stack).
- `QuicTransport` implementing `package:ipfs_libp2p` `Transport`:
  - `protocols`: `/ip4/udp/quic-v1`, `/ip6/udp/quic-v1`.
  - `canDial` / `canListen`: match QUIC multiaddr components.
  - `dial`: delegate to `quic_lib.Libp2pQuicTransport.dial` and wrap in
    `QuicConnection`.
  - `listen`: delegate to `quic_lib.Libp2pQuicTransport.listen` and wrap in
    `QuicListener`.
- `QuicConnection` and `QuicListener` adapters implementing the required
  libp2p interfaces.
- Unit tests verifying `Transport` interface compliance.

### Phase 2: UDP I/O Loop

- `quic_lib` already provides the QUIC endpoint and UDP I/O loop.
- Verify that `Libp2pQuicTransport` binds the correct local address and can
  receive incoming Initial packets.

### Phase 3: libp2p Transport Wrapper (completed)

- `QuicConnection.newStream` now opens a real QUIC bidirectional stream and
  wraps it in `QuicP2PStream`.
- `QuicP2PStream` maps `quic_lib` stream data to the `P2PStream.read`/`write`
  contract.
- `localMultiaddr`, `remoteMultiaddr`, `localPeer`, and `remotePeer` are
  provided from the connection metadata.

### Phase 4: libp2p Security Handshake (partial)

- libp2p QUIC requires TLS 1.3 with a self-signed certificate containing the
  peer's public key (per
  [libp2p QUIC spec](https://github.com/libp2p/specs/blob/master/transports/quic.md)).
- `QuicConnection` now exposes `verifyPeer()` for ALPN validation and
  `verifyPeerCertificate()` for libp2p TLS extension verification.
- `quic_lib`'s `Libp2pCertificateGenerator` is used to produce test
  certificates and the extension parser validates them.
- The remaining gap is automatic extraction of the peer's certificate bytes
  from the live `quic_lib` handshake. Once `quic_lib` exposes those bytes,
  `verifyPeerCertificate()` can be invoked automatically during connection
  establishment. Until then, Kubo/Helia interoperability is not yet
  complete.

### Phase 5: Integration & Testing

- Wire `QuicTransport` into `Libp2pRouter` when `enableQuic` is true.
- Add interop tests against a local Kubo/Helia node.
- Add CI for `dart_ipfs_quic` and `quic_lib` tests on Windows, Linux, macOS.

## Build & Distribution

No native library build is required. `quic_lib` is pure Dart and is resolved
as a normal `pub` dependency.

### Dependency

`packages/dart_ipfs_quic/pubspec.yaml` references `quic_lib` as a path
dependency to the local checkout during development:

```yaml
dependencies:
  quic_lib:
    path: ../../../dart_quic
```

Production releases use the hosted pub.dev package (`quic_lib: ^1.10.0` or
newer).

### CI

Run `dart pub get` followed by `dart test` for both `quic_lib` and
`packages/dart_ipfs_quic`.

## Security Considerations

- The QUIC implementation is pure Dart; no native binary verification is
  required.
- TLS certificate generation must use the node's existing key pair and must not
  introduce a separate trust root.
- The transport should only be enabled explicitly (`enableQuic: true`) and the
  router must fall back to TCP if the transport fails to load or the handshake
  cannot complete.
- **Captured-but-unverified peer certificate invariant:** During the QUIC
  handshake, the peer's certificate bytes are captured by the underlying
  `quic_lib` stack but are not validated automatically. The application must
  call `verifyPeerCertificate()` or `verifyPeerFromHandshake()` before trusting
  `QuicConnection.remotePeer`. Until one of those methods completes successfully,
  `remotePeer` throws because the peer identity has been received but not
  cryptographically verified.

## Recommended Next Steps

**Superseded by "Architectural blocker (2026-08-25)" above.** The steps
below assumed QUIC only needed a security-handshake gap filled in; that
turned out not to be the real blocker (see above — it's a hard
architectural mismatch with `ipfs_libp2p`'s `Swarm`/`BasicUpgrader`, not a
missing piece of glue code). Keeping the original list for historical
context, but do not resume from it without first deciding between the two
paths the blocker section lays out.

1. Update `quic_lib` so the live TLS handshake exposes the peer's certificate
   bytes to the adapter, then call `verifyPeerCertificate()` automatically
   during connection establishment.
2. Harden the `QuicP2PStream` read path for real bidirectional peer
   communication and add end-to-end QUIC stream tests.
3. Add interop tests against a local Kubo node and a Helia node over QUIC.
4. Keep the `quic_lib` hosted dependency current as new versions are
   published.

## References

- [QUIC_SPEC.md](features/QUIC_SPEC.md)
- [quic_lib](https://github.com/jxoesneon/quic_lib)
- [libp2p QUIC spec](https://github.com/libp2p/specs/blob/master/transports/quic.md)
