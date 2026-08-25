# Progresso da transpilação kubo/go-libp2p/boxo → dart_ipfs

**Leia este arquivo antes do plano.** O plano (`C:\Users\Administrador\.claude\plans\lexical-fluttering-acorn.md`, ou peça pro usuário reexportar se estiver em outra máquina/sessão) explica o *porquê* e o *como fazer* — a metodologia recursiva, a ordem de prioridade por tier, os critérios de escopo. Este arquivo diz *o que já foi feito*. Comece por aqui.

## Como isto foi gerado / como continuar

- Todos os 16 repositórios Go de referência estão clonados (`git clone --depth 1`) em `B:\Syncthing\Desenvolvimento\Projetos\Pessoal\go-ipfs-reference\` — **fora** do repositório git do `dart_ipfs`, então não aparecem aqui.
- Cada um já foi indexado com `go-ipfs-reference\go_module_index.go` (ferramenta AST em Go, mesmo formato/metodologia do `tool/generate_module_index.dart` do `dart_ipfs`) — o resultado está em `go-ipfs-reference\<repo>-index\`. **Não precisa reclonar nem reindexar** para continuar a execução; se algum índice parecer desatualizado, regenere com:
  ```
  go-ipfs-reference\go_module_index.exe go-ipfs-reference\<repo> go-ipfs-reference\<repo>-index
  ```
- `gopls` está instalado (`go install golang.org/x/tools/gopls@latest`) — a ferramenta `LSP` genérica (goToDefinition/findReferences/callHierarchy) funciona sobre os repos clonados pra desambiguar os casos que o índice sinaliza como "nome compartilhado por N declarações". Para cross-reference profundo dentro de um repo específico (não só o arquivo aberto), rode `go mod download` dentro daquele repo primeiro — os clones rasos não têm o cache de módulos populado por padrão.
- Comparação de dependências/arquitetura dart_ipfs × kubo (o que motivou esta transpilação): https://claude.ai/code/artifact/22156809-3f60-4775-adc3-23725ba42444

## Status

- `Status` possíveis: `não iniciado` | `em andamento` | `portado sem teste de paridade` | `portado com paridade comprovada` | `fora do escopo (daemon-CLI só, ver plano)`.
- `Destino em lib/src/` fica em branco até o pacote ser realmente mapeado — preencher ao decidir onde o port mora no `dart_ipfs`.
- Ordem das tabelas = ordem de prioridade do plano (Tier 1 primeiro: multiformats puros).


### `go-cid`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/dart_ipfs_core/lib/src/cid/cid.dart` | portado com paridade comprovada | Auditoria completa: NewCidV0/V1/Parse/Decode/Cast/CidFromBytes ≈ CID.v0/v1/decode/fromBytes; String/Encode ≈ encode/encodeWithBase; Set → dart:core Set\<CID\> nativo (CID já tem ==/hashCode corretos, nenhum port necessário). Gap real encontrado e fechado: tipo `Prefix` (version/codec/mhType/mhLength + `.sum(data)`), testado contra `TestNewPrefixV1`/`TestNewPrefixV0`. `Defined()`/Undef sentinel não portado (design Dart já usa exceção em vez de valor zero, não é lacuna). |
| `_rsrch/internal/cidiface` |  | fora do escopo (pasta de pesquisa interna do próprio go-cid, não é API pública) |  |

### `go-multiaddr`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `matest` |  | não iniciado |  |
| `multiaddr` |  | não iniciado |  |
| `net` |  | não iniciado |  |
| `x/meg` |  | não iniciado |  |

### `go-multihash`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` (a `Sum()` pública) | `packages/dart_ipfs_core/lib/src/cid/multihash.dart` (`MultihashUtils.sum`) | portado com paridade comprovada (subconjunto) | 12 vetores oficiais de `sum_test.go` passam byte a byte: identity, sha1, md5, sha2-256, sha2-512, dbl-sha2-256, sha3-224/256/384/512, keccak-256/512. **Deferido, não implementado:** blake2b, blake2s, blake3, shake-128/256, murmur3 (murmurhash já é dependência do projeto pra outra coisa -- HAMT -- mas não está fiado em MultihashUtils ainda), sha2-224/384/512-224/512-256. SHA2-256 domina o uso real de CID; os demais são baixa prioridade. |
| `core` (registro dinâmico de hashers) | — | não iniciado | O switch estático em `MultihashUtils._digestFor` cobre o mesmo conjunto de algoritmos funcionalmente, mas não replica o padrão de registro dinâmico do Go (`Register`/`RegisterVariableSize`/`GetHasher`) -- não parece necessário em Dart, mas não auditado a fundo ainda. |
| `multihash` |  | não iniciado |  |
| `opts` |  | não iniciado |  |
| `register/all` |  | não iniciado (ver nota em `core`) |  |
| `register/blake2` |  | não iniciado |  |
| `register/blake3` |  | não iniciado |  |
| `register/miniosha256` |  | não iniciado |  |
| `register/murmur3` |  | não iniciado |  |
| `register/sha256` |  | não iniciado |  |
| `register/sha3` |  | não iniciado |  |
| `test/sharness/t0030-lib` |  | fora do escopo (script de teste shell, não código de biblioteca) |  |

### `go-multibase`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `multibase-conv` |  | não iniciado |  |

### `go-multicodec`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |

### `go-multiaddr-dns`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `madns` |  | não iniciado |  |

### `go-libp2p`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `config` |  | não iniciado |  |
| `core` |  | não iniciado |  |
| `core/connmgr` |  | não iniciado |  |
| `core/control` |  | não iniciado |  |
| `core/crypto` |  | não iniciado |  |
| `core/crypto/pb` |  | não iniciado |  |
| `core/discovery` |  | não iniciado |  |
| `core/event` |  | não iniciado |  |
| `core/host` |  | não iniciado |  |
| `core/internal/catch` |  | não iniciado |  |
| `core/metrics` |  | não iniciado |  |
| `core/network` |  | não iniciado |  |
| `core/network/mocks` |  | não iniciado |  |
| `core/peer` |  | não iniciado |  |
| `core/peer/pb` |  | não iniciado |  |
| `core/peerstore` |  | não iniciado |  |
| `core/pnet` |  | não iniciado |  |
| `core/protocol` |  | não iniciado |  |
| `core/record` |  | não iniciado |  |
| `core/record/pb` |  | não iniciado |  |
| `core/routing` |  | não iniciado |  |
| `core/sec` |  | não iniciado |  |
| `core/test` |  | não iniciado |  |
| `core/transport` |  | não iniciado |  |
| `examples/autotls` |  | não iniciado |  |
| `examples/chat` |  | não iniciado |  |
| `examples/chat-with-mdns` |  | não iniciado |  |
| `examples/chat-with-rendezvous` |  | não iniciado |  |
| `examples/echo` |  | não iniciado |  |
| `examples/http-proxy` |  | não iniciado |  |
| `examples/ipfs-camp-2019/01-Transports` |  | não iniciado |  |
| `examples/ipfs-camp-2019/02-Multiaddrs` |  | não iniciado |  |
| `examples/ipfs-camp-2019/03-Muxing-Encryption` |  | não iniciado |  |
| `examples/ipfs-camp-2019/05-Discovery` |  | não iniciado |  |
| `examples/ipfs-camp-2019/06-Pubsub` |  | não iniciado |  |
| `examples/ipfs-camp-2019/07-Messaging` |  | não iniciado |  |
| `examples/ipfs-camp-2019/08-End` |  | não iniciado |  |
| `examples/libp2p-host` |  | não iniciado |  |
| `examples/metrics-and-dashboards` |  | não iniciado |  |
| `examples/multipro` |  | não iniciado |  |
| `examples/multipro/pb` |  | não iniciado |  |
| `examples/pubsub/basic-chat-with-rendezvous` |  | não iniciado |  |
| `examples/pubsub/chat` |  | não iniciado |  |
| `examples/relay` |  | não iniciado |  |
| `examples/routed-echo` |  | não iniciado |  |
| `examples/testutils` |  | não iniciado |  |
| `gologshim` |  | não iniciado |  |
| `p2p/canonicallog` |  | não iniciado |  |
| `p2p/discovery/backoff` |  | não iniciado |  |
| `p2p/discovery/mdns` |  | não iniciado |  |
| `p2p/discovery/mocks` |  | não iniciado |  |
| `p2p/discovery/routing` |  | não iniciado |  |
| `p2p/discovery/util` |  | não iniciado |  |
| `p2p/host/autonat` |  | não iniciado |  |
| `p2p/host/autonat/pb` |  | não iniciado |  |
| `p2p/host/autonat/test` |  | não iniciado |  |
| `p2p/host/autorelay` |  | não iniciado |  |
| `p2p/host/basic` |  | não iniciado |  |
| `p2p/host/blank` |  | não iniciado |  |
| `p2p/host/eventbus` |  | não iniciado |  |
| `p2p/host/observedaddrs` |  | não iniciado |  |
| `p2p/host/peerstore` |  | não iniciado |  |
| `p2p/host/peerstore/pstoreds` |  | não iniciado |  |
| `p2p/host/peerstore/pstoreds/pb` |  | não iniciado |  |
| `p2p/host/peerstore/pstoremem` |  | não iniciado |  |
| `p2p/host/peerstore/test` |  | não iniciado |  |
| `p2p/host/pstoremanager` |  | não iniciado |  |
| `p2p/host/relaysvc` |  | não iniciado |  |
| `p2p/host/resource-manager` |  | não iniciado |  |
| `p2p/host/resource-manager/obs` |  | não iniciado |  |
| `p2p/host/routed` |  | não iniciado |  |
| `p2p/http` |  | não iniciado |  |
| `p2p/http/auth` |  | não iniciado |  |
| `p2p/http/auth/internal/handshake` |  | não iniciado |  |
| `p2p/http/ping` |  | não iniciado |  |
| `p2p/metricshelper` |  | não iniciado |  |
| `p2p/muxer/testsuite` |  | não iniciado |  |
| `p2p/muxer/yamux` |  | não iniciado |  |
| `p2p/net/conngater` |  | não iniciado |  |
| `p2p/net/connmgr` |  | não iniciado |  |
| `p2p/net/gostream` |  | não iniciado |  |
| `p2p/net/mock` |  | não iniciado |  |
| `p2p/net/nat` |  | não iniciado |  |
| `p2p/net/nat/internal/nat` |  | não iniciado |  |
| `p2p/net/pnet` |  | não iniciado |  |
| `p2p/net/reuseport` |  | não iniciado |  |
| `p2p/net/swarm` |  | não iniciado |  |
| `p2p/net/swarm/testing` |  | não iniciado |  |
| `p2p/net/upgrader` |  | não iniciado |  |
| `p2p/protocol/autonatv2` |  | não iniciado |  |
| `p2p/protocol/autonatv2/pb` |  | não iniciado |  |
| `p2p/protocol/circuitv2/client` |  | não iniciado |  |
| `p2p/protocol/circuitv2/pb` |  | não iniciado |  |
| `p2p/protocol/circuitv2/proto` |  | não iniciado |  |
| `p2p/protocol/circuitv2/relay` |  | não iniciado |  |
| `p2p/protocol/circuitv2/util` |  | não iniciado |  |
| `p2p/protocol/holepunch` |  | não iniciado |  |
| `p2p/protocol/holepunch/pb` |  | não iniciado |  |
| `p2p/protocol/identify` |  | não iniciado |  |
| `p2p/protocol/identify/internal/user-agent` |  | não iniciado |  |
| `p2p/protocol/identify/pb` |  | não iniciado |  |
| `p2p/protocol/ping` |  | não iniciado |  |
| `p2p/security/insecure` |  | não iniciado |  |
| `p2p/security/insecure/pb` |  | não iniciado |  |
| `p2p/security/noise` |  | não iniciado |  |
| `p2p/security/noise/pb` |  | não iniciado |  |
| `p2p/security/tls` |  | não iniciado |  |
| `p2p/security/tls/cmd` |  | não iniciado |  |
| `p2p/security/tls/cmd/tlsdiag` |  | não iniciado |  |
| `p2p/test/backpressure` |  | não iniciado |  |
| `p2p/test/reconnects` |  | não iniciado |  |
| `p2p/test/resource-manager` |  | não iniciado |  |
| `p2p/transport/quic` |  | não iniciado |  |
| `p2p/transport/quic/cmd/client` |  | não iniciado |  |
| `p2p/transport/quic/cmd/lib` |  | não iniciado |  |
| `p2p/transport/quic/cmd/server` |  | não iniciado |  |
| `p2p/transport/quicreuse` |  | não iniciado |  |
| `p2p/transport/tcp` |  | não iniciado |  |
| `p2p/transport/tcpreuse` |  | não iniciado |  |
| `p2p/transport/tcpreuse/internal/sampledconn` |  | não iniciado |  |
| `p2p/transport/testsuite` |  | não iniciado |  |
| `p2p/transport/webrtc` |  | não iniciado |  |
| `p2p/transport/webrtc/pb` |  | não iniciado |  |
| `p2p/transport/webrtc/udpmux` |  | não iniciado |  |
| `p2p/transport/websocket` |  | não iniciado |  |
| `p2p/transport/webtransport` |  | não iniciado |  |
| `scripts/test_analysis` |  | não iniciado |  |
| `scripts/test_analysis/cmd/gotest2sql` |  | não iniciado |  |
| `test-plans/cmd/ping` |  | não iniciado |  |
| `x/rate` |  | não iniciado |  |
| `x/simlibp2p` |  | não iniciado |  |

### `kubo`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `assets` |  | não iniciado |  |
| `blocks/blockstoreutil` |  | não iniciado |  |
| `client/rpc` |  | não iniciado |  |
| `client/rpc/auth` |  | não iniciado |  |
| `cmd/ipfs` |  | não iniciado |  |
| `cmd/ipfs/kubo` |  | não iniciado |  |
| `cmd/ipfs/util` |  | não iniciado |  |
| `cmd/ipfswatch` |  | não iniciado |  |
| `commands` |  | não iniciado |  |
| `config` |  | não iniciado |  |
| `config/serialize` |  | não iniciado |  |
| `core` |  | não iniciado |  |
| `core/commands` |  | não iniciado |  |
| `core/commands/cmdenv` |  | não iniciado |  |
| `core/commands/cmdutils` |  | não iniciado |  |
| `core/commands/dag` |  | não iniciado |  |
| `core/commands/e` |  | não iniciado |  |
| `core/commands/keyencode` |  | não iniciado |  |
| `core/commands/name` |  | não iniciado |  |
| `core/commands/object` |  | não iniciado |  |
| `core/commands/pin` |  | não iniciado |  |
| `core/coreapi` |  | não iniciado |  |
| `core/corehttp` |  | não iniciado |  |
| `core/coreiface` |  | não iniciado |  |
| `core/coreiface/options` |  | não iniciado |  |
| `core/coreiface/tests` |  | não iniciado |  |
| `core/corerepo` |  | não iniciado |  |
| `core/coreunix` |  | não iniciado |  |
| `core/mock` |  | não iniciado |  |
| `core/node` |  | não iniciado |  |
| `core/node/helpers` |  | não iniciado |  |
| `core/node/libp2p` |  | não iniciado |  |
| `core/node/libp2p/fd` |  | não iniciado |  |
| `core/shutdown` |  | não iniciado |  |
| `coverage/main` |  | não iniciado |  |
| `docs/examples/kubo-as-a-library` |  | não iniciado |  |
| `fuse/fusetest` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `fuse/ipns` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `fuse/mfs` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `fuse/mount` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `fuse/node` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `fuse/readonly` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `fuse/writable` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `gc` |  | não iniciado |  |
| `internal/fusemount` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `misc/fsutil` |  | não iniciado |  |
| `p2p` |  | não iniciado |  |
| `plugin` |  | não iniciado |  |
| `plugin/loader` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `plugin/plugins/badgerds` |  | não iniciado |  |
| `plugin/plugins/dagjose` |  | não iniciado |  |
| `plugin/plugins/flatfs` |  | não iniciado |  |
| `plugin/plugins/fxtest` |  | não iniciado |  |
| `plugin/plugins/git` |  | não iniciado |  |
| `plugin/plugins/levelds` |  | não iniciado |  |
| `plugin/plugins/nopfs` |  | não iniciado |  |
| `plugin/plugins/pebbleds` |  | não iniciado |  |
| `plugin/plugins/peerlog` |  | não iniciado |  |
| `plugin/plugins/telemetry` |  | não iniciado |  |
| `profile` |  | não iniciado |  |
| `repo` |  | não iniciado |  |
| `repo/common` |  | não iniciado |  |
| `repo/fsrepo` |  | não iniciado |  |
| `repo/fsrepo/migrations` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `repo/fsrepo/migrations/atomicfile` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `repo/fsrepo/migrations/common` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `repo/fsrepo/migrations/fs-repo-16-to-17` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `repo/fsrepo/migrations/fs-repo-16-to-17/migration` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `repo/fsrepo/migrations/fs-repo-17-to-18` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `repo/fsrepo/migrations/fs-repo-17-to-18/migration` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `repo/fsrepo/migrations/ipfsfetcher` |  | fora do escopo (daemon-CLI só, ver plano) |  |
| `routing` |  | não iniciado |  |
| `test/api-startup` |  | não iniciado |  |
| `test/bench/bench_cli_ipfs_add` |  | não iniciado |  |
| `test/bench/offline_add` |  | não iniciado |  |
| `test/cli` |  | não iniciado |  |
| `test/cli/harness` |  | não iniciado |  |
| `test/cli/testutils` |  | não iniciado |  |
| `test/cli/testutils/httprouting` |  | não iniciado |  |
| `test/cli/testutils/pinningservice` |  | não iniciado |  |
| `test/dependencies` |  | não iniciado |  |
| `test/dependencies/go-sleep` |  | não iniciado |  |
| `test/dependencies/go-timeout` |  | não iniciado |  |
| `test/dependencies/iptb` |  | não iniciado |  |
| `test/dependencies/ma-pipe-unidir` |  | não iniciado |  |
| `test/dependencies/pollEndpoint` |  | não iniciado |  |
| `test/sharness/t0280-plugin-data` |  | não iniciado |  |
| `thirdparty/unit` |  | não iniciado |  |
| `thirdparty/verifbs` |  | não iniciado |  |
| `tracing` |  | não iniciado |  |

### `boxo`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `autoconf` |  | não iniciado |  |
| `bitswap` |  | não iniciado |  |
| `bitswap/client` |  | não iniciado |  |
| `bitswap/client/internal` |  | não iniciado |  |
| `bitswap/client/internal/blockpresencemanager` |  | não iniciado |  |
| `bitswap/client/internal/getter` |  | não iniciado |  |
| `bitswap/client/internal/messagequeue` |  | não iniciado |  |
| `bitswap/client/internal/notifications` |  | não iniciado |  |
| `bitswap/client/internal/peermanager` |  | não iniciado |  |
| `bitswap/client/internal/session` |  | não iniciado |  |
| `bitswap/client/internal/sessioninterestmanager` |  | não iniciado |  |
| `bitswap/client/internal/sessionmanager` |  | não iniciado |  |
| `bitswap/client/internal/sessionpeermanager` |  | não iniciado |  |
| `bitswap/client/traceability` |  | não iniciado |  |
| `bitswap/client/wantlist` |  | não iniciado |  |
| `bitswap/decision` |  | não iniciado |  |
| `bitswap/internal` |  | não iniciado |  |
| `bitswap/internal/defaults` |  | não iniciado |  |
| `bitswap/message` |  | não iniciado |  |
| `bitswap/message/pb` |  | não iniciado |  |
| `bitswap/metrics` |  | não iniciado |  |
| `bitswap/network` |  | não iniciado |  |
| `bitswap/network/bsnet` |  | não iniciado |  |
| `bitswap/network/bsnet/internal` |  | não iniciado |  |
| `bitswap/network/httpnet` |  | não iniciado |  |
| `bitswap/server` |  | não iniciado |  |
| `bitswap/server/internal/decision` |  | não iniciado |  |
| `bitswap/testinstance` |  | não iniciado |  |
| `bitswap/testnet` |  | não iniciado |  |
| `bitswap/tracer` |  | não iniciado |  |
| `bitswap/wantlist` |  | não iniciado |  |
| `blockservice` |  | não iniciado |  |
| `blockservice/internal` |  | não iniciado |  |
| `blockservice/test` |  | não iniciado |  |
| `blockstore` |  | não iniciado |  |
| `bootstrap` |  | não iniciado |  |
| `chunker` |  | não iniciado |  |
| `chunker/gen` |  | não iniciado |  |
| `dag/walker` |  | não iniciado |  |
| `datastore/dshelp` |  | não iniciado |  |
| `examples/bitswap-transfer` |  | não iniciado |  |
| `examples/car-file-fetcher` |  | não iniciado |  |
| `examples/gateway/car-file` |  | não iniciado |  |
| `examples/gateway/common` |  | não iniciado |  |
| `examples/gateway/proxy-blocks` |  | não iniciado |  |
| `examples/gateway/proxy-car` |  | não iniciado |  |
| `examples/routing/delegated-routing-client` |  | não iniciado |  |
| `exchange` |  | não iniciado |  |
| `exchange/offline` |  | não iniciado |  |
| `fetcher` |  | não iniciado |  |
| `fetcher/helpers` |  | não iniciado |  |
| `fetcher/impl/blockservice` |  | não iniciado |  |
| `fetcher/testutil` |  | não iniciado |  |
| `files` |  | não iniciado |  |
| `filestore` |  | não iniciado |  |
| `filestore/pb` |  | não iniciado |  |
| `filestore/posinfo` |  | não iniciado |  |
| `gateway` |  | não iniciado |  |
| `gateway/assets` |  | não iniciado |  |
| `gateway/assets/test` |  | não iniciado |  |
| `internal/ipnstest` |  | não iniciado |  |
| `internal/test` |  | não iniciado |  |
| `ipld/merkledag` |  | não iniciado |  |
| `ipld/merkledag/dagutils` |  | não iniciado |  |
| `ipld/merkledag/pb` |  | não iniciado |  |
| `ipld/merkledag/test` |  | não iniciado |  |
| `ipld/merkledag/traverse` |  | não iniciado |  |
| `ipld/unixfs` |  | não iniciado |  |
| `ipld/unixfs/file` |  | não iniciado |  |
| `ipld/unixfs/hamt` |  | não iniciado |  |
| `ipld/unixfs/importer` |  | não iniciado |  |
| `ipld/unixfs/importer/balanced` |  | não iniciado |  |
| `ipld/unixfs/importer/helpers` |  | não iniciado |  |
| `ipld/unixfs/importer/trickle` |  | não iniciado |  |
| `ipld/unixfs/internal` |  | não iniciado |  |
| `ipld/unixfs/io` |  | não iniciado |  |
| `ipld/unixfs/mod` |  | não iniciado |  |
| `ipld/unixfs/pb` |  | não iniciado |  |
| `ipld/unixfs/private/linksize` |  | não iniciado |  |
| `ipld/unixfs/test` |  | não iniciado |  |
| `ipns` |  | não iniciado |  |
| `ipns/pb` |  | não iniciado |  |
| `keystore` |  | não iniciado |  |
| `mfs` |  | não iniciado |  |
| `namesys` |  | não iniciado |  |
| `namesys/republisher` |  | não iniciado |  |
| `path` |  | não iniciado |  |
| `path/resolver` |  | não iniciado |  |
| `peering` |  | não iniciado |  |
| `pinning/pinner` |  | não iniciado |  |
| `pinning/pinner/dsindex` |  | não iniciado |  |
| `pinning/pinner/dspinner` |  | não iniciado |  |
| `pinning/remote/client` |  | não iniciado |  |
| `pinning/remote/client/cmd` |  | não iniciado |  |
| `pinning/remote/client/openapi` |  | não iniciado |  |
| `provider` |  | não iniciado |  |
| `retrieval` |  | não iniciado |  |
| `routing/http/client` |  | não iniciado |  |
| `routing/http/contentrouter` |  | não iniciado |  |
| `routing/http/filters` |  | não iniciado |  |
| `routing/http/internal` |  | não iniciado |  |
| `routing/http/internal/drjson` |  | não iniciado |  |
| `routing/http/server` |  | não iniciado |  |
| `routing/http/types` |  | não iniciado |  |
| `routing/http/types/iter` |  | não iniciado |  |
| `routing/http/types/json` |  | não iniciado |  |
| `routing/http/types/ndjson` |  | não iniciado |  |
| `routing/mock` |  | não iniciado |  |
| `routing/offline` |  | não iniciado |  |
| `routing/providerquerymanager` |  | não iniciado |  |
| `tar` |  | não iniciado |  |
| `tracing` |  | não iniciado |  |
| `util` |  | não iniciado |  |
| `verifcid` |  | não iniciado |  |

### `go-ipld-prime`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `adl` |  | não iniciado |  |
| `adl/rot13adl` |  | não iniciado |  |
| `codec` |  | não iniciado |  |
| `codec/cbor` |  | não iniciado |  |
| `codec/dagcbor` |  | não iniciado |  |
| `codec/dagjson` |  | não iniciado |  |
| `codec/json` |  | não iniciado |  |
| `codec/raw` |  | não iniciado |  |
| `datamodel` |  | não iniciado |  |
| `fluent` |  | não iniciado |  |
| `fluent/qp` |  | não iniciado |  |
| `linking` |  | não iniciado |  |
| `linking/cid` |  | não iniciado |  |
| `linking/preload` |  | não iniciado |  |
| `multicodec` |  | não iniciado |  |
| `must` |  | não iniciado |  |
| `node` |  | não iniciado |  |
| `node/basic` |  | não iniciado |  |
| `node/basicnode` |  | não iniciado |  |
| `node/bindnode` |  | não iniciado |  |
| `node/bindnode/registry` |  | não iniciado |  |
| `node/gendemo` |  | não iniciado |  |
| `node/mixins` |  | não iniciado |  |
| `node/tests` |  | não iniciado |  |
| `node/tests/corpus` |  | não iniciado |  |
| `printer` |  | não iniciado |  |
| `schema` |  | não iniciado |  |
| `schema/dmt` |  | não iniciado |  |
| `schema/dsl` |  | não iniciado |  |
| `schema/gen/go` |  | não iniciado |  |
| `schema/gen/go/mixins` |  | não iniciado |  |
| `storage` |  | não iniciado |  |
| `storage/bsadapter` |  | não iniciado |  |
| `storage/bsrvadapter` |  | não iniciado |  |
| `storage/dsadapter` |  | não iniciado |  |
| `storage/fsstore` |  | não iniciado |  |
| `storage/memstore` |  | não iniciado |  |
| `storage/sharding` |  | não iniciado |  |
| `storage/tests` |  | não iniciado |  |
| `testutil` |  | não iniciado |  |
| `testutil/garbage` |  | não iniciado |  |
| `traversal` |  | não iniciado |  |
| `traversal/patch` |  | não iniciado |  |
| `traversal/selector` |  | não iniciado |  |
| `traversal/selector/builder` |  | não iniciado |  |
| `traversal/selector/parse` |  | não iniciado |  |

### `go-libp2p-kad-dht`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `amino` |  | não iniciado |  |
| `crawler` |  | não iniciado |  |
| `dual` |  | não iniciado |  |
| `fullrt` |  | não iniciado |  |
| `internal` |  | não iniciado |  |
| `internal/config` |  | não iniciado |  |
| `internal/metrics` |  | não iniciado |  |
| `internal/net` |  | não iniciado |  |
| `internal/testing` |  | não iniciado |  |
| `netsize` |  | não iniciado |  |
| `pb` |  | não iniciado |  |
| `provider` |  | não iniciado |  |
| `provider/buffered` |  | não iniciado |  |
| `provider/dual` |  | não iniciado |  |
| `provider/internal` |  | não iniciado |  |
| `provider/internal/connectivity` |  | não iniciado |  |
| `provider/internal/keyspace` |  | não iniciado |  |
| `provider/internal/queue` |  | não iniciado |  |
| `provider/internal/timeseries` |  | não iniciado |  |
| `provider/keystore` |  | não iniciado |  |
| `provider/stats` |  | não iniciado |  |
| `qpeerset` |  | não iniciado |  |
| `records` |  | não iniciado |  |
| `rtrefresh` |  | não iniciado |  |

### `go-libp2p-pubsub`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `compat` |  | não iniciado |  |
| `internal/gologshim` |  | não iniciado |  |
| `internal/merkle` |  | não iniciado |  |
| `partialmessages` |  | não iniciado |  |
| `partialmessages/bitmap` |  | não iniciado |  |
| `pb` |  | não iniciado |  |
| `timecache` |  | não iniciado |  |

### `go-datastore`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `autobatch` |  | não iniciado |  |
| `context` |  | não iniciado |  |
| `delayed` |  | não iniciado |  |
| `examples` |  | não iniciado |  |
| `failstore` |  | não iniciado |  |
| `fuzz` |  | não iniciado |  |
| `fuzz/cmd/compare` |  | não iniciado |  |
| `fuzz/cmd/generate` |  | não iniciado |  |
| `fuzz/cmd/isprefix` |  | não iniciado |  |
| `fuzz/cmd/run` |  | não iniciado |  |
| `keytransform` |  | não iniciado |  |
| `mount` |  | não iniciado |  |
| `namespace` |  | não iniciado |  |
| `query` |  | não iniciado |  |
| `retrystore` |  | não iniciado |  |
| `scoped` |  | não iniciado |  |
| `scoped/generate` |  | não iniciado |  |
| `sync` |  | não iniciado |  |
| `test` |  | não iniciado |  |
| `trace` |  | não iniciado |  |

### `go-libp2p-kbucket`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `generate` |  | não iniciado |  |
| `keyspace` |  | não iniciado |  |
| `peerdiversity` |  | não iniciado |  |

### `go-libp2p-record`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `pb` |  | não iniciado |  |

### `go-libp2p-routing-helpers`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `tracing` |  | não iniciado |  |
