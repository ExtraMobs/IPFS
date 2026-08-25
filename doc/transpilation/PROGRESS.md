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

- `Status` possíveis: `não iniciado` | `em andamento` | `portado sem teste de paridade` | `portado com paridade comprovada` | `implementação original não auditada` | `fora do escopo (daemon-CLI só, ver plano)`.
- `implementação original não auditada` (valor novo, adicionado em 2026-08): existe código Dart funcional cobrindo (parte d)o que este pacote Go faz, mas foi escrito do zero, nunca comparado função-a-função com o Go real, e não tem teste de paridade contra vetores reais. **Não confundir com `não iniciado`** (nenhum código relevante existe) — a distinção importa porque a suite de testes já achou 2 bugs reais em código que "funcionava" antes de ser auditado (Noise só-Ed25519, RSA com DER errado). Ver a seção "Estado em aberto" abaixo pra o levantamento completo de onde essa cobertura existe.
- `Destino em lib/src/` fica em branco até o pacote ser realmente mapeado — preencher ao decidir onde o port mora no `dart_ipfs`.
- Ordem das tabelas = ordem de prioridade do plano (Tier 1 primeiro: multiformats puros).

## Estado em aberto (2026-08-25)

Isto é o que uma sessão futura precisa saber pra continuar de onde paramos — não é redundante com as tabelas abaixo, é o contexto que não cabe numa célula de tabela.

- **Levantamento recursivo de dependências completo**, cruzando `kubo/go.mod` + os 15 módulos clonados + o estado real deste repo (não só o que esta tabela diz): https://claude.ai/code/artifact/6b94efde-3f58-4ad6-98bd-c18d8de19330 — inclui a ordem de construção recomendada (abaixo) e, importante, a cobertura original já existente em `lib/src/` pra cada um dos 8 módulos sem port literal (DHT, PubSub, IPLD codecs, Bitswap, UnixFS, Gateway/CAR, storage, routing helpers).
- **Ordem de construção recomendada**, derivada dos imports Go reais (não suposição): ~~(1) `core/record`+`core/peer/pb` (fecha `PeerRecord`, autocontido)~~ **feito em 2026-08-25** → (2) três frentes paralelas sem dependência cruzada: ~~`go-libp2p-record`~~ **feito em 2026-08-25** →`routing-helpers` **(em andamento, ver nota abaixo)**, `go-libp2p-kbucket` **(próximo passo)**, `go-datastore`, `go-ipld-prime`, `go-libp2p-pubsub` → (3) `boxo` núcleo (bitswap/blockstore/dag/files/mfs/gateway — não depende da DHT) → (4) `go-libp2p-kad-dht` (ponto de convergência: kbucket+record+routing-helpers+boxo+datastore — é o ÚLTIMO a ficar pronto, não o primeiro) → (5) `boxo` namesys/routing (só cantos que realmente usam a DHT). Cortando tudo isso: o resto do `go-libp2p` em si (Host/Swarm/Transportes/NAT/Identify) ainda vem inteiro do `ipfs_libp2p` de terceiro — é o maior corpo de trabalho restante em linhas de código de todo o grafo, e nenhum item da lista acima o reduz.
- **`core/routing` + parte de `go-libp2p-routing-helpers` portados (2026-08-25)**: `core/routing` (pré-requisito não detectado na auditoria original -- ver a linha da tabela do `go-libp2p` acima) e as peças mecânicas/autocontidas de `go-libp2p-routing-helpers` (`Bootstrap`, `NullRouter`, `LimitedValueStore`, `Compose`) estão prontas. **`Parallel`/`Tiered`/`Sequential` continuam pendentes de propósito** -- exigem decidir como representar a propagação de `context.Value` do Go (o sistema de `QueryEvent`) em Dart antes de portar, não é trabalho mecânico. Ver a nota completa na linha `(root)` de `go-libp2p-routing-helpers` abaixo antes de retomar.
- **`go-libp2p-record` portado (2026-08-25)**: novo pacote `packages/transpiled_libp2p_record/` (ver a linha da tabela abaixo pra detalhe técnico). Primeiro pacote novo desde a reorganização de módulos que não é `transpiled_libp2p` nem um dos multiformats -- confirma que a convenção de pacote-por-módulo-Go se sustenta pra módulos menores também.
- **`core/record` + `core/peer/pb` portados (2026-08-25)**: `Record`/`Envelope`/`PeerRecord` completos em `packages/transpiled_libp2p/lib/src/core/record/` e `core/peer/peer_record.dart` (ver as linhas das tabelas abaixo pra detalhe técnico). Achado de metodologia relevante pra qualquer port futuro que precise imitar o `init()` do Go: uma variável de nível de biblioteca em Dart (`final bool _x = _setup();`) **não** roda só por importar o arquivo -- inicialização de topo em Dart é preguiçosa (só roda no primeiro acesso a essa variável). O registro automático do `PeerRecord` em `Envelope` teve que ser movido pro construtor (idempotente, com guarda contra recursão), não um "top-level init". Isso já causou um teste falhar nesta sessão antes de ser corrigido -- vale revisar qualquer port futuro que dependa do padrão `init()`/registro automático do Go.
- **Tarefa aberta, ainda não iniciada**: mapear a árvore/funções públicas do guarda-chuva pra espelhar `kubo` de verdade. Ponto de entrada já identificado: `bin/ipfs.dart` (`CommandRunner` → `DaemonCommand`/etc. → `IPFSNode`) é o equivalente do `kubo/cmd/ipfs/main.go` → `core/builder.go` → `core/core.go`. Falta decidir, por etapa (usando a ordem acima), o que em `lib/src/` é reaproveitável como está (cola de integração genuína, ex. `core/ipfs_node/`, `services/`) vs. o que precisa ser substituído por port real conforme cada módulo da ordem acima for feito.
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
| `core/routing` | `packages/transpiled_libp2p/lib/src/core/routing/{routing,options}.dart` | **portado com paridade comprovada** | Achado durante o port de `go-libp2p-routing-helpers`: esse módulo depende diretamente das interfaces de `core/routing` do próprio go-libp2p (`Routing`/`ValueStore`/`PeerRouting`/`ContentRouting`/`Option`), que a auditoria de dependências original (ver "Estado em aberto") não tinha detectado como pré-requisito -- não é um módulo Go separado, mas precisou ser portado antes de continuar. `routing.go` completo: `ContentProviding`/`ContentDiscovery`/`ContentRouting`/`PeerRouting`/`ValueStore`/`Routing`/`PubKeyFetcher`, `KeyForPublicKey`, `GetPublicKey` (usa `PeerId.extractPublicKey`/`NoPublicKeyException` já portados). `options.go` completo: `Options`→`RoutingOptions`, `Option`→`RoutingOption` (função void em vez de retornar erro, convenção de exceção já usada no resto do pacote), `Apply`/`ToOption`/`Expired`/`Offline`. `ErrNotFound`/`ErrNotSupported` viraram `RoutingNotFoundException`/`RoutingNotSupportedException`. Achado de Dart real durante o port: um parâmetro `store` tipado `ValueStore` não promovia pra `PubKeyFetcher` dentro de um `if (store is PubKeyFetcher)` (erro `undefined_method` mesmo com o tipo certo) -- contornado com cast explícito (`store as PubKeyFetcher`) em vez de depender de promoção implícita; causa raiz não totalmente investigada, mas o cast explícito é correto independente da causa. Testado em `test/routing_test.dart` (`keyForPublicKey`, `getPublicKey` nos três caminhos: chave embutida via identity-multihash, `PubKeyFetcher` otimizado, fallback `GetValue` puro). |
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

**Nota de cobertura (2026-08-25)**: é o módulo com mais implementação original já existente de toda esta lista, mas espalhada e não mapeada linha a linha contra os 114 pacotes reais do boxo -- por isso as linhas abaixo continuam em branco em vez de marcadas uma a uma. O que já existe e funciona: `lib/src/protocols/bitswap/` (7 arquivos, 1974 linhas, ~ `bitswap`+`bitswap/client`+`bitswap/server`+`bitswap/message`), `lib/src/core/unixfs/` (8, 1181, ~ pacote `unixfs` do próprio boxo -- que na verdade vive em `go-unixfsnode`, não clonado), `lib/src/services/gateway/` (23 arquivos, ~ `gateway`), `lib/src/core/data_structures/car.dart` (835 linhas, ~ `car`/`ipld/car`, mas o formato real vem do módulo separado `go-car/v2`, também não clonado), `lib/src/core/mfs/` (~ `mfs`), `lib/src/protocols/ipns/` (~ parte de `ipns`/`namesys`). Nenhum foi comparado função-a-função com o boxo real ainda -- status real de todos: `implementação original não auditada`, não `não iniciado`.

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `autoconf` |  | não iniciado |  |
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
| `(root)` |  | não iniciado | Modelo de dados/travessia genérico do IPLD real (`Node`, `NodeBuilder`, `Path`, seletores) -- **não tem equivalente algum** no que já existe em `lib/src/core/ipld/` (ver notas de `codec/*` abaixo); a camada Dart só cobre encode/decode dos formatos, não o modelo de dados/travessia. |
| `adl` |  | não iniciado |  |
| `adl/rot13adl` |  | não iniciado |  |
| `codec` |  | não iniciado |  |
| `codec/cbor` |  | não iniciado |  |
| `codec/dagcbor` | `lib/src/core/ipld/codecs/standard_codecs.dart` (`DagCborCodec`) | implementação original não auditada | Codec funcional já em uso, nunca comparado byte a byte com este pacote. |
| `codec/dagjson` | `lib/src/core/ipld/codecs/standard_codecs.dart` (`DagJsonCodec`) | implementação original não auditada | Idem `codec/dagcbor`. |
| `codec/json` |  | não iniciado |  |
| `codec/raw` | `lib/src/core/ipld/codecs/standard_codecs.dart` (`RawCodec`) | implementação original não auditada | Idem `codec/dagcbor`. `DagPbCodec` (também em `standard_codecs.dart`) não tem equivalente aqui -- DAG-PB é um módulo Go separado, `go-codec-dagpb`, não clonado em `go-ipfs-reference/` ainda. |
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
| `(root)` | `lib/src/protocols/pubsub/` (14 arquivos, 2557 linhas, incl. `gossipsub/`) | implementação original não auditada | GossipSub funcional já em uso (`gossipsub_handler.dart`, `pubsub_client.dart`), escrito do zero. Estruturalmente independente da cadeia DHT/boxo -- pode ser auditado/re-portado a qualquer momento, sem esperar por outro módulo. |
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
| `(root)` | `lib/src/core/storage/` (`datastore.dart`, `hive_datastore.dart`) | implementação original não auditada | Abstração de storage própria com backend Hive, já em uso. Sem dependência estrutural de outro módulo desta lista -- decisão real de paridade-vs-reuso quando chegar a vez dele, não bloqueio duro pra mais nada. |
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
| `(root)` | `lib/src/protocols/dht/kademlia_tree/` (12 arquivos) + `xor_distance_metric.dart`, `red_black_tree.dart`, `kademlia_routing_table.dart` | implementação original não auditada | Árvore Kademlia por distância XOR funcional já em uso, escrita do zero. Falta a filtragem de diversidade por ASN/faixa de IP que o `peerdiversity` real tem. Depende de `go-cidranger`+`go-libp2p-asn-util`, nenhum dos dois clonado em `go-ipfs-reference/` ainda. |
| `generate` |  | não iniciado |  |
| `keyspace` |  | não iniciado |  |
| `peerdiversity` |  | não iniciado |  |

### `go-libp2p-record`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_libp2p_record/lib/src/{validator,util,pubkey_validator,record}.dart` | **portado com paridade comprovada** | `Validator`/`NamespacedValidator` (`validator.go`), `SplitKey` (`util.go`), `PublicKeyValidator` (`pubkey.go`), `MakePutRecord`/`pb.Record{key,value,timeReceived}` (`record.go`+`pb/record.proto`, hand-rolled protobuf reaproveitando os helpers de varint de `transpiled_libp2p`). `ErrInvalidRecordType`/`ErrBetterRecord` viraram `InvalidRecordTypeException`/`BetterRecordException`. Testado contra os vetores reais do próprio `validator_test.go` (as 9 `badPaths`, os fluxos RSA/Ed25519 de `TestValidatePublicKey`/`TestValidateEd25519PublicKey`/`TestBadRecords`/`TestBestRecord`) em `test/util_test.dart`/`test/pubkey_validator_test.dart`/`test/record_test.dart` -- as chaves RSA usam seed própria do Dart em vez do RNG determinístico do Go (`random.NewSeededRand`, não replicável), então os bytes não batem com o Go, mas a lógica de validação (aceita/rejeita) é a mesma testada. Ainda não consumido por `lib/src/protocols/dht/dht_handler.dart` -- a validação de valor da DHT lá continua embutida diretamente, sem usar este `Validator`; essa integração é trabalho futuro, separado deste port. |
| `pb` |  | não iniciado |  |

### `go-libp2p-routing-helpers`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/transpiled_libp2p_routing_helpers/lib/src/{bootstrap,null_router,limited_value_store,compose,multi_error}.dart` (parcial) + `lib/src/routing/` (5 arquivos originais do guarda-chuva, não substituídos ainda) | **em andamento** | Portado: `Bootstrap` (`bootstrap.go`), `Null`→`NullRouter` (`null.go`, renomeado porque `Null` colide com o tipo `Null` nativo do Dart), `LimitedValueStore` (`limited.go`), `Compose` (`composed.go`), e um `MultiError`/`combineErrors`/`appendError` própios equivalentes a `go.uber.org/multierr` (não vale a pena um pacote à parte pra duas funções). **Deliberadamente não portado ainda**: `Parallel`/`Tiered`/`Sequential` e seus builders `CompParallel`/`CompSequential` (`parallel.go`/`tiered.go`/`compparallel.go`/`compsequential.go`, ~1500 linhas) -- todos dependem do sistema de `QueryEvent` do `core/routing` (`core/routing/query.go`, propagação de evento via valor de `context.Context`, sem equivalente direto em Dart) e usam fan-out/fan-in via goroutine+channel+`select` (incluindo um caminho via `reflect.Select` pra >8 canais) que precisa ser redesenhado com `Stream`/`Future.wait` do Dart, não traduzido mecanicamente -- isso é uma decisão de design real, não uma lacuna esquecida. Retomar isso exige primeiro decidir como representar a propagação de `context.Value` do Go em Dart (candidatos: `Zone` do Dart, que tem semântica parecida, ou passagem explícita de parâmetro). Achado de Dart real durante o port: um `ValueStore` não promovia pra `Bootstrap` dentro de `if (store is Bootstrap)` (mesmo quirk de `core/routing`, ver nota lá) -- contornado com cast explícito. Testado contra os vetores reais de `null_test.go`/`limited_test.go` (`TestNull`, `TestLimitedValueStore`) em `test/null_router_test.dart`/`test/limited_value_store_test.dart`; `Compose`/`MultiError` testados sem vetor Go direto (comportamento óbvio: componente ausente = `NullRouter`). Ainda não consumido por `lib/src/routing/`, que continua com a implementação própria não auditada. |
| `tracing` |  | não iniciado | Wrapper de OpenTelemetry em volta de cada método do `Compose`/`Parallel`/etc -- observabilidade, não lógica de protocolo; não portado de propósito, mesmo padrão de "pular telemetria" já aplicado a outros achados desta sessão (ex.: buffer pooling do `go-buffer-pool` em `core/record`). |
| `tracing` |  | não iniciado |  |
