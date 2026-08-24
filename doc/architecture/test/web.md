---
test-group: web
generated: 2026-08-24T09:58:20.744556
---

# `test/web/`

## `test/web/ipfs_web_node_test.dart`

- IPFSWebNode
- should start and set running state
- should stop and unset running state
- should add and retrieve content
- get should return null for non-existent CID
- should handle pinning
- should addStream and retrieve content
- addStream should work with empty stream
- should handle IPNS operations with unlocked keystore
- publishIPNS should throw if not started
- resolveIPNS should throw if not started
- addFile should throw on IO platform
- start with bootstrap peers
- Bitswap and PubSub getters
- get with Bitswap fallback (mocked connected peers)

