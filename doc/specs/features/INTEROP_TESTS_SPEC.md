# dart_ipfs Cross-Implementation Interoperability Test Suite Specification

**Document ID:** `INTEROP_TESTS_SPEC`  
**Version:** 1.1-draft
**Status:** Draft specification for implementation  
**Maintainer Priority:** P0 APPROVED

---

## 1. Goal and Scope

Verify wire-level interoperability between `dart_ipfs` and other IPFS
implementations using local, isolated processes. The first proof is a Kubo
provider known in advance:

`Kubo → TCP/Noise → Bitswap WANT_BLOCK → CID validation → blockstore`.

After that proof, extend the same flow through `CID → DHT.findProviders`.

Scope:

- P0 tests against Kubo for Bitswap fetch and the required CAR/gateway paths.
- P1 tests against Kubo for DHT provider discovery and IPNS resolution.
- P1 nightly tests against Helia (Node.js), report-only.
- A Dart harness that starts each implementation as a local child process with
  a temporary repository, random localhost ports, and cleanup on exit.
- CI that runs the P0 scenarios for changes to protocol or service code.

Out of scope:

- Exhaustive conformance against every IPFS implementation.
- Browser-based interop tests.
- Long-running soak tests and performance benchmarks.

## 2. Official References

- Kubo CLI: https://docs.ipfs.tech/reference/kubo/cli/
- Kubo RPC: https://docs.ipfs.tech/reference/kubo/rpc/
- IPFS gateway specifications: https://specs.ipfs.tech/http-gateways/
- IPNS record spec: https://specs.ipfs.tech/ipns/ipns-record/
- Bitswap specification: https://specs.ipfs.tech/bitswap/
- libp2p specifications: https://docs.libp2p.io/
- CAR v1/v2 format: https://ipld.io/specs/transport/car/
- Helia: https://github.com/ipfs/helia
- Dart testing: https://dart.dev/guides/testing

## 3. Local Process Harness

The harness must locate configured local Kubo and Helia executables, create a
temporary repository per process, initialize it, assign free localhost TCP
ports, and remove the repositories and child processes in a `finally` path.
No shared user repository, persistent key, production endpoint, or host-wide
daemon may be used.

Required files:

```
test/interop/
├── bin/setup.dart              # starts peers and bootstraps connectivity
├── lib/kubo_client.dart        # thin Kubo RPC client
├── lib/dart_ipfs_client.dart   # thin dart_ipfs RPC client
├── lib/local_peer.dart         # process, repo, port and cleanup lifecycle
├── lib/cid_matcher.dart        # deterministic CID comparison helpers
├── .kubo-version               # tested Kubo version
└── test/
    ├── car_test.dart
    ├── bitswap_test.dart
    ├── gateway_test.dart
    ├── dht_test.dart
    └── ipns_test.dart
```

Helia runs through the same lifecycle contract using a temporary working
directory and an explicitly configured localhost API/listen address.

## 4. Test Matrix

| Scenario | Peer(s) | Priority | Success criteria |
|---|---|---|---|
| CAR exchange | Kubo | P0 | Root CID and block payloads match in both directions. |
| Bitswap fetch | Kubo | P0 | WANT_BLOCK returns exact bytes, validated by CID. |
| Gateway retrieval | Kubo or local HTTP client | P0 | Body, content type, raw and CAR formats match. |
| DHT provide/find | Kubo | P1 | Expected peer ID appears in provider results. |
| IPNS resolution | Kubo | P1 | Resolved CID matches the published record. |
| Bitswap and CAR | Helia | P1 nightly | Same byte-exact assertions as Kubo. |

P0 failures block the interop job. P1 failures are surfaced without blocking.

## 5. Execution and Retry Policy

- Start peers, wait for readiness, exchange addresses, and verify connectivity.
- Use three retries and a 120-second timeout for Bitswap; CAR uses 60 seconds.
- Gateway uses ten retries and a 30-second timeout.
- DHT and IPNS use five retries and a 60-second timeout.
- Capture process logs on failure; test data is synthetic and non-sensitive.
- Stop every child process and delete every temporary repository after each run.

The CI workflow invokes the same local commands as a developer, with Kubo and
Node.js/Helia versions pinned in repository metadata. It must not depend on a
pre-existing daemon or a shared filesystem repository.

## 6. Acceptance Criteria

1. P0 Bitswap, CAR, and gateway scenarios pass against the pinned Kubo version.
2. Every P0 scenario checks exact bytes, not only CID equality.
3. The first Bitswap proof validates the received block before storing it.
4. P1 DHT/IPNS tests run and report independently of P0 status.
5. Helia tests run nightly with the same isolated-process lifecycle.
6. Each peer uses a unique temporary repository and localhost ports.
7. All child processes and temporary repositories are cleaned up on success,
   failure, and interruption.
8. The Dart harness emits actionable failure messages per scenario.
9. The interop job is capped at ten minutes for the P0 suite.

## 7. Dependencies and Ordering

Prerequisites are the reusable Kubo RPC, networking, Bitswap, DHT, gateway,
IPNS, and CAR implementations. The CLI is only a developer-facing launcher;
the harness invokes library APIs or explicit local executables.

Implement the known-provider Bitswap proof first, then CAR/gateway coverage,
then DHT provider discovery and IPNS. Helia remains a report-only extension
until the Kubo scenarios are stable.

## 8. Backward Compatibility

Interop tests are additive and do not change the public API. The tested Kubo
and Helia versions may change between releases and must be recorded with the
test results.
