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
| `(root)` | `packages/dart_ipfs_core/lib/src/multiaddr/{protocol,transcoders,multiaddr}.dart` | portado com paridade comprovada | Reescrito do zero em `dart_ipfs_core` (a dependência existente, `ipfs_libp2p`'s `MultiAddr`, cobria só 15/37 protocolos e tinha **dois bugs reais de código de wire**: `quic-v1` usava o código 460, que é o de `quic` puro em go-multiaddr -- o `P_QUIC_V1` real é 461; e `sni` usava 467 em vez do real 449 -- ambos causariam incompatibilidade de wire silenciosa com peers reais). Tabela completa de 37 protocolos (`Protocols` em `protocol.dart`, códigos/tamanhos copiados literalmente de `protocols.go`) + todos os transcoders (`transcoders.dart`: ip4/ip6/ip6zone/ipcidr/port/dns/onion/onion3/garlic64/garlic32/p2p/unix/certhash/http-path/memory) + `Component`/`Multiaddr` (`multiaddr.dart`: parse/toBytes/fromBytes/encapsulate/decapsulate/valueForProtocol/compare/equal). IPv4/IPv6 parsing é caseiro (não usa `dart:io`'s `InternetAddress`, pra manter `dart_ipfs_core` sem dependência de `dart:io`/web-incompatível) -- inclui formatação IPv6 canônica RFC 5952 com compressão `::` e caso especial `::ffff:a.b.c.d`. 152 testes de paridade em `test/multiaddr_parity_test.dart`, usando as listas `good`/`bad` reais de `multiaddr_test.go` (incluindo os payloads i2p/Tor completos), mais round-trip binário e um teste cruzado provando que um PeerId em base58 e o mesmo PeerId como CID base32 (`libp2p-key`) decodificam pro mesmo valor. CIDs de PeerId em base36 (`k2k4r8oq...`, prefixo `k`) foram inicialmente um gap documentado (`package:multibase` não tinha codec base36) -- fechado no mesmo commit que reescreveu `go-multibase` logo em seguida; os 11 vetores voltaram pra lista `_good` e há um teste cruzado provando que base58/base32/base36 do mesmo PeerId decodificam pro mesmo valor. `FilterAddrs`/`Filters` (filtro allow/deny de endereços) e `Match`/`x/meg` (mini-linguagem de pattern matching sobre protocolos) não portados -- nenhum caller em `dart_ipfs` precisa deles hoje; retomar se/quando o swarm precisar de política de filtragem de endereço. |
| `matest` |  | fora do escopo (helpers de teste do próprio go-multiaddr, não é API de produção) |  |
| `net` |  | não iniciado | Conveniências que integram `Multiaddr` com `net.Conn`/`net.Dial` do Go (`ToNetAddr`, `FromNetAddr`, `Listen`, etc.) -- equivalente Dart seria integração com `dart:io`'s `Socket`/`RawDatagramSocket` no Tier 3 (transporte), não faz sentido portar antes do transporte real existir. |
| `x/meg` |  | não iniciado | Mini-linguagem de pattern matching usada só por `Multiaddr.Match`; ver nota do `(root)` acima -- sem caller no `dart_ipfs` hoje. |

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
| `(root)` | `packages/dart_ipfs_core/lib/src/cid/multibase.dart` | portado com paridade comprovada | Reescrito do zero: `package:multibase`'s `Multibase` enum só cobre 8 das 21 codificações que o próprio go-multibase implementa, e usa um algoritmo de conversão por inteiro-grande (correto pra base36/base58, mas **errado** pra base16/32/64 -- que são esquemas de agrupamento de bits de largura fixa, não conversão numérica -- daí o bug de base32 já documentado aqui antes). `MultibaseUtils.decode`/`.encodeWithName` agora despacham as 21 codificações reais por nome/caractere-prefixo (idêntico ao `Encoding` do Go, que também é literalmente um rune): identity, base2, base16(upper), os 8 variantes de base32 (via `package:base32`, bit-packing correto), base36(upper) e base58btc/flickr (via `package:base_x`'s `BaseXCodec`, mesmo algoritmo do Bitcoin com contagem explícita de bytes líder-zero -- correto pra essa família), os 4 variantes de base64 (via `dart:convert`), e base256emoji (tabela de 256 emojis copiada literalmente do Go, sem aritmética). `base8`/`base10`/`base45` **não implementados -- assim como no próprio go-multibase**, que só declara as constantes mas nunca as implementa (cai em `ErrUnsupportedEncoding`); replicado exatamente (lança `UnsupportedError`), não é uma lacuna real. `encode(mb.Multibase, bytes)` manteve a assinatura estreita (8 valores) que `CID`/outros callers já usam, mas passou a rotear pelas mesmas implementações corretas -- corrigindo de brinde um bug latente (`base32upper` nunca tinha sido corrigido, só `base32` minúsculo). 116 testes de paridade em `test/multibase_parity_test.dart`, usando `encodedSamples` de `multibase_test.go` (21 codificações de "Decentralize everything!!!") + os fixtures CSV oficiais do spec (`spec/tests/*.csv` -- submódulo git que o clone raso não trouxe, clonado à parte nesta sessão) cobrindo zero/um/dois bytes líder-zero e decode case-insensitive. Isso também fechou o gap de base36 documentado na linha do `go-multiaddr` acima -- os 11 vetores que usavam PeerId em base36 voltaram pra lista `_good` de `multiaddr_parity_test.dart` e passam. |
| `multibase-conv` |  | fora do escopo (CLI wrapper do go-multibase, não é API de produção) |  |

### `go-multicodec`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/dart_ipfs_core/lib/src/cid/multicodec.dart` | portado com paridade comprovada | Tabela completa de 603 entradas, extraída **mecanicamente** de `code_table.go` (regex sobre `Name Code = 0xNN // nome-canonico`, não transcrita à mão) -- a tabela anterior tinha só ~30 entradas escolhidas a dedo e havia **divergido da real**: inventava `ipld-ns`/`ipfs-ns`/`ipns-ns` nos códigos 0x300/0x301/0x302, quando a tabela real do go-multicodec usa esses códigos pra `ipns-record`/`libp2p-peer-record`/`libp2p-relay-rsvp`; e `dnslink` estava no código errado (0x33, que na verdade é `multibase` -- o real `dnslink` é 0xe8). Corrigido também o mesmo par de nomes errados em `lib/src/utils/encoding.dart` (utilitário duplicado da árvore do `dart_ipfs` que ainda não foi absorvido pelo `dart_ipfs_core` -- fora do escopo deste port consolidar os dois, mas o bug encontrado foi corrigido nos dois lugares). 5 testes de paridade em `test/multicodec_parity_test.dart` (contagem exata de 603, round-trip código↔nome, spot-check espalhado pelo arquivo inteiro, e um teste específico provando que a faixa 0x300 bate com a tabela real). |

### `go-multiaddr-dns`

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` | `packages/dart_ipfs_core/lib/src/multiaddr/dns_resolver.dart` (orquestração) + `lib/src/transport/dns/` no `dart_ipfs` (I/O real) | **portado com paridade comprovada, incluindo I/O real e integração no bootstrap** | **Este é o pacote que disparou toda a transpilação** (nó ficava em 0 peers por causa da resolução de `/dnsaddr/`) -- agora fechado ponta a ponta. Orquestração (`dart_ipfs_core`): a interface `BasicResolver` (`lookupIPAddr`/`lookupTXT`), `MockResolver` (mock.go), a classe `Resolver` inteira (resolve.go: `resolve()`, resolvers por domínio/TLD com match left-to-right, o algoritmo de sufixo do dnsaddr com contagem de componentes), `dnsMatches` (util.go `Matches`), `isFqdn`/`fqdn` (bug de paridade de bits encontrado e corrigido contra `TestIsFqdn`/`TestFqdn`). Precisou `splitFunc`/`splitFirst`/`forEach` no `Multiaddr`. 30 testes de paridade em `test/dns_resolver_parity_test.dart` via `MockResolver`, sem rede real. **I/O real (segunda parte desta sessão, "destrinchar o stdlib que ficou faltando"):** checado pub.dev primeiro pela metodologia -- o único pacote pure-Dart de DNS clássico (`dns`, terrier989/dint.dev) tem 30/160 pontos, 6 likes, 33 downloads (sinal forte de abandono, não é algo pra depender em código de produção); os demais achados (`dns_client`, `super_dns_client`, `dnsolve`) são DNS-over-HTTPS ou wrappers FFI do resolver nativo, que não replicam a semântica de DNS clássico que o kubo/go-libp2p realmente usam. Confirmado: sem alternativa viável, escrito do zero um cliente RFC 1035 mínimo em `lib/src/transport/dns/`: `dns_message.dart` (encode de query + decode de resposta -- header, nomes com ponteiro de compressão RFC 1035 §4.1.4 com guarda contra loop, registros A/AAAA/TXT, concatenação de character-strings de TXT igual ao `net.LookupTXT` do Go), `udp_dns_client.dart` (`RawDatagramSocket`, timeout + retry + fallback entre resolvers, já que `dart:io` não expõe descoberta do resolver do SO -- usa 1.1.1.1/8.8.8.8 por padrão, configurável), `system_resolver.dart` (`SystemResolver`: `lookupIPAddr` via `InternetAddress.lookup` do próprio `dart:io`, que já cobria A/AAAA sem lacuna nenhuma; `lookupTXT` via o cliente UDP novo). Testado com bytes reais capturados de uma troca UDP ao vivo com 1.1.1.1 (`test/transport/dns/dns_message_test.dart`, 9 testes determinísticos, incluindo o caso real de `_dnsaddr.bootstrap.libp2p.io` com nomes comprimidos) e cross-verificado independentemente via `Resolve-DnsName -Type TXT` do PowerShell. Mais 5 testes ao vivo (`@Tags(['network'])`, pulados por padrão -- ver `dart_test.yaml`, rodar com `dart test --preset network`) provando resolução real: `Resolver`+`SystemResolver` juntos resolvem `/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu...` (o endereço de bootstrap real do `network_config.dart`) até um endereço concreto, recursivamente (o TXT de `bootstrap.libp2p.io` aponta pra aliases por nó tipo `sv15.bootstrap.libp2p.io`, que por sua vez precisam de outra resolução -- comportamento esperado do go-multiaddr-dns, não bug). **Integrado no fluxo real de bootstrap:** `bootstrap_handler.dart` resolvia endereços `/dnsaddr/...` literalmente antes (nunca funcionava -- essa era a causa raiz dos 0 peers), agora resolve via `Resolver` antes de discar, com fallback condicional pra web (`dns_bootstrap_resolver.dart` com export condicional `if (dart.library.html)`, já que browsers não expõem socket bruto -- mesmo padrão já usado por `network_handler.dart`) e resolver injetável no construtor pra testes determinísticos offline (`test/core/ipfs_node/bootstrap_utils_test.dart`, novo grupo `BootstrapHandler DNS resolution`, 3 testes com `MockResolver`, provando que o endereço resolvido -- não o `/dnsaddr/...` original -- é o que chega em `NetworkHandler.connectToPeer`). |
| `madns` |  | fora do escopo (`cmd/madns`, CLI wrapper do go-multiaddr-dns, não é API de produção) |  |

### `go-libp2p`

**Ordem de prioridade invertida** (ver plano, `lexical-fluttering-acorn.md`): testei um nó real conectando contra `bootstrap.libp2p.io` e descobri que o handshake Noise da dependência `ipfs_libp2p` (usada hoje pra host/transporte/segurança) é hardcoded pra Ed25519 (`p2p/security/noise/noise_protocol.dart`: `if (pubKey.type != crypto_pb.KeyType.Ed25519) throw ...`) -- rejeita qualquer peer real que use RSA, então portar `core/crypto`/`core/peer` sozinho (Tier 2 original) não destrava conexão real (a checagem está na camada de segurança). Por isso `core/sec`/`p2p/security/{noise,tls}` (Tier 3 original) viraram prioridade antes do resto de `core/crypto`/`core/peer`/`core/record`. Também achado no mesmo teste: discagem QUIC-v1 de saída falha com "No transport found for address" -- gap de registro de transporte, investigar junto.

Um bug concreto de `core/peer` já foi corrigido fora de ordem (motivado pelo mesmo teste): `PeerId.fromPublicKey` em `lib/src/core/types/peer_id.dart` calculava `sha256(chave pública crua)` diretamente, em vez de multihash do `PublicKey{Type, Data}` protobuf-marshaled (`identity` multihash quando o marshaled cabe em ≤42 bytes -- sempre o caso pra Ed25519, 36 bytes -- `sha2-256` caso contrário, exatamente `IDFromPublicKey` de `core/peer/peer.go`). Também rejeitava qualquer tipo que não fosse `'Ed25519'`; agora aceita `RSA`/`Secp256k1`/`ECDSA` também (só a derivação do PeerId, não assinatura/verificação -- isso ainda é `core/crypto` de verdade). Um protobuf mínimo de 2 campos (`PublicKey{Type, Data}`, crypto.proto) foi escrito à mão em `peer_id.dart` -- não vale a pena codegen completo pra isso.

Corrigir esse bug expôs um segundo bug real, preexistente: `_encodeBase36`/`_decodeBase36` (também em `peer_id.dart`) convertiam os bytes pra um único `BigInt`, descartando bytes zero à esquerda -- mesma classe de bug já documentada e corrigida em `multibase.dart` no Tier 1 (base32 do `package:multibase`). Como o identity-multihash de uma chave Ed25519 sempre começa com o byte `0x00` (o código do multihash `identity`), esse bug ficava latente até a derivação de PeerId ficar correta. Corrigido substituindo `_encodeBase36`/`_decodeBase36` inteiros pelas chamadas equivalentes em `dart_ipfs_core`'s `MultibaseUtils` (já testado, 116 casos de paridade no Tier 1) -- não faz sentido manter dois codecs base36 no projeto. Testes atualizados: `test/core/types/peer_id_test.dart` (vetores exatos calculados à mão pro caso Ed25519) e `test/property/dht_property_test.dart` (o teste que antes documentava a limitação de bytes-zero-à-esquerda como conhecida agora prova que foi corrigida, com 500 iterações aleatórias sem pular nenhuma).

| Pacote Go | Destino em `lib/src/` | Status | Notas |
|---|---|---|---|
| `(root)` |  | não iniciado |  |
| `config` |  | não iniciado |  |
| `core` |  | não iniciado |  |
| `core/connmgr` |  | não iniciado |  |
| `core/control` |  | não iniciado |  |
| `core/crypto` | `packages/dart_ipfs_core/lib/src/crypto/key_types.dart` (`Key`/`PrivKey`/`PubKey`/`KeyType`) + `rsa_key.dart`, `secp256k1_key.dart`, `ecdsa_key.dart` | **portado com paridade comprovada** (RSA, Secp256k1, ECDSA todos com vetor real Go) | **RSA**: `MinRsaKeyBits=2048`, PKCS1 DER privado/PKIX DER público via ASN.1 do `package:pointycastle`, sign/verify SHA-256+PKCS1v1.5 via `pc.RSASigner`. Validado contra `crypto/rsa`+`crypto/x509` do Go (`go-ipfs-reference/noise_vectors/rsa_vectors.go`): DER round-trip exato, assinatura Dart bate byte a byte com a do Go (PKCS1v1.5 é determinístico) -- `test/rsa_key_parity_test.dart`. **Secp256k1**: raw = escalar de 32 bytes big-endian / ponto comprimido SEC1 de 33 bytes (mesmo formato de `github.com/decred/dcrd/dcrec/secp256k1/v4`, a lib que `core/crypto/secp256k1.go` encapsula); assinatura DER com nonce determinístico RFC6979 (SHA-256/HMAC) via `pc.ECDSASigner` em modo `DET-ECDSA`, canonicalizada pra S-baixo (`ECSignature.normalize`) igual ao `Signature.Serialize()` do dcrd. Validado contra `github.com/decred/dcrd/dcrec/secp256k1/v4/ecdsa` (`go-ipfs-reference/secp256k1_vectors/main.go`): **a assinatura RFC6979 do Dart bate byte a byte com a do Go** (achado notável -- confirma que a variante de nonce RFC6979 do dcrd, que pula a redução `bits2octets` por já operar sobre hash de 256 bits ~ ordem da curva, coincide na prática com a implementação padrão do pointycastle) -- `test/secp256k1_key_parity_test.dart`. **ECDSA**: hardcoded pra NIST P-256 igual ao Go (`elliptic.P256()`); raw privado = SEC1 `ECPrivateKey` (RFC 5915, `x509.MarshalECPrivateKey` -- SEQUENCE com version/OCTET STRING d/[0] EXPLICIT OID da curva/[1] EXPLICIT BIT STRING do ponto, os dois campos opcionais do RFC 5915 sempre presentes por serem os que o Go sempre emite); raw público = PKIX `SubjectPublicKeyInfo` com AlgorithmIdentifier `{id-ecPublicKey, namedCurve OID}` (não NULL como no RSA) envolvendo o ponto não-comprimido. `ecdsa.Sign` do Go usa nonce aleatorizado (não RFC6979), então a paridade aqui é provada por verificação cruzada, não assinatura idêntica: Dart aceita uma assinatura real do Go, e as codificações DER/SEC1 batem byte a byte. Validado contra `crypto/ecdsa`+`crypto/x509` do Go (`go-ipfs-reference/ecdsa_vectors/main.go`) -- `test/ecdsa_key_parity_test.dart`. Em todos os três: geração de chave via `pc.*KeyGenerator`+`FortunaRandom`, seed real via `Random.secure()` do Dart. **Ed25519** (`ed25519_key.dart`): não é um port novo -- envolve o `Ed25519Signer` já existente (usado por IPNS) na mesma abstração `PrivKey`/`PubKey`, já que ele usava `package:cryptography` diretamente sem conformar à interface. Raw privado = 64 bytes `seed‖publicKey` (formato de `ed25519.PrivateKey` do Go); como `package:cryptography` só expõe a seed de 32 bytes de forma síncrona, a concatenação é feita uma vez, de forma assíncrona, na fábrica (`generateEd25519KeyPair`/`unmarshalEd25519PrivateKey`), mantendo `raw()` síncrono como nos outros três tipos. Validado contra `crypto/ed25519` do Go (`go-ipfs-reference/ed25519_vectors/main.go`): assinatura EdDSA determinística bate byte a byte -- `test/ed25519_key_parity_test.dart`. **`key_codec.dart`** (novo, sem arquivo Go correspondente 1:1 -- é a contraparte de `MarshalPublicKey`/`UnmarshalPublicKey`/`MarshalPrivateKey`/`UnmarshalPrivateKey` de `core/crypto/key.go`): despacha por `KeyType` entre os quatro tipos concretos, usado por qualquer código que recebe uma chave de identidade de tipo desconhecido (ex.: o payload do handshake Noise) -- `test/key_codec_test.dart`. Com isso, os quatro tipos de chave do protobuf `crypto.pb.KeyType` (RSA/Ed25519/Secp256k1/ECDSA) têm cobertura uniforme. O gap real que impede conexão com peers não-Ed25519 continua sendo o handshake Noise (`p2p/security/noise`, hardcoded pra Ed25519 -- ver nota acima), não este pacote; os tipos de chave aqui são pré-requisito pro payload de assinatura do Noise, não a correção em si. |
| `core/crypto/pb` | `packages/dart_ipfs_core/lib/src/crypto/key_types.dart` (`marshalKeyProto`/`unmarshalKeyProto`, protobuf mínimo de 2 campos hand-rolled: `PublicKey`/`PrivateKey{Type,Data}`) + duplicata equivalente em `lib/src/core/types/peer_id.dart` (`_marshalPublicKeyProto`, só encode) | portado sem teste de paridade formal (coberto indiretamente pelos testes de `rsa_key_parity_test.dart` e `peer_id_test.dart`) | `key_types.dart` agora tem encode E decode general-purpose (campos em qualquer ordem, valida `KeyType` desconhecido/mensagem truncada); `peer_id.dart` ainda tem sua própria cópia só-encode mais antiga -- oportunidade de limpeza: fazer `peer_id.dart` reusar `marshalKeyProto`/`KeyType` de `dart_ipfs_core` em vez de manter duas implementações do mesmo formato. Ainda não geramos código de um `.proto` real -- é só os 2 campos hand-rolled; revisitar se vale migrar pra protobuf codegen de verdade (o projeto já usa `protoc`-gerado em outros lugares, ver `lib/src/proto/`). |
| `core/discovery` |  | não iniciado |  |
| `core/event` |  | não iniciado |  |
| `core/host` |  | não iniciado |  |
| `core/internal/catch` |  | não iniciado |  |
| `core/metrics` |  | não iniciado |  |
| `core/network` |  | não iniciado |  |
| `core/network/mocks` |  | não iniciado |  |
| `core/peer` | `lib/src/core/types/peer_id.dart` (`PeerId.fromPublicKey` apenas) | em andamento | `IDFromPublicKey` corrigido (ver nota acima) -- resto do pacote (interface `ID`, `AddrInfo`, `Set`, etc.) não iniciado. |
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
| `p2p/security/noise` | `lib/src/transport/noise/noise_state.dart` (núcleo do protocolo Noise) + `noise_handshake_payload.dart` (payload assinado) -- `session.go`/`transport.go` equivalentes ainda não portados, e nada disso está ligado ao transporte real ainda | em andamento -- núcleo + payload com paridade comprovada, wiring no transporte real ainda não | Portado: `CipherState`/`SymmetricState`/`HandshakeState` completos pro cipher suite fixo que o go-libp2p sempre usa (`DH25519, CipherChaChaPoly, HashSHA256`, padrão `XX`). Usa `package:cryptography` (já dependência) pra X25519/ChaCha20-Poly1305/SHA256; o HKDF de 2-3 saídas do próprio spec do Noise (seção 4.3, distinto do RFC 5869) foi escrito à mão sobre HMAC-SHA256. **Validado byte a byte contra um vetor real** gerado por `flynn/noise` (a lib Go que `p2p/security/noise` realmente usa, via `vectorgen` da própria lib) -- 3 mensagens de handshake + 2 de transporte pós-handshake batem exato, mais um teste de auto-interop -- `test/transport/noise/noise_state_test.dart`. **Payload assinado** (`generateHandshakePayload`/`handleRemoteHandshakePayload` de `handshake.go`, `noise_handshake_payload.dart`): protobuf mínimo de 2 campos (`identity_key`, `identity_sig` -- campo 4 `extensions` nunca emitido e ignorado na leitura, já que é opcional e o handshake funciona sem ele), assinatura via `"noise-libp2p-static-key:" + chave estática Noise` assinada com a chave de identidade libp2p, despachada por `key_codec.dart` do `dart_ipfs_core` (então já funciona pros 4 tipos de chave: RSA/Ed25519/Secp256k1/ECDSA, não só Ed25519), e derivação do `PeerId` remoto via `PeerId.fromPublicKey`. **Validado contra um payload real construído com o `core/crypto`+`core/peer`+`p2p/security/noise/pb` de verdade do go-libp2p** (protobuf gerado por `protoc`, não hand-rolled -- `go-ipfs-reference/go-libp2p/dartipfs_vectors/main.go`): o decoder hand-rolled do Dart lê o wire format real corretamente, a verificação de assinatura aceita a assinatura real do Go, e o `PeerId` derivado bate com o que o `peer.IDFromPublicKey` real do Go calculou -- `test/transport/noise/noise_handshake_payload_test.dart`. Achei e corrigi dois erros reais nas MINHAS PRÓPRIAS asserções de teste do núcleo Noise ao comparar contra o vetor (não no protocolo em si): (1) assumi que as mensagens de transporte pós-handshake do vetor alternavam entre as partes -- na verdade o `vectorgen` usa `cs0`/`cs1` do MESMO lado (quem escreveu a última mensagem de handshake) pras duas, sem alternar; (2) no teste de auto-interop, emparelhei errado enc/dec dos dois lados (`aSplit.$1` com `bSplit.$2` em vez de `bSplit.$1` -- os dois lados derivam os MESMOS dois `CipherState`s do mesmo chaining key final, e é o papel initiator/responder que decide qual é enc e qual é dec, não quem calculou o `Split()`). **Falta pro handshake libp2p completo**: `session.go`/`transport.go` equivalentes (framing de 2 bytes de comprimento, leitura/escrita de stream pós-handshake), e -- a peça que falta pra realmente corrigir o bug original -- a integração de fato substituindo o uso do `ipfs_libp2p` (dependência externa do pub.dev, não editável neste repo) no transporte real, o que é uma decisão arquitetural maior (trocar a pilha de transporte/segurança em produção) que vale confirmar com o usuário antes de fazer, em vez de simplesmente decidir sozinho. |
| `p2p/security/noise/pb` | `lib/src/transport/noise/noise_handshake_payload.dart` (protobuf mínimo de 2 campos hand-rolled: `identity_key`, `identity_sig` -- campo `extensions` (`NoiseExtensions{webtransport_certhashes, stream_muxers}`) não implementado, não usado pelo handshake básico) | portado sem teste de paridade formal isolado (coberto indiretamente por `noise_handshake_payload_test.dart`, que valida o wire format completo contra protobuf real gerado por `protoc`) |  |
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
