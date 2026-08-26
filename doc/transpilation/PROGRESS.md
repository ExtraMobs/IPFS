# Progresso da transpilação kubo/go-libp2p/boxo → dart_ipfs

**Leia `AGENTS.md` e este arquivo antes de transpilar.** `AGENTS.md` define o
escopo atual (biblioteca/runtime, sem componentes exclusivamente CLI); este
arquivo registra a ordem e o que já foi validado.

## Como isto foi gerado / como continuar

- Todos os 17 repositórios Go de referência estão clonados (`git clone --depth 1`) em `B:\Syncthing\Desenvolvimento\Projetos\Pessoal\go-ipfs-reference\` — **fora** do repositório git do `dart_ipfs`, então não aparecem aqui.
- URLs e commits exatos dessas fontes estão fixados em
  [`UPSTREAM_LOCK.md`](UPSTREAM_LOCK.md).
- Cada um já foi indexado com `go-ipfs-reference\go_module_index.go` (ferramenta AST em Go, mesmo formato/metodologia do `tool/generate_module_index.dart` do `dart_ipfs`) — o resultado está em `go-ipfs-reference\<repo>-index\`. **Não precisa reclonar nem reindexar** para continuar a execução; se algum índice parecer desatualizado, regenere com:
  ```
  go-ipfs-reference\go_module_index.exe go-ipfs-reference\<repo> go-ipfs-reference\<repo>-index
  ```
- `gopls` está instalado (`go install golang.org/x/tools/gopls@latest`) — a ferramenta `LSP` genérica (goToDefinition/findReferences/callHierarchy) funciona sobre os repos clonados pra desambiguar os casos que o índice sinaliza como "nome compartilhado por N declarações". Para cross-reference profundo dentro de um repo específico (não só o arquivo aberto), rode `go mod download` dentro daquele repo primeiro — os clones rasos não têm o cache de módulos populado por padrão.
- Comparação de dependências/arquitetura dart_ipfs × kubo (o que motivou esta transpilação): https://claude.ai/code/artifact/22156809-3f60-4775-adc3-23725ba42444

## Status

- `Status` possíveis: `não iniciado` | `em andamento` | `portado sem teste de paridade` | `portado com paridade comprovada` | `implementação original não auditada` | `fora do escopo (<razão confirmada>)`.
- `implementação original não auditada` (valor novo, adicionado em 2026-08): existe código Dart funcional cobrindo (parte d)o que este pacote Go faz, mas foi escrito do zero, nunca comparado função-a-função com o Go real, e não tem teste de paridade contra vetores reais. **Não confundir com `não iniciado`** (nenhum código relevante existe) — a distinção importa porque a suite de testes já achou 2 bugs reais em código que "funcionava" antes de ser auditado (Noise só-Ed25519, RSA com DER errado). Ver a seção "Estado em aberto" abaixo pra o levantamento completo de onde essa cobertura existe.
- `Destino em lib/src/` fica em branco até o pacote ser realmente mapeado — preencher ao decidir onde o port mora no `dart_ipfs`.
- Ordem das tabelas = ordem de prioridade do plano (Tier 1 primeiro: multiformats puros).

## Estado em aberto (2026-08-25)

- 🚧 **NÃO CONFIÁVEL — `go-ipld-prime/codec/dagjson` em auditoria (2026-08-26)**: núcleo Node↔DAG-JSON adicionado em `transpiled_ipld_prime`, com CID, bytes no envelope `{\"/\":{\"bytes\":...}}`, ordenação lexical padrão e opções de encode para rejeitar links/bytes; ainda falta comparação completa dos vetores Go (opções de decode, limites e erros); não declarar paridade.

Isto é o que uma sessão futura precisa saber pra continuar de onde paramos — não é redundante com as tabelas abaixo, é o contexto que não cabe numa célula de tabela.

- 🚧 **NÃO CONFIÁVEL — `go-libp2p-routing-helpers` em andamento (2026-08-26)**: WIP de `Parallel`/`Tiered`/`ComposableParallel`/`ComposableSequential` e builders auditado contra o SHA travado. Já cobre merge de `QueryEvent` nos caminhos `Future` e `Stream`, `ProvideManyRouter` usando o `MultihashInfo` já existente em `transpiled_multihash`, limites/timeouts de streams e `DoNotWaitForSearchValue`; `dart analyze` está limpo e os 32 testes Dart passam, assim como `go test ./...` no upstream. **Ainda não declarar paridade final**: os fixtures extensos de `parallel_test.go`/`compparallel_test.go`/`compsequential_test.go` não foram reproduzidos integralmente em Dart, e não há API Dart de `context.Context`, portanto cancelamento cooperativo fica limitado ao cancelamento de subscriptions de `Stream` e timeouts de `Future` (o trabalho subjacente de um `Future` vencido pode continuar).
- **Regra permanente pedida pelo usuário nesta sessão**: sempre que um port estiver em andamento (arquivos escritos mas ainda sem `dart analyze`/`dart test`/commit), anotar isso no TOPO desta seção, marcado como não confiável, antes de continuar -- assim, se a sessão for interrompida no meio, a próxima sessão (ou ferramenta) sabe exatamente o que é seguro reaproveitar e o que é só rascunho. Esta seção é o lugar certo pra esse aviso; nenhum bullet "🚧 em andamento" deveria sobreviver depois que o trabalho correspondente termina (teste+commit) -- quando terminar, vira uma nota normal como as abaixo, ou desaparece.
- **`go-datastore` portado (2026-08-25)**: novo pacote `packages/transpiled_datastore/` (ver a linha `(root)` da tabela abaixo pra detalhe técnico completo). Nota de metodologia: `dart test` (sem argumento de arquivo) mostrou-se instável NESTE ambiente Windows/Git-Bash quando rodando múltiplos arquivos de teste em paralelo -- o reporter às vezes repete o nome de um teste de um arquivo várias vezes e omite testes de outros arquivos, de forma não-determinística entre execuções (reproduzido tanto via Git Bash quanto PowerShell). Rodar com `dart test -j 1` (concorrência 1) ou por arquivo/diretório individual dá resultado limpo e determinístico todas as vezes -- os 22 testes deste pacote foram confirmados passando dessa forma antes do commit. Isso é uma característica do test runner/ambiente, não um defeito do código portado; registrar aqui pra qualquer sessão futura que veja contagens de teste estranhas neste projeto saber que não é motivo de alarme, e que `-j 1` resolve.
- **Levantamento recursivo de dependências completo**, cruzando `kubo/go.mod`, os módulos clonados e o estado real deste repo (não só o que esta tabela diz): https://claude.ai/code/artifact/6b94efde-3f58-4ad6-98bd-c18d8de19330 — inclui a ordem de construção recomendada (abaixo) e, importante, a cobertura original já existente em `lib/src/` pra cada um dos 8 módulos sem port literal (DHT, PubSub, IPLD codecs, Bitswap, UnixFS, Gateway/CAR, storage, routing helpers).
- **Ordem de construção recomendada**, derivada dos imports Go reais (não suposição): ~~(1) `core/record`+`core/peer/pb` (fecha `PeerRecord`, autocontido)~~ **feito em 2026-08-25** → (2) três frentes paralelas sem dependência cruzada: ~~`go-libp2p-record`~~ **feito em 2026-08-25** →`routing-helpers` **(em andamento, ver nota abaixo)**, ~~`go-libp2p-kbucket`~~ **feito em 2026-08-25**, ~~`go-datastore`~~ **feito em 2026-08-25**, `go-ipld-prime` **(em andamento -- `datamodel`, `node/basicnode`, `codec/json`/`raw`, `linking`/`linking/cid`, `storage`, `traversal` e `traversal/selector` feitos; faltam os demais codecs, `traversal/patch` e `schema`/`schema/gen/go`, este último requer design próprio por depender de geração/reflexão no Go)**, `go-libp2p-pubsub` **(em andamento -- `timecache`+`partialmessages/bitmap` feitos em 2026-08-25 (únicos subpacotes sem dependência de `Host`/`Stream` do `go-libp2p`); `PubSub`/`GossipSubRouter` (a orquestração central, ~27500 linhas) ficam bloqueados até `go-libp2p` Host/Stream/Network estar pronto -- ver nota completa na linha `(root)` da tabela)** → (3) `boxo` núcleo (bitswap/blockstore/dag/files/mfs/gateway — não depende da DHT) → (4) `go-libp2p-kad-dht` (ponto de convergência: kbucket+record+routing-helpers+boxo+datastore — é o ÚLTIMO a ficar pronto, não o primeiro) → (5) `boxo` namesys/routing (só cantos que realmente usam a DHT). Cortando tudo isso: o resto do `go-libp2p` em si (Host/Swarm/Transportes/NAT/Identify) ainda vem inteiro do `ipfs_libp2p` de terceiro — é o maior corpo de trabalho restante em linhas de código de todo o grafo, e nenhum item da lista acima o reduz.
- **`go-libp2p-kbucket` portado (2026-08-25)**: novo pacote `packages/transpiled_libp2p_kbucket/` (ver a linha `(root)` da tabela abaixo pra detalhe técnico completo). Dois bugs reais encontrados e corrigidos durante este port, ambos do mesmo gênero (Dart não tem largura fixa de inteiro, Go sim): (1) o gerador de `bucket_prefixmap.go` (arquivo GERADO de 65536 linhas no Go — portado como script, não transcrito à mão) hasheava só 6 dos 34 bytes reais na primeira versão; (2) `genRandomKey` usava `~` de precisão arbitrária do Dart onde o Go usa complemento de bits de um `uint8` real, causando sobreposição de máscaras que contaminava bits que deveriam vir determinadamente da chave local — pego pelo próprio teste de paridade (`TestGenRandomKey`, 100 iterações), não por inspeção. Reforça o padrão já visto nesta sessão: todo `~`/complemento de bits portado do Go precisa de `& 0xFF` (ou a máscara de largura equivalente) logo depois, nunca confiar no comportamento "óbvio".
- **Primeira onda multiagente validada (2026-08-26)**: `boxo/bitswap/client/wantlist`, `go-ipld-prime/codec`+`codec/raw` e `go-libp2p/core/routing/query.go` foram revisados, testados contra seus pacotes Go e validados em Dart. `QueryEvent` usa `Zone` e `QueryEventRegistration.close()` no lugar de `context.Context`/canal genéricos. Essas limitações estão registradas nas linhas das tabelas, não são licença para pular os consumidores.
- **`core/routing` + parte de `go-libp2p-routing-helpers` portados (2026-08-25/26)**: `core/routing` e as peças mecânicas/autocontidas de `go-libp2p-routing-helpers` (`Bootstrap`, `NullRouter`, `LimitedValueStore`, `Compose`) estão prontas; `query.go` agora também está pronto. O WIP de `Parallel`/`Tiered`/composable está funcional e testado de forma direcionada, mas permanece não confiável até fechar a paridade indicada no aviso acima.
- **`go-libp2p-record` portado (2026-08-25)**: novo pacote `packages/transpiled_libp2p_record/` (ver a linha da tabela abaixo pra detalhe técnico). Primeiro pacote novo desde a reorganização de módulos que não é `transpiled_libp2p` nem um dos multiformats -- confirma que a convenção de pacote-por-módulo-Go se sustenta pra módulos menores também.
- **`core/record` + `core/peer/pb` portados (2026-08-25)**: `Record`/`Envelope`/`PeerRecord` completos em `packages/transpiled_libp2p/lib/src/core/record/` e `core/peer/peer_record.dart` (ver as linhas das tabelas abaixo pra detalhe técnico). Achado de metodologia relevante pra qualquer port futuro que precise imitar o `init()` do Go: uma variável de nível de biblioteca em Dart (`final bool _x = _setup();`) **não** roda só por importar o arquivo -- inicialização de topo em Dart é preguiçosa (só roda no primeiro acesso a essa variável). O registro automático do `PeerRecord` em `Envelope` teve que ser movido pro construtor (idempotente, com guarda contra recursão), não um "top-level init". Isso já causou um teste falhar nesta sessão antes de ser corrigido -- vale revisar qualquer port futuro que dependa do padrão `init()`/registro automático do Go.
- **Tarefa aberta, ainda não iniciada**: mapear a API pública do guarda-chuva contra a composição programática de `kubo/core` (`builder.go`, `core.go` e serviços reutilizáveis). `bin/ipfs.dart` é apenas uma ferramenta original e não é referência de arquitetura nem alvo de paridade. Falta decidir, por etapa (usando a ordem acima), o que em `lib/src/` é cola de integração genuína reaproveitável (por exemplo `core/ipfs_node/` e `services/`) e o que precisa ser substituído por port real.
- **Correção de escopo após auditoria de callers (2026-08-25)**: o plano antigo marcava toda a árvore FUSE, `plugin/loader` e todas as migrações como “daemon-CLI only”. Isso era amplo demais. `core/core.go` importa `fuse/mount`, `core/coreapi` importa `internal/fusemount`, `repo/fsrepo` usa `repo/fsrepo/migrations`, e o exemplo oficial `kubo-as-a-library` usa `plugin/loader`. Essas unidades voltaram para `não iniciado`. Implementações FUSE chamadas somente por `cmd`/`core/commands`, os binários `main` de migração e `ipfsfetcher` continuam fora após busca dos imports reais.
- **Limpeza de identidade do fork (concluída)**: removidos `README.md`/`CONTRIBUTING.md`/`CHANGELOG.md`/`LICENSE`/`SECURITY.md`/`ROADMAP.md`/`ENGINEERING_NOTES.md`/`CODE_OF_CONDUCT.md`/`FUNDING.yml`/workflow de publish automático no pub.dev/Docker+Helm+K8s (apontavam pro registry do autor original) — eram 100% conteúdo do projeto `jxoesneon/IPFS` upstream, sem valor de código pra este fork. `pubspec.yaml`/`melos.yaml` e os docs técnicos que restaram agora apontam pro fork real (`github.com/ExtraMobs/IPFS`). Esses arquivos precisam ser reescritos do zero quando o fork tiver uma identidade própria definida — não foram recriados ainda, de propósito.
- **Limitação conhecida dos planos do Claude Code**: o arquivo de plano (`C:\Users\Administrador\.claude\plans\...`) não é versionado neste repositório — vive só na instalação local do Claude Code, e pode ser sobrescrito por um plano mais novo com o mesmo nome (já aconteceu nesta sessão: o plano original de metodologia foi substituído pelo plano de reorganização de pacotes). Esta seção existe justamente pra não depender só do arquivo de plano pra continuidade entre sessões.


### `go-cid`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_cid/lib/src/cid.dart` | portado com paridade comprovada | Auditoria completa: NewCidV0/V1/Parse/Decode/Cast/CidFromBytes ≈ CID.v0/v1/decode/fromBytes; String/Encode ≈ encode/encodeWithBase; Set → dart:core Set\<CID\> nativo (CID já tem ==/hashCode corretos, nenhum port necessário). Gap real encontrado e fechado: tipo `Prefix` (version/codec/mhType/mhLength + `.sum(data)`), testado contra `TestNewPrefixV1`/`TestNewPrefixV0`. `Defined()`/Undef sentinel não portado (design Dart já usa exceção em vez de valor zero, não é lacuna). |
| `_rsrch/internal/cidiface` |  | fora do escopo (pasta de pesquisa interna do próprio go-cid, não é API pública) |  |

### `go-multiaddr`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_multiaddr/lib/src/{protocol,transcoders,multiaddr}.dart` | portado com paridade comprovada | Reescrito do zero em `dart_ipfs_core` (a dependência existente, `ipfs_libp2p`'s `MultiAddr`, cobria só 15/37 protocolos e tinha **dois bugs reais de código de wire**: `quic-v1` usava o código 460, que é o de `quic` puro em go-multiaddr -- o `P_QUIC_V1` real é 461; e `sni` usava 467 em vez do real 449 -- ambos causariam incompatibilidade de wire silenciosa com peers reais). Tabela completa de 37 protocolos (`Protocols` em `protocol.dart`, códigos/tamanhos copiados literalmente de `protocols.go`) + todos os transcoders (`transcoders.dart`: ip4/ip6/ip6zone/ipcidr/port/dns/onion/onion3/garlic64/garlic32/p2p/unix/certhash/http-path/memory) + `Component`/`Multiaddr` (`multiaddr.dart`: parse/toBytes/fromBytes/encapsulate/decapsulate/valueForProtocol/compare/equal). IPv4/IPv6 parsing é caseiro (não usa `dart:io`'s `InternetAddress`, pra manter `dart_ipfs_core` sem dependência de `dart:io`/web-incompatível) -- inclui formatação IPv6 canônica RFC 5952 com compressão `::` e caso especial `::ffff:a.b.c.d`. 152 testes de paridade em `test/multiaddr_parity_test.dart`, usando as listas `good`/`bad` reais de `multiaddr_test.go` (incluindo os payloads i2p/Tor completos), mais round-trip binário e um teste cruzado provando que um PeerId em base58 e o mesmo PeerId como CID base32 (`libp2p-key`) decodificam pro mesmo valor. CIDs de PeerId em base36 (`k2k4r8oq...`, prefixo `k`) foram inicialmente um gap documentado (`package:multibase` não tinha codec base36) -- fechado no mesmo commit que reescreveu `go-multibase` logo em seguida; os 11 vetores voltaram pra lista `_good` e há um teste cruzado provando que base58/base32/base36 do mesmo PeerId decodificam pro mesmo valor. `FilterAddrs`/`Filters` (filtro allow/deny de endereços) e `Match`/`x/meg` (mini-linguagem de pattern matching sobre protocolos) não portados -- nenhum caller em `dart_ipfs` precisa deles hoje; retomar se/quando o swarm precisar de política de filtragem de endereço. |
| `matest` |  | fora do escopo (helpers de teste do próprio go-multiaddr, não é API de produção) |  |
| `net` |  | não iniciado | Conveniências que integram `Multiaddr` com `net.Conn`/`net.Dial` do Go (`ToNetAddr`, `FromNetAddr`, `Listen`, etc.) -- equivalente Dart seria integração com `dart:io`'s `Socket`/`RawDatagramSocket` no Tier 3 (transporte), não faz sentido portar antes do transporte real existir. |
| `x/meg` |  | não iniciado | Mini-linguagem de pattern matching usada só por `Multiaddr.Match`; ver nota do `(root)` acima -- sem caller no `dart_ipfs` hoje. |

### `go-multihash`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` (a `Sum()` pública) | `packages/transpiled_multihash/lib/src/multihash.dart` (`MultihashUtils.sum`) | portado com paridade comprovada (subconjunto) | 12 vetores oficiais de `sum_test.go` passam byte a byte: identity, sha1, md5, sha2-256, sha2-512, dbl-sha2-256, sha3-224/256/384/512, keccak-256/512. **Deferido, não implementado:** blake2b, blake2s, blake3, shake-128/256, murmur3 (murmurhash já é dependência do projeto pra outra coisa -- HAMT -- mas não está fiado em MultihashUtils ainda), sha2-224/384/512-224/512-256. SHA2-256 domina o uso real de CID; os demais são baixa prioridade. |
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
| `(root)` | `packages/transpiled_multibase/lib/src/multibase.dart` | portado com paridade comprovada | Reescrito do zero: `package:multibase`'s `Multibase` enum só cobre 8 das 21 codificações que o próprio go-multibase implementa, e usa um algoritmo de conversão por inteiro-grande (correto pra base36/base58, mas **errado** pra base16/32/64 -- que são esquemas de agrupamento de bits de largura fixa, não conversão numérica -- daí o bug de base32 já documentado aqui antes). `MultibaseUtils.decode`/`.encodeWithName` agora despacham as 21 codificações reais por nome/caractere-prefixo (idêntico ao `Encoding` do Go, que também é literalmente um rune): identity, base2, base16(upper), os 8 variantes de base32 (via `package:base32`, bit-packing correto), base36(upper) e base58btc/flickr (via `package:base_x`'s `BaseXCodec`, mesmo algoritmo do Bitcoin com contagem explícita de bytes líder-zero -- correto pra essa família), os 4 variantes de base64 (via `dart:convert`), e base256emoji (tabela de 256 emojis copiada literalmente do Go, sem aritmética). `base8`/`base10`/`base45` **não implementados -- assim como no próprio go-multibase**, que só declara as constantes mas nunca as implementa (cai em `ErrUnsupportedEncoding`); replicado exatamente (lança `UnsupportedError`), não é uma lacuna real. `encode(mb.Multibase, bytes)` manteve a assinatura estreita (8 valores) que `CID`/outros callers já usam, mas passou a rotear pelas mesmas implementações corretas -- corrigindo de brinde um bug latente (`base32upper` nunca tinha sido corrigido, só `base32` minúsculo). 116 testes de paridade em `test/multibase_parity_test.dart`, usando `encodedSamples` de `multibase_test.go` (21 codificações de "Decentralize everything!!!") + os fixtures CSV oficiais do spec (`spec/tests/*.csv` -- submódulo git que o clone raso não trouxe, clonado à parte nesta sessão) cobrindo zero/um/dois bytes líder-zero e decode case-insensitive. Isso também fechou o gap de base36 documentado na linha do `go-multiaddr` acima -- os 11 vetores que usavam PeerId em base36 voltaram pra lista `_good` de `multiaddr_parity_test.dart` e passam. |
| `multibase-conv` |  | fora do escopo (CLI wrapper do go-multibase, não é API de produção) |  |

### `go-multicodec`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_multicodec/lib/src/multicodec.dart` | portado com paridade comprovada | Tabela completa de 603 entradas, extraída **mecanicamente** de `code_table.go` (regex sobre `Name Code = 0xNN // nome-canonico`, não transcrita à mão) -- a tabela anterior tinha só ~30 entradas escolhidas a dedo e havia **divergido da real**: inventava `ipld-ns`/`ipfs-ns`/`ipns-ns` nos códigos 0x300/0x301/0x302, quando a tabela real do go-multicodec usa esses códigos pra `ipns-record`/`libp2p-peer-record`/`libp2p-relay-rsvp`; e `dnslink` estava no código errado (0x33, que na verdade é `multibase` -- o real `dnslink` é 0xe8). Corrigido também o mesmo par de nomes errados em `lib/src/utils/encoding.dart` (utilitário duplicado da árvore do `dart_ipfs` que ainda não foi absorvido pelo `dart_ipfs_core` -- fora do escopo deste port consolidar os dois, mas o bug encontrado foi corrigido nos dois lugares). 5 testes de paridade em `test/multicodec_parity_test.dart` (contagem exata de 603, round-trip código↔nome, spot-check espalhado pelo arquivo inteiro, e um teste específico provando que a faixa 0x300 bate com a tabela real). |

### `go-multiaddr-dns`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_multiaddr_dns/lib/src/dns_resolver.dart` (orquestração) + `lib/src/transport/dns/` no `dart_ipfs` (I/O real) | **portado com paridade comprovada, incluindo I/O real e integração no bootstrap** | **Este é o pacote que disparou toda a transpilação** (nó ficava em 0 peers por causa da resolução de `/dnsaddr/`) -- agora fechado ponta a ponta. Orquestração (`dart_ipfs_core`): a interface `BasicResolver` (`lookupIPAddr`/`lookupTXT`), `MockResolver` (mock.go), a classe `Resolver` inteira (resolve.go: `resolve()`, resolvers por domínio/TLD com match left-to-right, o algoritmo de sufixo do dnsaddr com contagem de componentes), `dnsMatches` (util.go `Matches`), `isFqdn`/`fqdn` (bug de paridade de bits encontrado e corrigido contra `TestIsFqdn`/`TestFqdn`). Precisou `splitFunc`/`splitFirst`/`forEach` no `Multiaddr`. 30 testes de paridade em `test/dns_resolver_parity_test.dart` via `MockResolver`, sem rede real. **I/O real (segunda parte desta sessão, "destrinchar o stdlib que ficou faltando"):** checado pub.dev primeiro pela metodologia -- o único pacote pure-Dart de DNS clássico (`dns`, terrier989/dint.dev) tem 30/160 pontos, 6 likes, 33 downloads (sinal forte de abandono, não é algo pra depender em código de produção); os demais achados (`dns_client`, `super_dns_client`, `dnsolve`) são DNS-over-HTTPS ou wrappers FFI do resolver nativo, que não replicam a semântica de DNS clássico que o kubo/go-libp2p realmente usam. Confirmado: sem alternativa viável, escrito do zero um cliente RFC 1035 mínimo em `lib/src/transport/dns/`: `dns_message.dart` (encode de query + decode de resposta -- header, nomes com ponteiro de compressão RFC 1035 §4.1.4 com guarda contra loop, registros A/AAAA/TXT, concatenação de character-strings de TXT igual ao `net.LookupTXT` do Go), `udp_dns_client.dart` (`RawDatagramSocket`, timeout + retry + fallback entre resolvers, já que `dart:io` não expõe descoberta do resolver do SO -- usa 1.1.1.1/8.8.8.8 por padrão, configurável), `system_resolver.dart` (`SystemResolver`: `lookupIPAddr` via `InternetAddress.lookup` do próprio `dart:io`, que já cobria A/AAAA sem lacuna nenhuma; `lookupTXT` via o cliente UDP novo). Testado com bytes reais capturados de uma troca UDP ao vivo com 1.1.1.1 (`test/transport/dns/dns_message_test.dart`, 9 testes determinísticos, incluindo o caso real de `_dnsaddr.bootstrap.libp2p.io` com nomes comprimidos) e cross-verificado independentemente via `Resolve-DnsName -Type TXT` do PowerShell. Mais 5 testes ao vivo (`@Tags(['network'])`, pulados por padrão -- ver `dart_test.yaml`, rodar com `dart test --preset network`) provando resolução real: `Resolver`+`SystemResolver` juntos resolvem `/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu...` (o endereço de bootstrap real do `network_config.dart`) até um endereço concreto, recursivamente (o TXT de `bootstrap.libp2p.io` aponta pra aliases por nó tipo `sv15.bootstrap.libp2p.io`, que por sua vez precisam de outra resolução -- comportamento esperado do go-multiaddr-dns, não bug). **Integrado no fluxo real de bootstrap:** `bootstrap_handler.dart` resolvia endereços `/dnsaddr/...` literalmente antes (nunca funcionava -- essa era a causa raiz dos 0 peers), agora resolve via `Resolver` antes de discar, com fallback condicional pra web (`dns_bootstrap_resolver.dart` com export condicional `if (dart.library.html)`, já que browsers não expõem socket bruto -- mesmo padrão já usado por `network_handler.dart`) e resolver injetável no construtor pra testes determinísticos offline (`test/core/ipfs_node/bootstrap_utils_test.dart`, novo grupo `BootstrapHandler DNS resolution`, 3 testes com `MockResolver`, provando que o endereço resolvido -- não o `/dnsaddr/...` original -- é o que chega em `NetworkHandler.connectToPeer`). |
| `madns` |  | fora do escopo (`cmd/madns`, CLI wrapper do go-multiaddr-dns, não é API de produção) |  |

### `go-libp2p`

**Ordem de prioridade invertida** (ver plano, `lexical-fluttering-acorn.md`): testei um nó real conectando contra `bootstrap.libp2p.io` e descobri que o handshake Noise da dependência `ipfs_libp2p` (usada hoje pra host/transporte/segurança) rejeitava qualquer peer real que não fosse Ed25519 (causa raiz real detalhada na linha do `p2p/security/noise` abaixo), então portar `core/crypto`/`core/peer` sozinho (Tier 2 original) não destravava conexão real (a checagem está na camada de segurança). Por isso `core/sec`/`p2p/security/{noise,tls}` (Tier 3 original) viraram prioridade antes do resto de `core/crypto`/`core/peer`/`core/record`. Também achado no mesmo teste: discagem QUIC-v1 de saída falha com "No transport found for address" -- investigado a fundo depois (ver `p2p/transport/quic` abaixo): é um bloqueio arquitetural real com o `Swarm` de terceiro, não um gap de implementação simples, e ficou arquivado como pendência deliberada, não corrigido.

**Correção validada contra a rede real (`bootstrap.libp2p.io`)**: com `DartIpfsNoiseSecurity` plugado (ver linha `p2p/security/noise`), um nó `dart_ipfs` real conectou e **manteve conectados os 4 peers de bootstrap padrão por 40s seguidos** (script de teste ad-hoc, mesmo método usado na investigação original) -- os 4 IDs são `Qm...` (multihash sha2-256 legado, não `identity`/inline), o que é exatamente o padrão de peer com chave RSA que travava antes dessa correção. Antes desta sessão, o mesmo teste ficava em 0 peers conectados por 30s.

Um bug concreto de `core/peer` já foi corrigido fora de ordem (motivado pelo mesmo teste): `PeerId.fromPublicKey` em `packages/transpiled_libp2p/lib/src/core/peer/peer_id.dart` calculava `sha256(chave pública crua)` diretamente, em vez de multihash do `PublicKey{Type, Data}` protobuf-marshaled (`identity` multihash quando o marshaled cabe em ≤42 bytes -- sempre o caso pra Ed25519, 36 bytes -- `sha2-256` caso contrário, exatamente `IDFromPublicKey` de `core/peer/peer.go`). Também rejeitava qualquer tipo que não fosse `'Ed25519'`; agora aceita `RSA`/`Secp256k1`/`ECDSA` também (só a derivação do PeerId, não assinatura/verificação -- isso ainda é `core/crypto` de verdade). Um protobuf mínimo de 2 campos (`PublicKey{Type, Data}`, crypto.proto) foi escrito à mão em `peer_id.dart` -- não vale a pena codegen completo pra isso.

Corrigir esse bug expôs um segundo bug real, preexistente: `_encodeBase36`/`_decodeBase36` (também em `peer_id.dart`) convertiam os bytes pra um único `BigInt`, descartando bytes zero à esquerda -- mesma classe de bug já documentada e corrigida em `multibase.dart` no Tier 1 (base32 do `package:multibase`). Como o identity-multihash de uma chave Ed25519 sempre começa com o byte `0x00` (o código do multihash `identity`), esse bug ficava latente até a derivação de PeerId ficar correta. Corrigido substituindo `_encodeBase36`/`_decodeBase36` inteiros pelas chamadas equivalentes em `dart_ipfs_core`'s `MultibaseUtils` (já testado, 116 casos de paridade no Tier 1) -- não faz sentido manter dois codecs base36 no projeto. Testes atualizados: `test/core/types/peer_id_test.dart` (vetores exatos calculados à mão pro caso Ed25519) e `test/property/dht_property_test.dart` (o teste que antes documentava a limitação de bytes-zero-à-esquerda como conhecida agora prova que foi corrigida, com 500 iterações aleatórias sem pular nenhuma).

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `config` |  | não iniciado |  |
| `core` |  | não iniciado |  |
| `core/connmgr` |  | não iniciado |  |
| `core/control` |  | não iniciado |  |
| `core/crypto` | `packages/transpiled_libp2p/lib/src/core/crypto/key_types.dart` (`Key`/`PrivKey`/`PubKey`/`KeyType`) + `rsa_key.dart`, `secp256k1_key.dart`, `ecdsa_key.dart` | **portado com paridade comprovada** (RSA, Secp256k1, ECDSA todos com vetor real Go) | **RSA**: `MinRsaKeyBits=2048`, PKCS1 DER privado/PKIX DER público via ASN.1 do `package:pointycastle`, sign/verify SHA-256+PKCS1v1.5 via `pc.RSASigner`. Validado contra `crypto/rsa`+`crypto/x509` do Go (`go-ipfs-reference/noise_vectors/rsa_vectors.go`): DER round-trip exato, assinatura Dart bate byte a byte com a do Go (PKCS1v1.5 é determinístico) -- `test/rsa_key_parity_test.dart`. **Secp256k1**: raw = escalar de 32 bytes big-endian / ponto comprimido SEC1 de 33 bytes (mesmo formato de `github.com/decred/dcrd/dcrec/secp256k1/v4`, a lib que `core/crypto/secp256k1.go` encapsula); assinatura DER com nonce determinístico RFC6979 (SHA-256/HMAC) via `pc.ECDSASigner` em modo `DET-ECDSA`, canonicalizada pra S-baixo (`ECSignature.normalize`) igual ao `Signature.Serialize()` do dcrd. Validado contra `github.com/decred/dcrd/dcrec/secp256k1/v4/ecdsa` (`go-ipfs-reference/secp256k1_vectors/main.go`): **a assinatura RFC6979 do Dart bate byte a byte com a do Go** (achado notável -- confirma que a variante de nonce RFC6979 do dcrd, que pula a redução `bits2octets` por já operar sobre hash de 256 bits ~ ordem da curva, coincide na prática com a implementação padrão do pointycastle) -- `test/secp256k1_key_parity_test.dart`. **ECDSA**: hardcoded pra NIST P-256 igual ao Go (`elliptic.P256()`); raw privado = SEC1 `ECPrivateKey` (RFC 5915, `x509.MarshalECPrivateKey` -- SEQUENCE com version/OCTET STRING d/[0] EXPLICIT OID da curva/[1] EXPLICIT BIT STRING do ponto, os dois campos opcionais do RFC 5915 sempre presentes por serem os que o Go sempre emite); raw público = PKIX `SubjectPublicKeyInfo` com AlgorithmIdentifier `{id-ecPublicKey, namedCurve OID}` (não NULL como no RSA) envolvendo o ponto não-comprimido. `ecdsa.Sign` do Go usa nonce aleatorizado (não RFC6979), então a paridade aqui é provada por verificação cruzada, não assinatura idêntica: Dart aceita uma assinatura real do Go, e as codificações DER/SEC1 batem byte a byte. Validado contra `crypto/ecdsa`+`crypto/x509` do Go (`go-ipfs-reference/ecdsa_vectors/main.go`) -- `test/ecdsa_key_parity_test.dart`. Em todos os três: geração de chave via `pc.*KeyGenerator`+`FortunaRandom`, seed real via `Random.secure()` do Dart. **Ed25519** (`ed25519_key.dart`): não é um port novo -- envolve o `Ed25519Signer` já existente (usado por IPNS) na mesma abstração `PrivKey`/`PubKey`, já que ele usava `package:cryptography` diretamente sem conformar à interface. Raw privado = 64 bytes `seed‖publicKey` (formato de `ed25519.PrivateKey` do Go); como `package:cryptography` só expõe a seed de 32 bytes de forma síncrona, a concatenação é feita uma vez, de forma assíncrona, na fábrica (`generateEd25519KeyPair`/`unmarshalEd25519PrivateKey`), mantendo `raw()` síncrono como nos outros três tipos. Validado contra `crypto/ed25519` do Go (`go-ipfs-reference/ed25519_vectors/main.go`): assinatura EdDSA determinística bate byte a byte -- `test/ed25519_key_parity_test.dart`. **`key_codec.dart`** (novo, sem arquivo Go correspondente 1:1 -- é a contraparte de `MarshalPublicKey`/`UnmarshalPublicKey`/`MarshalPrivateKey`/`UnmarshalPrivateKey` de `core/crypto/key.go`): despacha por `KeyType` entre os quatro tipos concretos, usado por qualquer código que recebe uma chave de identidade de tipo desconhecido (ex.: o payload do handshake Noise) -- `test/key_codec_test.dart`. Com isso, os quatro tipos de chave do protobuf `crypto.pb.KeyType` (RSA/Ed25519/Secp256k1/ECDSA) têm cobertura uniforme. O gap real que impede conexão com peers não-Ed25519 continua sendo o handshake Noise (`p2p/security/noise`, hardcoded pra Ed25519 -- ver nota acima), não este pacote; os tipos de chave aqui são pré-requisito pro payload de assinatura do Noise, não a correção em si. |
| `core/crypto/pb` | `packages/transpiled_libp2p/lib/src/core/crypto/key_types.dart` (`marshalKeyProto`/`unmarshalKeyProto`, protobuf mínimo de 2 campos hand-rolled: `PublicKey`/`PrivateKey{Type,Data}`) + duplicata equivalente em `packages/transpiled_libp2p/lib/src/core/peer/peer_id.dart` (`_marshalPublicKeyProto`, só encode) | portado sem teste de paridade formal (coberto indiretamente pelos testes de `rsa_key_parity_test.dart` e `peer_id_test.dart`) | `key_types.dart` agora tem encode E decode general-purpose (campos em qualquer ordem, valida `KeyType` desconhecido/mensagem truncada); `peer_id.dart` ainda tem sua própria cópia só-encode mais antiga -- oportunidade de limpeza: fazer `peer_id.dart` reusar `marshalKeyProto`/`KeyType` de `dart_ipfs_core` em vez de manter duas implementações do mesmo formato. Ainda não geramos código de um `.proto` real -- é só os 2 campos hand-rolled; revisitar se vale migrar pra protobuf codegen de verdade (o projeto já usa `protoc`-gerado em outros lugares, ver `lib/src/proto/`). |
| `core/discovery` |  | não iniciado |  |
| `core/event` |  | não iniciado |  |
| `core/host` |  | não iniciado |  |
| `core/internal/catch` |  | não iniciado |  |
| `core/metrics` |  | não iniciado |  |
| `core/network` |  | não iniciado |  |
| `core/network/mocks` |  | não iniciado |  |
| `core/peer` | `packages/transpiled_libp2p/lib/src/core/peer/peer_id.dart` (`ID` -- `peer.go`) + `addr_info.dart` (`AddrInfo` -- `addrinfo.go`) + `peer_record.dart` (`PeerRecord` -- `record.go`) | **portado com paridade comprovada** | `IDFromPublicKey`/`IDFromPrivateKey` corrigidos e completos (`PeerId.fromPubKey`/`fromPrivateKey`, ver nota acima sobre o bug original). Resto de `peer.go` completo: `IDFromBytes`, `Decode` (base58 legado ou CID), `FromCid`/`ToCid` (`libp2p-key` codec via `transpiled_cid`), `ID.Validate`, `ID.ShortString`, `MatchesPublicKey`/`MatchesPrivateKey`, `ExtractPublicKey`, e `IDSlice`'s ordenação bytewise (`PeerId implements Comparable<PeerId>`, já que `sort.Interface` não existe em Dart). `peer_serde.go` completo: `MarshalBinary`/`UnmarshalBinary`, `MarshalText`/`UnmarshalText` (o par `Marshal`/`MarshalTo`/`Size` do gogo-proto não foi portado -- é idêntico a `MarshalBinary`, não é uma lacuna real). `addrinfo.go`/`addrinfo_serde.go` completos: `SplitAddr` (precisou `Multiaddr.splitLast()`, adicionado ao `transpiled_multiaddr`), `IDFromP2PAddr`, `AddrInfoFromString`/`AddrInfoFromP2pAddr`/`AddrInfoToP2pAddrs`, `AddrInfosFromP2pAddrs`/`AddrInfosToIDs`, `Loggable`, serialização JSON (`toJson`/`fromJson`). Note "`Set`" citada numa versão anterior desta linha não existe na versão vendorizada de `go-libp2p` em `go-ipfs-reference/` -- foi removida do pacote real em algum momento; correção do registro, não uma lacuna. `record.go` completo: `PeerRecord`, `PeerRecordFromAddrInfo`, `PeerRecordFromProtobuf`/`ToProtobuf`, `TimestampSeq` (adaptado pra microssegundos*1000, `DateTime` do Dart não expõe nanossegundos -- a garantia de estritamente-crescente se mantém), registro automático em `Envelope` via `registerType` no construtor (não em `library`-level init -- ver nota em `peer_record.dart`, inicialização de topo em Dart é preguiçosa, não roda só por importar como o `init()` do Go faria). Testes com vetores reais do próprio `peer_test.go`/`addrinfo_test.go` do go-libp2p (a chave RSA e o peer ID `QmcJeseo...` do keyset `man`, os multiaddrs de `addrinfo_test.go`) em `test/peer_id_test.dart`/`test/addr_info_test.dart`/`test/peer_record_test.dart`. |
| `core/peer/pb` | `packages/transpiled_libp2p/lib/src/core/peer/peer_record.dart` (protobuf de `PeerRecord{peer_id, seq, addresses}` hand-rolled, 3 campos + submensagem `AddressInfo{multiaddr}`) | portado sem teste de paridade formal isolado (coberto indiretamente por `peer_record_test.dart`) |  |
| `core/peerstore` |  | não iniciado |  |
| `core/pnet` |  | não iniciado |  |
| `core/protocol` |  | não iniciado |  |
| `core/record` | `packages/transpiled_libp2p/lib/src/core/record/record.dart` (`Record`, `RegisterType` -- `record.go`) + `envelope.dart` (`Envelope`, `Seal`, `Consume(Typed)Envelope` -- `envelope.go`) | **portado com paridade comprovada** | `Record` interface + registro completos: `registerType`/`unmarshalRecordPayload`, adaptado pra usar uma *factory function* (`Record Function()`) em vez de refletir um `reflect.Type` registrado (Dart não tem `reflect.New` a partir de um token de tipo em runtime) -- a factory é chamada uma vez na hora do registro (pra ler `codec()`) e de novo a cada unmarshal, mesmo efeito líquido do padrão Go. `Envelope` completo: `Seal`, `ConsumeEnvelope`, `ConsumeTypedEnvelope`, `UnmarshalEnvelope`/`marshal`, `equals`, `record()`/`typedRecord`, `_validate` com o mesmo domain-separation (`makeUnsigned`: cada campo prefixado por varint de comprimento, concatenado) -- buffer pooling do Go (`go-buffer-pool`) não portado, é otimização de performance sem efeito observável, GC do Dart cobre o caso. Protobuf de `Envelope{public_key, payload_type, payload, signature}` (campos 1/2/3/5, hand-rolled) reaproveita `marshalPublicKey`/`unmarshalPublicKey` (`key_codec.dart`) pro campo `public_key` aninhado, já que é o mesmo formato `crypto.pb.PublicKey`. Testes com vetores do próprio `record_test.go`/`envelope_test.go` do go-libp2p (incluindo os testes de adulteração de domain/payload/payloadType que provam rejeição de assinatura) em `test/record_test.dart`/`test/envelope_test.dart`. |
| `core/record/pb` | `packages/transpiled_libp2p/lib/src/core/record/envelope.dart` (protobuf de `Envelope{public_key, payload_type, payload, signature}` hand-rolled) | portado sem teste de paridade formal isolado (coberto indiretamente por `envelope_test.dart`) |  |
| `core/routing` | `packages/transpiled_libp2p/lib/src/core/routing/{routing,options,query}.dart` | **portado com paridade comprovada** | Além de `routing.go`/`options.go` já registrados, `query.go` está em `query.dart`: valores 0–7, serialização JSON, buffer 16, ordenação e cópia profunda de respostas. `context.Value`/canal Go foi adaptado para `Zone` + `QueryEventRegistration`; `close()` cancela novas publicações e drena eventos enfileirados. Vetores Dart em `test/query_event_test.dart`; `go test ./core/routing`, análise direcionada e `dart test -j 1` passaram. |
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
| `p2p/security/noise` | `packages/transpiled_libp2p/lib/src/p2p/security/noise/noise_state.dart` (núcleo) + `noise_handshake_payload.dart` (payload assinado) + `noise_framing.dart` (framing pós-handshake, standalone) + `dart_ipfs_noise_security.dart` (wiring real) | **portado com paridade comprovada e ligado no transporte real** | Portado: `CipherState`/`SymmetricState`/`HandshakeState` completos pro cipher suite fixo que o go-libp2p sempre usa (`DH25519, CipherChaChaPoly, HashSHA256`, padrão `XX`), validado byte a byte contra vetor real do `flynn/noise` -- `test/transport/noise/noise_state_test.dart`. Payload assinado validado contra um payload real construído com `core/crypto`+`core/peer`+`p2p/security/noise/pb` de verdade do go-libp2p (protobuf `protoc`-gerado, não hand-rolled) -- `test/transport/noise/noise_handshake_payload_test.dart`. Framing pós-handshake (`rw.go`: length-prefix de 2 bytes, chunking em `MaxPlaintextLength`) portado standalone em `noise_framing.dart` e testado (`test/transport/noise/noise_framing_test.dart`) -- **mas não é o que roda em produção**: ver nota abaixo. Achei e corrigi dois erros reais nas MINHAS PRÓPRIAS asserções de teste do núcleo Noise ao comparar contra o vetor (não no protocolo em si, detalhes preservados no histórico do commit `47302e2d`). **Wiring real** (`dart_ipfs_noise_security.dart`, `DartIpfsNoiseSecurity implements SecurityProtocol` de `ipfs_libp2p`, plugado em `lib/src/transport/libp2p_router.dart` via `config.Libp2p.security(...)`): a causa raiz real do bug original não era o guard `create()` de `ipfs_libp2p`'s `NoiseSecurity` (que checa o tipo da chave LOCAL, que já era sempre Ed25519 -- nunca disparava), e sim `_verifyHandshakePayload`/`secureOutbound`/`secureInbound` chamarem `Ed25519PublicKey.unmarshal()` incondicionalmente na chave de identidade do peer REMOTO, não importando o `KeyType` real no payload -- qualquer peer real com RSA/Secp256k1/ECDSA seria mal-interpretado e rejeitado na verificação de assinatura. Como `ipfs_libp2p` é dependência de terceiro (pub.dev, `stephanfeb/dart_libp2p`, não editável neste repo), a correção só podia ser uma implementação nova de `SecurityProtocol` neste repo, escolhida em vez de copiar+corrigir o `NoiseXXPattern` deles (não auditado) porque já tínhamos handshake mechanics própria com paridade Go comprovada. Reaproveita a própria `SecuredConnection` de `ipfs_libp2p` pro transporte pós-handshake -- **confirmado por leitura de código que seu framing interno (`_writeFrame`/`_readAndDecryptMessage`) é byte-a-byte idêntico ao `rw.go` real** (length-prefix 2 bytes BE, ChaCha20-Poly1305, AAD vazio, nonce = 4 bytes zero + contador 8 bytes little-endian) -- então `noise_framing.dart` fica como referência standalone validada, não duplicada na integração real. Identidade remota (RSA/Ed25519/Secp256k1/ECDSA) despachada via `key_codec.dart` do `dart_ipfs_core`, bridged pra tipos do `ipfs_libp2p` reusando o dispatcher genérico deles (`publicKeyFromProto`) sobre os MESMOS bytes de wire protobuf -- funciona pra RSA/Ed25519/ECDSA; Secp256k1 falha nesse bridge específico porque nem o `ipfs_libp2p` tem parser de Secp256k1 (`PubKeyUnmarshallers` comentado pra esse tipo), então `establishedRemotePublicKey` fica `null` nesse caso (degradação graciosa, não falha o handshake -- campo opcional). **Achado um segundo bug real e pré-existente em `ipfs_libp2p`, independente do já conhecido**: `RsaPublicKey.fromRawBytes`/`unmarshal` deles espera DER PKCS1 `SEQUENCE{n,e}` puro, não o PKIX `SubjectPublicKeyInfo` que `x509.MarshalPKIXPublicKey`/`core/crypto`'s `RsaPublicKey.Raw()` do go-libp2p realmente produzem -- então mesmo corrigindo só o guard de tipo, a implementação de RSA deles quebraria com peers reais; por isso `establishedRemotePublicKey` também fica `null` pra RSA (a autenticação em si não depende disso -- é feita inteiramente pelo `verifyNoiseHandshakePayload` próprio antes de chegar em `ipfs_libp2p`). Identidade local: `libp2p_router.dart` agora deriva a mesma seed de 32 bytes pros dois lados (`core_crypto.ed25519KeyPairFromSeed` novo em `dart_ipfs_core` + `Ed25519PrivateKey.fromRawBytes` de `ipfs_libp2p`), já que o `KeyPair` do `ipfs_libp2p` gerado do jeito antigo (`generateEd25519KeyPair()`) não expõe os bytes crus da chave privada depois de criado (limitação real da própria lib) -- tipo de identidade LOCAL continua só Ed25519 por enquanto (`_keyType` hardcoded, fora de escopo desta correção, que era sobre autenticar peers REMOTOS de qualquer tipo). **Validado com testes reais de conexão** (não mockados): `dart_ipfs_noise_security_test.dart` roda o handshake completo fim a fim sobre um par de `TransportConn` fake em memória, incluindo uma identidade RSA completando autenticação (o caso que `ipfs_libp2p`'s `NoiseSecurity` rejeitaria) e um write de >2 frames (chunking) batendo. `test/transport/libp2p_router_test.dart`'s testes de integração existentes (`should connect to another peer`, `should send and receive messages`) continuam passando com sockets TCP reais de verdade, agora securizados pelo Noise próprio em vez do `ipfs_libp2p`. |
| `p2p/security/noise/pb` | `packages/transpiled_libp2p/lib/src/p2p/security/noise/noise_handshake_payload.dart` (protobuf mínimo de 2 campos hand-rolled: `identity_key`, `identity_sig` -- campo `extensions` (`NoiseExtensions{webtransport_certhashes, stream_muxers}`) não implementado, não usado pelo handshake básico) | portado sem teste de paridade formal isolado (coberto indiretamente por `noise_handshake_payload_test.dart`, que valida o wire format completo contra protobuf real gerado por `protoc`) |  |
| `p2p/security/tls` |  | não iniciado |  |
| `p2p/security/tls/cmd` |  | não iniciado |  |
| `p2p/security/tls/cmd/tlsdiag` |  | não iniciado |  |
| `p2p/test/backpressure` |  | não iniciado |  |
| `p2p/test/reconnects` |  | não iniciado |  |
| `p2p/test/resource-manager` |  | não iniciado |  |
| `p2p/transport/quic` | `packages/dart_ipfs_quic/` (`QuicTransport`/`QuicConnection`, sobre o `quic_lib` de terceiro) | **bloqueado por arquitetura, documentado, não corrigido** | Corrigido um bug pequeno e real: `QuicTransport.canDial`/`canListen` reivindicava endereços `.../quic-v1/webtransport` que pertencem ao WebTransport, quebrando-o sempre que QUIC também estava habilitado. Além disso: discagem QUIC real quebra com `UnsupportedError` porque o `Swarm`/`BasicUpgrader` do `ipfs_libp2p` roda incondicionalmente negociação de segurança (Noise) + muxer sobre QUALQUER transporte, sem exceção pra transportes autossegurados/automultiplexados como QUIC de verdade -- e pior, `Swarm.newStream()` (usado por DHT/Bitswap/Identify via `Host.newStream()`) exige um `SwarmConn` interno, então uma conexão QUIC só pode ser usada pelo resto da pilha de protocolo se vier do próprio caminho de discagem do `Swarm` (o mesmo que força a negociação que QUIC de verdade não usa). Ser compatível com peers QUIC reais E utilizável pelo DHT/Bitswap/Identify como estão hoje são mutuamente exclusivos sem editar o `ipfs_libp2p` (dependência de terceiro, não editável neste repo -- mesma restrição do Noise). Decisão: arquivado como pendência deliberada, não perseguido agora. Detalhe completo, incluindo as duas rotas possíveis (QUIC só-entre-dart_ipfs vs. reescrever o caminho de stream do DHT/Bitswap/Identify pra contornar o Swarm) em `doc/specs/QUIC_TRANSPORT_RFC.md`, seção "Architectural blocker (2026-08-25)" -- ler antes de retomar. |
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
| `cmd/ipfs` |  | fora do escopo (exclusivamente CLI) |  |
| `cmd/ipfs/kubo` |  | fora do escopo (exclusivamente CLI) |  |
| `cmd/ipfs/util` |  | fora do escopo (exclusivamente CLI) |  |
| `cmd/ipfswatch` |  | fora do escopo (exclusivamente CLI) |  |
| `commands` |  | fora do escopo (exclusivamente CLI) |  |
| `config` |  | não iniciado |  |
| `config/serialize` |  | não iniciado |  |
| `core` |  | não iniciado |  |
| `core/commands` |  | fora do escopo (exclusivamente CLI) |  |
| `core/commands/cmdenv` |  | fora do escopo (exclusivamente CLI) |  |
| `core/commands/cmdutils` |  | fora do escopo (exclusivamente CLI) |  |
| `core/commands/dag` |  | fora do escopo (exclusivamente CLI) |  |
| `core/commands/e` |  | fora do escopo (exclusivamente CLI) |  |
| `core/commands/keyencode` |  | fora do escopo (exclusivamente CLI) |  |
| `core/commands/name` |  | fora do escopo (exclusivamente CLI) |  |
| `core/commands/object` |  | fora do escopo (exclusivamente CLI) |  |
| `core/commands/pin` |  | fora do escopo (exclusivamente CLI) |  |
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
| `fuse/fusetest` |  | fora do escopo (helper de teste) |  |
| `fuse/ipns` |  | fora do escopo (somente CLI/testes) | Callers de produção encontrados somente na montagem iniciada pela CLI. |
| `fuse/mfs` |  | fora do escopo (somente CLI/testes) | Callers de produção encontrados somente na montagem iniciada pela CLI. |
| `fuse/mount` |  | não iniciado | Importado por `core/core.go`; fornece os tipos de estado de montagem expostos pelo nó. |
| `fuse/node` |  | fora do escopo (somente CLI/testes) | Callers de produção encontrados em `cmd/ipfs/kubo/daemon.go` e `core/commands`. |
| `fuse/readonly` |  | fora do escopo (somente CLI/testes) | Usado por `fuse/node`, que é CLI-only no grafo atual. |
| `fuse/writable` |  | fora do escopo (somente CLI/testes) | Usado por `fuse/ipns`/`fuse/mfs`, que são CLI-only no grafo atual. |
| `gc` |  | não iniciado |  |
| `internal/fusemount` |  | não iniciado | Importado por `core/coreapi`; marca chamadas de publicação originadas por FUSE. |
| `misc/fsutil` |  | não iniciado |  |
| `p2p` |  | não iniciado |  |
| `plugin` |  | não iniciado |  |
| `plugin/loader` |  | não iniciado | Usado pelo exemplo oficial `docs/examples/kubo-as-a-library` para registrar plugins embutidos. |
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
| `repo/fsrepo/migrations` |  | não iniciado | `repo/fsrepo` usa `RepoVersion` e `WriteRepoVersion`; também contém migrações embutidas. |
| `repo/fsrepo/migrations/atomicfile` |  | não iniciado | Dependência das migrações embutidas via `common`. |
| `repo/fsrepo/migrations/common` |  | não iniciado | Dependência das migrações embutidas 16→17 e 17→18. |
| `repo/fsrepo/migrations/fs-repo-16-to-17` |  | fora do escopo (wrapper CLI `main`) | A lógica reutilizável está no subpacote `migration`. |
| `repo/fsrepo/migrations/fs-repo-16-to-17/migration` |  | não iniciado | Importado por `migrations/embedded.go`. |
| `repo/fsrepo/migrations/fs-repo-17-to-18` |  | fora do escopo (wrapper CLI `main`) | A lógica reutilizável está no subpacote `migration`. |
| `repo/fsrepo/migrations/fs-repo-17-to-18/migration` |  | não iniciado | Importado por `migrations/embedded.go`. |
| `repo/fsrepo/migrations/ipfsfetcher` |  | fora do escopo (somente CLI/testes) | Callers de produção encontrados apenas em `cmd/ipfs/kubo/add_migrations.go`. |
| `routing` |  | não iniciado |  |
| `test/api-startup` |  | não iniciado |  |
| `test/bench/bench_cli_ipfs_add` |  | fora do escopo (exclusivamente CLI) |  |
| `test/bench/offline_add` |  | não iniciado |  |
| `test/cli` |  | fora do escopo (exclusivamente CLI) |  |
| `test/cli/harness` |  | fora do escopo (exclusivamente CLI) |  |
| `test/cli/testutils` |  | fora do escopo (exclusivamente CLI) |  |
| `test/cli/testutils/httprouting` |  | fora do escopo (exclusivamente CLI) |  |
| `test/cli/testutils/pinningservice` |  | fora do escopo (exclusivamente CLI) |  |
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

### `go-block-format`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_block_format/lib/src/blocks.dart` | **portado com paridade comprovada (caminho padrão)** | `Block`, `BasicBlock`, `NewBlock`, `NewBlockWithPrefix`, `NewBlockWithCid`, `Multihash`, `RawData`, `Cid`, `String` e `Loggable`; erro `ErrWrongHash` preservado para o modo de depuração. Fonte fixada em `UPSTREAM_LOCK.md` (v0.2.4). Como no Go, `NewBlockWithCid` aceita CID confiável no caminho padrão (`boxo/util.Debug=false`); o toggle global de depuração ainda precisa ser integrado quando `boxo/util` for portado. Testes Dart cobrem CIDv0 e metadados; `go test ./...` passou no módulo clonado. |

### `boxo`

**Nota de cobertura (2026-08-25)**: é o módulo com mais implementação original já existente de toda esta lista, mas espalhada e não mapeada linha a linha contra os 114 pacotes reais do boxo -- por isso as linhas abaixo continuam em branco em vez de marcadas uma a uma. O que já existe e funciona: `lib/src/protocols/bitswap/` (7 arquivos, 1974 linhas, ~ `bitswap`+`bitswap/client`+`bitswap/server`+`bitswap/message`), `lib/src/core/unixfs/` (8, 1181, ~ pacote `unixfs` do próprio boxo -- que na verdade vive em `go-unixfsnode`, não clonado), `lib/src/services/gateway/` (23 arquivos, ~ `gateway`), `lib/src/core/data_structures/car.dart` (835 linhas, ~ `car`/`ipld/car`, mas o formato real vem do módulo separado `go-car/v2`, também não clonado), `lib/src/core/mfs/` (~ `mfs`), `lib/src/protocols/ipns/` (~ parte de `ipns`/`namesys`). Nenhum foi comparado função-a-função com o boxo real ainda -- status real de todos: `implementação original não auditada`, não `não iniciado`.

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `autoconf` |  | não iniciado |  |
| `util` | `packages/transpiled_boxo/lib/src/util/{util,time,file}.dart` | **portado com paridade comprovada** | Fonte fixada em `doc/transpilation/UPSTREAM_LOCK.md` (Boxo SHA `25b1db8931508bb069eb6e67243b34d353cbe845`). Porte das APIs públicas de `util.go`, `time.go` e `file.go`: `FileExists`, RFC3339 UTC, `Debug`, erros sentinela, `ErrCast`, `ExpandPathnames`, `GetenvBool`, `Partition`/`RPartition`, `Hash` (SHA2-256 via `transpiled_multihash`), `IsValidHash` (Base58 via `transpiled_base58`) e `XOR`. Testes Dart derivados dos vetores Go; `go test ./util`, `dart analyze` e `dart test -j 1` passam. Benchmarks e detalhes de `runtime/debug` além do stack trace de `ErrCast` não foram portados. |
| `bitswap` | `lib/src/protocols/bitswap/` (ver nota acima) | implementação original não auditada |  |
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
| `bitswap/client/wantlist` | `packages/transpiled_boxo/lib/src/bitswap/client/wantlist/{wantlist,want_type}.dart` | **portado com paridade comprovada** | `NewRefEntry`, `New`, `Len`, `Add`, `Remove`, `RemoveType`, `Has`, `Get` e `Entries`, incluindo cache, precedência Block/Have e ordenação por prioridade. `WantType` preserva os valores protobuf `Block=0` e `Have=1`. Vetores de `wantlist_test.go` adaptados em 10 testes Dart; `go test ./bitswap/client/wantlist`, `dart analyze` e `dart test -j 1` passaram. |
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
| `bitswap/wantlist` | `packages/transpiled_boxo/lib/bitswap/wantlist.dart` | **portado com paridade comprovada** | Forwarder depreciado de `forward.go`: `Entry`/`Wantlist` como aliases e `newWantlist`/`newRefEntry` (correspondentes Dart de `New`/`NewRefEntry`) encaminhando para `bitswap/client/wantlist`; teste mínimo de identidade e uso. `go test ./bitswap/wantlist`, `dart analyze` e `dart test -j 1` passaram. |
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
| `(root)` | `packages/transpiled_ipld_prime/lib/transpiled_ipld_prime.dart` (barrel) | **portado com paridade comprovada** | O pacote `ipld` raiz do Go (`datamodel.go`, `linking.go`, `schema.go`, `codec.go`, `adl.go`, `operations.go`) é só um facade de re-export/alias sobre `datamodel`/`linking`/`schema` -- os próprios mantenedores do Go documentam isso como "transicional"/"namespace noise que pode ser removido um dia". O barrel Dart já cumpre exatamente esse papel: expõe os símbolos de `datamodel` (portados, ver a linha `datamodel` abaixo) direto no top-level do pacote, sem prefixo, igual ao que o facade Go faz. Nada a portar aqui além do próprio barrel. |
| `adl` |  | não iniciado |  |
| `adl/rot13adl` |  | não iniciado |  |
| `codec` | `packages/transpiled_ipld_prime/lib/src/codec/api.dart` | **portado com paridade comprovada** | Tipos `Encoder`/`Decoder`, `ErrBudgetExhausted` e `MapSortMode`; os valores e a mensagem de erro são cobertos em `test/codec/api_test.dart`. |
| `codec/cbor` |  | não iniciado |  |
| `codec/dagcbor` | `lib/src/core/ipld/codecs/standard_codecs.dart` (`DagCborCodec`) | implementação original não auditada | Codec funcional já em uso, nunca comparado byte a byte com este pacote. |
| `codec/dagjson` | `packages/transpiled_ipld_prime/lib/src/codec/dagjson/codec.dart` + implementação legada | portado sem teste de paridade | Encode/decode básico de Node, bytes e CID; canonicalização/opções/erros completos ainda precisam auditoria contra Go. |
| `codec/json` | `packages/transpiled_ipld_prime/lib/src/codec/json/codec.dart` (+ `lib/codec/json.dart`) | **portado com paridade comprovada** | `encode`/`decode` para JSON ordinário, usando `dart:convert`; mapas preservam ordem de iteração e a saída usa indentação por tab e newline como o `refmt/json` do Go. Links e bytes são rejeitados com as mesmas mensagens do `codec/json` Go (ao contrário de DAG-JSON). Testes derivados de `marshal_test.go` e cobrindo decodificação e formatação em `test/codec/json_test.dart`. `registerJsonCodec` registra o código `Multicodec.code('json')` (`0x0200`); o registry padrão o instala automaticamente no primeiro acesso, compensando a inicialização lazy de top-level do Dart. |
| `codec/raw` | `packages/transpiled_ipld_prime/lib/src/codec/raw/codec.dart` | **portado com paridade comprovada** | `Encode`/`Decode` preservam bytes, propagação de erros e reuso de `Uint8List`; vetores de `codec/raw/codec_test.go` adaptados. `registerRawCodec` registra `Multicodec.code('raw')` (`0x55`) e o registry padrão o instala automaticamente no primeiro acesso. A integração com `LinkSystem` agora é coberta em `test/linking_test.dart`. Não usar a implementação original do guarda-chuva como evidência de paridade. |
| `datamodel` | `packages/transpiled_ipld_prime/lib/src/datamodel/{kind,path_segment,path,link,node,node_builder,errors,null_node,copy,equal}.dart` | **portado com paridade comprovada** | `Kind`/`KindSet` (`kind.go`, enum Dart com campo `code` guardando o char ASCII original, só por rastreabilidade/debug), `PathSegment` (`pathSegment.go`, união string-ou-int portada do mesmo jeito que o Go -- campos `_s`/`_i` com sentinela, Dart não tem união mais leve também), `Path` (`path.go`), `Link`/`LinkPrototype` (`link.go`, interfaces puras; implementação CID está na linha `linking/cid`), `Node`/`NodePrototype`/`NodePrototypeSupportingAmend`/`MapIterator`/`ListIterator`/`UintNode`/`LargeBytesNode` (`node.go`; `io.ReadSeeker` do `LargeBytesNode` virou um `ByteReadSeeker` mínimo próprio, já que Dart não tem uma interface seekable-genérica equivalente em `dart:core`/`dart:io`), `NodeAssembler`/`MapAssembler`/`ListAssembler`/`NodeBuilder` (`nodeBuilder.go`), `ErrWrongKind`→`WrongKindException`/`ErrNotExists`→`NotExistsException`/`ErrRepeatedMapKey`→`RepeatedMapKeyException`/`ErrInvalidSegmentForList`→`InvalidSegmentForListException`/`ErrIteratorOverread`→`IteratorOverreadException` (`errors.go`), `Null`→`nullNode`/`Absent`→`absentNode` (`unit.go`), `Copy`→`copyNode` (`copy.go`), `DeepEqual`→`deepEqual` (`equal.go`). **Divergência de convenção deliberada**: todo método Go que retorna `(valor, error)` (lookups, `As*`, `Next()` dos iteradores) virou um método que retorna só o valor e LANÇA uma exceção no erro -- mesma convenção já usada em `transpiled_libp2p` (ex. `PeerId.extractPublicKey`), não um padrão novo. Testado contra vetores reais de `kind_test.go` (`TestErrWrongKind_String`), `path_test.go` (`TestParsePath`; `TestPathSegmentZeroValue` não portado -- testa especificamente o "pegadinha" do valor-zero de struct do Go, que não existe em Dart já que toda `PathSegment` precisa passar por um construtor nomeado explícito). `equal_test.go`/`copy_test.go` (`TestDeepEqual`/`TestCopy`) **não puderam usar os fixtures reais do Go** (que dependem de `node/basicnode`+`fluent/qp`+`linking/cid`, nenhum portado ainda) -- os MESMOS casos de teste (mesmas entradas, mesmo resultado esperado) foram reproduzidos usando um `Node`/`NodeBuilder` mínimo e propositalmente simples (`test/fixtures/simple_node.dart`, NÃO um port do `basicnode` real, só o suficiente pra exercitar `deepEqual`/`copyNode`) -- documentado no cabeçalho do arquivo de teste e aqui pra não ser confundido com o port real de `node/basicnode`, que continua "não iniciado" na tabela abaixo. |
| `fluent` | `packages/transpiled_ipld_prime/lib/fluent.dart` | portado com paridade comprovada |  |
| `fluent/qp` | `packages/transpiled_ipld_prime/lib/fluent/qp.dart` | portado com paridade comprovada | API completa de `qp.go`: `BuildMap`/`BuildList` → `buildMap`/`buildList` (records `(Node?, Object?)` para valor+erro), `Map`/`List`/`MapEntry`/`ListEntry` e todos os helpers escalares (`Null`, `Bool`, `Int`, `Float`, `String`, `Bytes`, `Link`, `Node`) em convenção Dart. Teste do exemplo oficial, erro de chave duplicada e todos os tipos; `go test ./fluent/qp` passa. Busca no pub.dev não encontrou pacote Dart/IPLD substituto relevante; nenhuma dependência adicionada. |
| `linking` | `packages/transpiled_ipld_prime/lib/src/linking/linking.dart` (+ `lib/linking.dart`) | **portado com paridade comprovada** | `LinkSystem` completo (`Load`/`LoadPlusRaw`/`LoadRaw`/`Fill`/`Store`/`ComputeLink` e variantes `Must*`), `LinkContext`, openers, `NodeReifier`, `ErrLinkingSetup`→`LinkingSetupException`, `ErrHashMismatch`→`HashMismatchException` e configuração por storage (`types.go`, `errors.go`, `functions.go`, `setup.go`). Exceções são o fluxo de erro idiomático Dart, portanto `Must*` só delega ao método normal; `context.Context` virou campo opaco `Object?` (Dart não tem cancelamento síncrono equivalente). Testes derivados de `functions_test.go` cobrem Store→Load/LoadRaw/LoadPlusRaw, bytes e prioridade de hash mismatch sobre erro de decoder; `go test ./linking/...` passa no SHA travado. |
| `linking/cid` | `packages/transpiled_ipld_prime/lib/src/linking/cid/{cid_link,link_system}.dart` (+ `lib/linking_cid.dart`) | **portado com paridade comprovada** | `Link`/`LinkPrototype` baseados em `CID`, `DefaultLinkSystem`/`LinkSystemUsingMulticodecRegistry` e `Memory`; preserva string, bytes binários, prefixo, construção por digest e chaveamento de memória por multihash. Testes Dart validam round-trip CID real e integração raw; `go test ./linking/...` passa. |
| `linking/preload` |  | não iniciado |  |
| `multicodec` | `packages/transpiled_ipld_prime/lib/src/multicodec/registry.dart` (+ `lib/codec.dart`) | **portado com paridade comprovada** | `Registry`/`DefaultRegistry` e atalhos globais `RegisterEncoder`/`LookupEncoder`/`ListEncoders`/`RegisterDecoder`/`LookupDecoder`/`ListDecoders`, com substituição na mesma chave e erros equivalentes. Testado em `test/multicodec/registry_test.dart`; `registerJsonCodec`/`registerRawCodec` cobrem os registros `0x0200`/`0x55`, instalados automaticamente no primeiro acesso ao registry padrão. Sem mutex, como no Go: uso concorrente exige sincronização do chamador. |
| `must` |  | não iniciado |  |
| `node` |  | não iniciado |  |
| `node/basic` |  | não iniciado |  |
| `node/basicnode` | `packages/transpiled_ipld_prime/lib/src/basicnode/{base_node,scalars,stream_bytes,any_node,list_node,map_node,value_assembler,prototypes}.dart` | **portado com paridade comprovada** | Implementação concreta de `Node`/`NodeBuilder` genérica pra qualquer valor do Data Model: `plainBool/Int/Uint/Float/String/Bytes/Link` → `PlainBool/Int/Uint/Float/String/Bytes/Link` (`bool.go`/`int.go`/`float.go`/`string.go`/`bytes.go`/`link.go`), `streamBytes` → `StreamBytes` (`bytes_stream.go`, com um `ByteReadSeeker` próprio no lugar de `io.ReadSeeker` -- ver nota da linha `datamodel`), `anyBuilder` → `AnyBuilder` (`any.go`), `plainList`/`plainMap` → `PlainList`/`PlainMap` (`list.go`/`map.go`), `Prototype` (`prototypes.go`). **Duas simplificações deliberadas, ambas documentadas nos comentários de cabeçalho dos arquivos**: (1) o pacote `node/mixins` do Go (structs por Kind com os métodos "sempre erro wrong-kind", pensados pra inlining zero-alloc do compilador Go) virou duas classes-base Dart (`BaseNode`/`BaseAssembler` em `base_node.dart`) com implementações-padrão que lançam exceção -- mesmo `WrongKindException` com os mesmos campos, só que via herança em vez de composição de struct; (2) os tipos `plainX__Builder`/`plainX__Assembler` separados do Go (só existem pra `NewBuilder` fazer uma alocação em vez de duas) viraram uma única classe por kind que implementa `NodeBuilder` diretamente, e os tipos `plainList__ValueAssembler`/`plainMap__ValueAssembler` + seus wrappers `...ValueAssemblerMap`/`...ValueAssemblerList` (que existem só pra amortizar alocação por elemento) viraram um único `ValueAssembler` reutilizável (`value_assembler.dart`) -- preservando o mesmo contrato observável, incluindo os guardas de "assembler expirado" (`ka.AssignString` duas vezes deve falhar) que o Go implementa anulando o ponteiro de volta pro pai; aqui via um flag `_used`/`_parent` nulável que lança `StateError` na segunda chamada. `MethodName` nas exceções usa o nome EXATO do método Go (`'LookupByIndex'`, não `'lookupByIndex'`) especificamente pra poder testar contra as strings de erro reais do Go byte a byte. Testado contra vetores reais de `int_test.go` (`TestBasicInt`, `TestIntErrors` -- strings de erro batendo exatamente com o Go) e das specs reutilizáveis de `node/tests` (`stringSpecs.go`'s `SpecTestString`, `byteSpecs.go`'s `SpecTestBytes`, `listSpecs.go`'s `SpecTestListString`, `mapSpecs.go`'s `SpecTestMapStrInt`/`SpecTestMapStrMapStrInt`/`SpecTestMapStrListStr`, incluindo os casos de chave repetida e assembler expirado) -- o *motor* genérico de spec-test do Go (`node/tests/testEngine.go`, feito pra rodar as mesmas specs contra N implementações incluindo nós tipados por schema) não foi portado, só os casos concretos, aplicados diretamente contra `Prototype.any`/`Prototype.map`/`Prototype.list`/`Prototype.string`/`Prototype.bytes` -- 24 testes ao todo neste pacote. |
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
| `storage` | `packages/transpiled_ipld_prime/lib/src/storage/{storage,memstore}.dart` (+ `lib/linking.dart`) | **portado com paridade comprovada** | Interfaces `Storage`/`ReadableStorage`/`WritableStorage` e capacidades opcionais streaming/vector/peek, helpers `Has`/`Get`/`Put`/`GetStream`/`PutStream`/`PutVec`/`Peek` e `memstore.Store`→`MemoryStore` (`api.go`, `funcs.go`, `memstore.go`). Streaming é síncrono (`Iterable`/`Sink`) porque codecs Dart já são síncronos; fallback de `putStream` mantém o commit único e bufferiza somente quando necessário. Coberto pela integração do `LinkSystem`; adaptadores fs/blockstore/datastore e sharding permanecem nas sublinhas. |
| `storage/bsadapter` |  | não iniciado |  |
| `storage/bsrvadapter` |  | não iniciado |  |
| `storage/dsadapter` |  | não iniciado |  |
| `storage/fsstore` |  | não iniciado |  |
| `storage/memstore` | `packages/transpiled_ipld_prime/lib/src/storage/memstore.dart` | **portado com paridade comprovada** | `Store` com cópia defensiva em `get`/`put`, fast paths `getStream`/`peek` e mapa exposto `bag`; exercitado por `test/linking_test.dart`. |
| `storage/sharding` |  | não iniciado |  |
| `storage/tests` |  | não iniciado |  |
| `testutil` |  | não iniciado |  |
| `testutil/garbage` |  | não iniciado |  |
| `traversal` | `packages/transpiled_ipld_prime/lib/src/traversal/traversal.dart` (+ `lib/traversal.dart`) | **portado com paridade comprovada** | `WalkLocal`/`WalkMatching`/`WalkAdv`/`WalkTransforming`, `Focus`/`Get`/`FocusedTransform`, `SelectLinks`, `Progress`/`Config`/`Budget`, callbacks, `SkipMe`, limites, pré-carregamento e crossing de links. O `context.Context` vira `Object?`; carregamento e preloader permanecem síncronos, conforme o `LinkSystem` Dart. Testes derivados de `walk_test.go`, `walk_with_stop_test.go`, `focus_test.go` e `select_links_test.go` cobrem ordem e paths, `SkipMe`, match/candidate, `StartAtPath`, links/`LastBlock`, falha sem loader, budgets, seleção de links e transforms. `dart analyze`, 59 testes Dart (`-j 1`) e `go test ./traversal/...` passam. |
| `traversal/patch` |  | não iniciado |  |
| `traversal/selector` | `packages/transpiled_ipld_prime/lib/src/traversal/selector/selector.dart` (+ `lib/traversal_selector.dart`) | **portado com paridade comprovada** | `Selector`/`CompileSelector`/deprecated `ParseSelector`, `ParseContext`, iterador de segmentos, todas as cláusulas (`Matcher` com `Slice`, `ExploreAll`/`Fields`/`Index`/`Range`/`Union`/`Recursive`/`RecursiveEdge`/`InterpretAs`) e `Condition` de link. Erros Go `(valor,error)` tornam-se `SelectorParseException`; `LargeBytesNode` usa o `ByteReadSeeker` já portado. Testes derivados de `matcher_test.go` e dos testes de cláusulas cobrem bounds de string/bytes, JSON inválido, erros, união, campos/índice/range e recursão limitada; `go test ./traversal/selector`, `dart analyze` e `dart test -j 1` passam. |
| `traversal/selector/builder` | `packages/transpiled_ipld_prime/lib/traversal_selector_builder.dart` | **portado com paridade comprovada** | `SelectorSpec`/`SelectorSpecBuilder`/`ExploreFieldsSpecBuilder`; os variádicos Go são `List<SelectorSpec>` em Dart. |
| `traversal/selector/parse` | `packages/transpiled_ipld_prime/lib/traversal_selector_parse.dart` | **portado com paridade comprovada** | `ParseJSONSelector`/`ParseAndCompileJSONSelector` e os quatro selectors comuns; usa o codec JSON já portado. |

### `go-libp2p-kad-dht`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `lib/src/protocols/dht/` (40 arquivos, 7171 linhas) | implementação original não auditada | Cliente DHT completo e em uso -- `dht_client.dart`, `dht_handler.dart`, `provider_store.dart`, `peer_store.dart`, `reprovider.dart`, `optimistic_provider.dart`, `rate_limiter.dart` -- mas escrito do zero, nunca comparado função-a-função com este módulo. Depende de `go-libp2p-kbucket`+`record`+`routing-helpers`+`boxo`+`go-datastore` (nenhum ainda portado) -- é o último módulo da ordem de construção recomendada, não o primeiro (ver "Estado em aberto" acima). |
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
| `(root)` | `lib/src/protocols/pubsub/` (14 arquivos, 2557 linhas, incl. `gossipsub/`) | implementação original não auditada | GossipSub funcional já em uso (`gossipsub_handler.dart`, `pubsub_client.dart`), escrito do zero. Módulo Go real tem ~27.500 linhas (incl. testes) e depende estruturalmente de `Host`/`Stream`/`Network` do `go-libp2p` (ainda não portado, vem do `ipfs_libp2p` de terceiro) -- ordem de grandeza bem maior e mais entrelaçada com libp2p do que qualquer módulo portado até agora nesta sessão (kbucket/datastore/ipld-prime são algorítmicos/autocontidos). Decisão desta sessão: portar primeiro só os subpacotes autocontidos, sem dependência de `Host`, deixando `PubSub`/`GossipSubRouter` (a orquestração central) pra quando `go-libp2p` Host/Stream estiver pronto -- mesmo padrão já usado pra `Parallel`/`Tiered` do `routing-helpers`. |
| `compat` |  | não iniciado | Compatibilidade com o protocolo floodsub legado -- não bloqueia nada. |
| `internal/gologshim` |  | fora do escopo | Shim de logging, não lógica de protocolo. |
| `internal/merkle` |  | não iniciado | Só um `example.go`, não lógica central. |
| `partialmessages` |  | não iniciado | Depende de `Host`/`Stream` -- fora do escopo desta rodada, ver nota da linha `(root)`. |
| `partialmessages/bitmap` | `packages/transpiled_libp2p_pubsub/lib/src/partialmessages/bitmap.dart` | **portado com paridade comprovada** | `Bitmap`/`NewBitmapWithOnesCount`/`Merge`/`IsZero`/`OnesCount`/`Set`/`Get`/`Clear`/`And`/`Or`/`Xor`/`Flip` (`bitmap.go`). **Bug real encontrado no próprio Go upstream, corrigido no port**: `Bitmap` é `[]byte` e `Set` recebe o receiver POR VALOR; o `append` que cresce o slice dentro de `Set` é invisível pro `Bitmap` do chamador (nunca retornado), então crescer via `Set` além do tamanho atual não tem efeito duradouro nenhum -- parece um bug latente do Go, não um comportamento intencional. Portado como classe Dart envolvendo um `Uint8List` que cresce o armazenamento COMPARTILHADO, corrigindo esse problema (crescimento fica visível pra qualquer titular do mesmo objeto `Bitmap`, coisa que a semântica de valor do slice do Go não permitia sem reatribuição). Sem `bitmap_test.go` no Go upstream -- testes escritos contra o contrato documentado de cada método (`test/partialmessages/bitmap_test.dart`, 8 testes). |
| `pb` |  | não iniciado | Mensagens protobuf do RPC do pubsub -- útil só quando `PubSub`/`GossipSubRouter` forem portados de verdade. |
| `timecache` | `packages/transpiled_libp2p_pubsub/lib/src/timecache/{time_cache,first_seen_cache,last_seen_cache,util}.dart` | **portado com paridade comprovada** | `TimeCache`/`Strategy`/`NewTimeCache`/`NewTimeCacheWithStrategy` (`time_cache.go`), `FirstSeenCache` (`first_seen_cache.go`), `LastSeenCache` (`last_seen_cache.go`), `background`/`sweep` (`util.go`, `sweep` mantido como função pura tomando `now` explicitamente -- o que também é o que torna a lógica de expiração testável deterministicamente sem depender de relógio real ou fake). `sync.RWMutex`/`sync.Mutex` do Go não portados (mesmo raciocínio do `go-libp2p-kbucket`: isolate único cooperativo do Dart não precisa). Testado contra vetores reais de `first_seen_cache_test.go`/`last_seen_cache_test.go` (`TestFirstSeenCacheFound/Expire/NotFoundAfterExpire`, `TestLastSeenCacheFound/Expire/SlideForward/NotFoundAfterExpire`) -- o Go usa `testing/synctest` (tempo virtual instantâneo dentro de uma "bolha"); este port usa delays reais curtos (`Future.delayed` na casa de 100-500ms) em vez de adicionar `package:fake_async` como dependência nova só pra isso, com margens generosas pra evitar flakiness -- mesmo comportamento reproduzido, só mais lento (ordem de segundos, não instantâneo). Mais o teste da própria função pura `sweep` com `DateTime` controlado, sem qualquer espera. 17 testes ao todo neste pacote. |

### `go-datastore`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_datastore/lib/src/{key,path_clean,datastore,basic_ds,null_ds,batch,features}.dart` (+ `lib/src/core/storage/` do guarda-chuva, não substituído ainda -- ver Notas) | **portado com paridade comprovada** | `Key` (`key.go`, incluindo `path.Clean` portado linha-a-linha em `path_clean.dart` já que `Key.Clean` depende dele diretamente), `Datastore`/`Read`/`Write`/`Batching`/`CheckedDatastore`/`ScrubbedDatastore`/`GCDatastore`→`GcDatastore`/`PersistentDatastore`/`TTLDatastore`→`TtlDatastore`/`Txn`/`TxnDatastore`/`Batch`/`ErrNotFound`→`NotFoundException`/`GetBackedHas`/`GetBackedSize`/`DiskUsage`/`QueryIter` (`datastore.go`, `context.Context` não portado como parâmetro -- nenhuma outra interface desta transpilação usa esse padrão; cancelamento fica a cargo dos próprios mecanismos de `Future`/`Stream` do Dart), `MapDatastore`/`LogDatastore`/`Shim`/`LogBatch` (`basic_ds.go`), `NullDatastore`/`nullTxn` (`null_ds.go`), `basicBatch`→`BasicBatch` (`batch.go`), `Feature`/`Features`/`FeatureByName`/`FeaturesForDatastore` (`features.go`, a reflexão genérica do Go via `reflect.TypeOf(...).Implements(...)` virou checagem `is` fixa por feature -- conjunto fechado de 7 features, sem preocupação de escala que justificasse replicar a reflexão). Testado contra vetores reais de `key_test.go` (`TestKeyBasic` via o helper `subtestKey`, `TestKeyAncestry`, `TestType`, `TestRandom`, `TestLess`, `TestKeyMarshalJSON`, `TestKey_RootNamespace`) e `features_test.go` (`TestFeatureByName`, `TestFeaturesForDatastore`), além do próprio conformance suite `test/basic_tests.go`+`test/test_util.go`+`test/suite.go` (`dstest.SubtestAll`/`BatchSubtests`, portado em `test/dstest/` como helper de teste reutilizável, aplicado contra `MapDatastore`/`LogDatastore`/`NullDatastore` em `test/{map,log,null}_datastore_test.dart`) -- 22 testes ao todo. `dstest.SubtestCombinations` foi portado mas deliberadamente não é chamado por padrão (produto exaustivo de 1152 sub-queries; o próprio Go só roda isso fora do detector de race pela mesma razão de custo). `TestKeyUnmarshalJSON`'s asserções de string de erro exatas do Go não foram portadas -- `Key.unmarshalJson` lança `FormatException` do Dart em entrada inválida em vez de manter o receiver mutável inalterado (idioma do `encoding/json` do Go sem equivalente limpo em Dart pra um construtor factory); ver comentário no próprio método. **Achado de naming-collision do Dart** (mesmo padrão do `core_routing.getPublicKey` já documentado em `transpiled_libp2p`): `LogDatastore.diskUsage()` (método de instância) precisou de um import prefixado (`as ds show diskUsage`) pra chamar a função livre `diskUsage()` de `datastore.dart` sem ela ser sombreada pelo próprio método. **Ainda não consumido** por `lib/src/core/storage/` do guarda-chuva (abstração própria com backend Hive, não auditada) -- essa integração é trabalho futuro, quando `go-libp2p-kad-dht`/boxo precisarem de um datastore de verdade. |
| `autobatch` |  | não iniciado | Depende de `Batching`, autobatch de escritas -- não usado pelo caminho crítico do kad-dht/boxo até onde mapeado. |
| `context` |  | não iniciado | Datastore com timeout via `context.Context` -- padrão de cancelamento que este port não usa (ver nota da linha `(root)`). |
| `delayed` |  | não iniciado |  |
| `examples` |  | fora do escopo | Exemplos de uso, não biblioteca. |
| `failstore` |  | não iniciado |  |
| `fuzz` |  | fora do escopo | Alvo de fuzzing do Go, não lógica de protocolo. |
| `fuzz/cmd/compare` |  | fora do escopo |  |
| `fuzz/cmd/generate` |  | fora do escopo |  |
| `fuzz/cmd/isprefix` |  | fora do escopo |  |
| `fuzz/cmd/run` |  | fora do escopo |  |
| `keytransform` |  | não iniciado | Decorator de datastore (reescreve chaves) -- usado por `namespace`. |
| `mount` |  | não iniciado |  |
| `namespace` |  | não iniciado | Provável dependência real de `go-libp2p-kad-dht`/boxo (namespacing de chaves da DHT/blockstore) -- revisitar quando começar `go-libp2p-kad-dht`. |
| `query` | `packages/transpiled_datastore/lib/src/query/{query,filter,order,query_impl}.dart` | **portado com paridade comprovada** | `Query`/`Entry`/`Result`→`QueryResult`/`Results`/`Iterator`→`QueryIterator`/`ResultsFromIterator`/`ResultsWithEntries`/`ResultsReplaceQuery`/`Query.String` (`query.go`), `Filter`/`Op`→`FilterOp`/`FilterValueCompare`/`FilterKeyCompare`/`FilterKeyPrefix` (`filter.go`), `Order`/`OrderByFunction`/`OrderByValue(Descending)`/`OrderByKey(Descending)`/`Less`→`queryLess`/`Compare`→`queryCompare`/`Sort`→`querySort` (`order.go`), `NaiveFilter`/`NaiveLimit`/`NaiveOffset`/`NaiveOrder`/`NaiveQueryApply`/`ResultEntriesFrom` (`query_impl.go`). O caminho de construção de `Results` baseado em canal do Go (`results`/`ResultsWithContext`, pra produtores concorrentes) não foi portado -- só o caminho pull-based (`resultsIter`/`Iterator`), suficiente pro isolate único e cooperativo do Dart (mesmo raciocínio já usado pra remover `sync.RWMutex` no `go-libp2p-kbucket`); ver o comentário de cabeçalho de `query.dart`. Testado contra vetores reais de `filter_test.go` (`TestFilterKeyCompare`, `TestFilterKeyPrefix`), `order_test.go` (`TestOrderByKey`), `query_test.go` (`TestNaiveQueryApply`, `TestLimit`, `TestOffset`, `TestResultsFromIterator`+`TestResultsFromIteratorNoClose`, `TestStringer`) -- `TestResultsFromIteratorUsingChan` não portado (exercita só a API de canal do Go que este port não tem). |
| `retrystore` |  | não iniciado |  |
| `scoped` |  | não iniciado |  |
| `scoped/generate` |  | não iniciado |  |
| `sync` |  | não iniciado | `sync.MutexWrap` -- decorator de exclusão mútua; provavelmente desnecessário em Dart (mesmo raciocínio de remoção de `sync.RWMutex` já aplicado no `go-libp2p-kbucket`), mas não confirmar sem checar os call sites reais de `go-libp2p-kad-dht`/boxo quando chegar a vez. |
| `test` | `packages/transpiled_datastore/test/dstest/{basic_tests,test_util}.dart` | **portado com paridade comprovada** | `dstest.SubtestAll`/`BasicSubtests`/`BatchSubtests`/`RunBatchTest`/`RunBatchDeleteTest`/`RunBatchPutAndDeleteTest`/todas as `Subtest*` de `test/basic_tests.go`. É helper de TESTE (não produção), igual ao pacote `dstest` original -- ver nota da linha `(root)`. |
| `trace` |  | não iniciado |  |

### `go-libp2p-kbucket`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_libp2p_kbucket/lib/src/{bucket,table,table_refresh,sorting,util,keyspace,xor_keyspace,peer_metrics,key_prefix_map}.dart` | **portado com paridade comprovada** | `PeerInfo`/`Bucket` (`bucket.go`, `container/list` do Go virou `List<PeerInfo>` puro -- tamanhos de bucket são pequenos, sem necessidade da lista encadeada), `RoutingTable`/`DiversityFilter`/exceções (`table.go`, `sync.RWMutex` removido -- isolate único do Dart sem `await` nas seções críticas portadas torna desnecessário), `RoutingTableRefresh` (`table_refresh.go`, virou `extension on RoutingTable` -- é o jeito mais próximo do Dart pro padrão Go de "mais um arquivo no mesmo pacote adicionando métodos ao mesmo struct"; exigiu expor `cplRefreshedAt` como getter em vez de campo privado, já que extensions não alcançam membros privados de outro arquivo), `PeerDistanceSorter`/`SortClosestPeers` (`sorting.go`), `Xor`/`CommonPrefixLen`/`ConvertPeerID`/`ConvertKey`/`Closer`/`GenRandPeerIDWithCPL` (`util.go`), `Key`/`KeySpace`/`XORKeySpace` (`keyspace.go`+`xorkeyspace.go`). `core/peerstore.Metrics` (ainda não portado do `go-libp2p`) virou um placeholder mínimo `PeerMetrics` (`latencyEWMA`) em `peer_metrics.dart`, documentado como provisório. **`bucket_prefixmap.go` é um arquivo GERADO** (65536 linhas de lookup table, `//go:generate`) -- em vez de transcrever à mão, o gerador (`generate/main.go`) foi portado como script (`tool/generate_prefix_map.dart`), rodado uma vez, e o resultado commitado, igual ao próprio projeto Go faz. Bug real encontrado e corrigido no port do gerador: a primeira versão hasheava só 6 bytes (cabeçalho do multihash + contador) em vez dos 34 bytes reais do Go (`[idLen]byte{0x12,0x20}` + contador + 28 bytes de padding zero, tudo isso fazendo parte do hash) -- pego comparando a primeira e a última linha da tabela gerada contra os valores reais do `bucket_prefixmap.go` do Go, que batem exatamente após a correção. Segundo bug real encontrado (este durante os próprios testes, não durante o port do gerador): `table_refresh.dart`'s `genRandomKey` usava `~origMask` (complemento de bits de precisão arbitrária do Dart) onde o Go usa `^origMask` num `uint8` (complemento de 8 bits, estoura em 256) -- isso fazia `randMask` sobrepor bits de `origMask`, contaminando com bits aleatórios posições que deveriam vir determinadamente da chave local; corrigido mascarando com `& 0xFF` logo após o `~`. **Deliberadamente não portado**: `peerdiversity/filter.go` (254 linhas, filtro de diversidade por IP/ASN) -- depende de `go-cidranger`+`go-libp2p-asn-util`, nenhum clonado em `go-ipfs-reference/` ainda; `RoutingTable.diversityFilter` fica como hook opcional (`DiversityFilter?`, `null` por padrão), igual à opcionalidade `df != nil` do próprio Go. Testado contra vetores reais de `util_test.go` (`TestCloser`), `table_refresh_test.go` (`TestGenRandPeerID` -- confirma que `genRandPeerId` produz, para cada CPL de 0 a `maxCplForRefresh`, um ID cujo CPL real bate exatamente com o pedido, o teste mais forte de correção pro gerador de prefixos; `TestGenRandomKey`, 100 iterações; `TestRefreshAndGetTrackedCpls`), `bucket_test.go` (`TestBucketMinimum`, `TestUpdateAllWith`), `sorting_test.go` (`TestSortClosestPeersIsSorted`, `TestSortClosestPeersDoesNotMutateInput`), `table_test.go` (`TestNPeersForCpl`) -- 12 testes em `packages/transpiled_libp2p_kbucket/test/`. Ainda não consumido por `lib/src/protocols/dht/kademlia_tree/` (a árvore Kademlia própria, não auditada, continua em uso ali); essa integração é trabalho futuro. |
| `generate` | `packages/transpiled_libp2p_kbucket/tool/generate_prefix_map.dart` | **portado com paridade comprovada** | Ver nota da linha `(root)`. |
| `keyspace` | `packages/transpiled_libp2p_kbucket/lib/src/{keyspace,xor_keyspace}.dart` | **portado com paridade comprovada** | `Key`/`KeySpace`/`XORKeySpace`/`ZeroPrefixLen`/`XOR`. |
| `peerdiversity` |  | fora do escopo | Ver nota da linha `(root)`: depende de `go-cidranger`+`go-libp2p-asn-util`, nenhum clonado ainda. |

### `go-libp2p-record`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_libp2p_record/lib/src/{validator,util,pubkey_validator,record}.dart` | **portado com paridade comprovada** | `Validator`/`NamespacedValidator` (`validator.go`), `SplitKey` (`util.go`), `PublicKeyValidator` (`pubkey.go`), `MakePutRecord`/`pb.Record{key,value,timeReceived}` (`record.go`+`pb/record.proto`, hand-rolled protobuf reaproveitando os helpers de varint de `transpiled_libp2p`). `ErrInvalidRecordType`/`ErrBetterRecord` viraram `InvalidRecordTypeException`/`BetterRecordException`. Testado contra os vetores reais do próprio `validator_test.go` (as 9 `badPaths`, os fluxos RSA/Ed25519 de `TestValidatePublicKey`/`TestValidateEd25519PublicKey`/`TestBadRecords`/`TestBestRecord`) em `test/util_test.dart`/`test/pubkey_validator_test.dart`/`test/record_test.dart` -- as chaves RSA usam seed própria do Dart em vez do RNG determinístico do Go (`random.NewSeededRand`, não replicável), então os bytes não batem com o Go, mas a lógica de validação (aceita/rejeita) é a mesma testada. Ainda não consumido por `lib/src/protocols/dht/dht_handler.dart` -- a validação de valor da DHT lá continua embutida diretamente, sem usar este `Validator`; essa integração é trabalho futuro, separado deste port. |
| `pb` |  | não iniciado |  |

### `go-libp2p-routing-helpers`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_libp2p_routing_helpers/lib/src/{bootstrap,null_router,limited_value_store,compose,multi_error,parallel,tiered,composable}.dart` + `lib/src/routing/` (5 arquivos originais do guarda-chuva, não substituídos ainda) | **em andamento** | Prontos e previamente validados: `Bootstrap`, `NullRouter`, `LimitedValueStore`, `Compose` e helpers de multi-erro. WIP auditado: `Parallel`/`Tiered`, `ComposableParallel`/`ComposableSequential`, configs, `ReadyAbleRouter`, `ComposableRouter` e `ProvideManyRouter`; o batch reutiliza `MultihashInfo` de `transpiled_multihash`, e o fallback produz CIDv1 `raw` como o Go. O fan-out/fan-in usa `Future`/`Stream`; o merge de `QueryEvent` reutiliza `QueryEventRegistration`/`Zone` e agora cobre `SearchValue`/`FindProvidersAsync`. Testes direcionados cobrem deduplicação/limite do `Parallel`, duplicatas intencionais do composable, fechamento de busca produtiva, seletor/valores vazios, timeout total de stream, `DoNotWaitForSearchValue`, fallback de valores vazios, regras de erro e os dois caminhos de `ProvideMany`. `dart analyze`, 32 testes Dart e `go test ./...` passam. **Paridade final ainda não declarada** pelos fixtures Go restantes e pela limitação de cancelamento descrita no aviso do topo. Ainda não consumido por `lib/src/routing/`, que continua implementação original não auditada. |
| `tracing` |  | não iniciado | Wrapper de OpenTelemetry em volta de cada método do `Compose`/`Parallel`/etc -- observabilidade, não lógica de protocolo; não portado de propósito, mesmo padrão de "pular telemetria" já aplicado a outros achados desta sessão (ex.: buffer pooling do `go-buffer-pool` em `core/record`). |
| `tracing` |  | não iniciado |  |
