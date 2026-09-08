# Escopo do projeto

O objetivo deste projeto é portar para Dart apenas bibliotecas reutilizáveis
necessárias para executar um nó IPFS embutido em aplicações Dart ou Flutter.

Kubo, Boxo e go-libp2p são referências de comportamento, não superfícies de
produto que devam ser reproduzidas integralmente.

## Objetivo prioritário do projeto

Até ser concluído e marcado como tal em `doc/transpilation/PROGRESS.md`, o
primeiro objetivo é comprovar o download P2P de um bloco por CID interoperando
com Kubo:

`Kubo conhecido → TCP/Noise → /ipfs/bitswap/1.2.0 → WANT_BLOCK → bloco validado pelo CID → blockstore`.

Depois da prova com provider conhecido, estenda o mesmo fluxo para:

`CID → DHT.findProviders → AddrInfo → conectar provider → Bitswap → validar → blockstore`.

Todo agente que atuar na transpilação deve seguir a ordem e os critérios da
checklist "Objetivo 1 — primeiro download P2P por CID" no topo de
`doc/transpilation/PROGRESS.md`. Trabalho que não destrava nem valida essa
checklist fica atrás dela, salvo correção necessária para manter a suíte verde
ou instrução explícita do usuário. Gateway HTTP(S) não conta como download P2P
e só entra no escopo quando o usuário o pedir explicitamente.

## Fora do escopo

Ignore qualquer pacote, arquivo ou teste cuja única finalidade seja CLI,
incluindo:

- `kubo/cmd/**`;
- `kubo/commands/**`;
- `kubo/core/commands/**`;
- `kubo/test/cli/**`;
- parsing de comandos e flags;
- prompts, help, completion e formatação de terminal;
- exit codes, PID files e gerenciamento de processo exclusivo da CLI.

Esses itens não devem ser portados, auditados nem contabilizados como lacunas.

O `bin/ipfs.dart` existente não é alvo de paridade com a CLI do Kubo. Ele pode
permanecer como ferramenta auxiliar, mas não deve orientar a arquitetura ou o
escopo da transpilação.

Código utilizado tanto pela CLI quanto por APIs programáticas continua no
escopo. Ciclo de vida `create`/`start`/`stop`, configuração, rede,
armazenamento, protocolos, gateway e RPC reutilizáveis são componentes de
biblioteca.

Antes de trabalhar na transpilação, leia
`doc/transpilation/PROGRESS.md`.

## Dependências do ecossistema IPFS

Dê prioridade aos ports Dart internos já auditados contra o módulo Go
correspondente. O módulo Go upstream fixado em
`doc/transpilation/UPSTREAM_LOCK.md` continua sendo a fonte autoritativa de
fidelidade. Ports internos ainda não auditados e ports Dart externos servem
apenas como pistas até serem confirmados contra esse upstream.

Cada módulo Go reutilizável portado deve permanecer em um pacote Dart próprio,
respeitando sua fronteira de `go.mod`. Esses pacotes ficam em
`packages/transpiled_<nome_do_modulo>/`; somente a integração do nó embutido
fica no pacote raiz, sob `lib/`.

## Ordem obrigatória: transpilar antes de adaptar

### Tipos primitivos Go compartilhados

Use `packages/boilerplate/`, módulo lógico `fixed_types.Golang.<tipo>`, para
centralizar a representação em bytes e a semântica dos tipos primitivos Go.
Em Dart, importe `package:boilerplate/fixed_types/golang.dart` com prefixo
`Golang`; namespaces de tipos aninhados não existem na linguagem Dart.
O caminho e o prefixo representam o schema solicitado, sem factories dinâmicas
que eliminem a checagem estática dos tipos.

Antes de duplicar máscaras, limites, overflow, shifts ou conversões numéricas
em um port, use o tipo correspondente já validado nesse módulo. Se faltar,
implemente e teste sua semântica ali primeiro, pela especificação Go e vetores
executados em Go. Não atribua fidelidade a tipos ainda não implementados.
O objetivo desse pacote de tipagem simulada como no Golang é reduzir
drasticamente as verificações de limites e comportamentos dentro dessa
transpilação, garantindo que o próprio tipo encapsule as regras da linguagem Go
(overflow módulo 2^N, truncamento, shifts, divisão/resto e extensão de sinal).
Overflow permitido e conversões truncantes Go não devem virar exceções de
faixa arbitrárias. Preserve também divisão, resto, sinal e zero value.
Conversões para tipos Dart devem ser explícitas e não perder precisão.

Essa camada de adaptação não corresponde a um go.mod upstream e é exceção
deliberada ao prefixo `transpiled_`. Ela não absorve codecs nem regras IPFS.
Validações de dados não confiáveis, limites de protocolo e segurança continuam
nos módulos responsáveis. Migre os consumidores com testes de paridade;
não remova verificações apenas porque existe um wrapper de tipo.
É expressamente proibido implementar subsistemas novos sem aviso e
aprovação prévia do mantenedor.

### Rastrear chamadas antes de implementar

Antes de portar, corrigir ou adaptar qualquer função, todo agente deve:

1. consultar o índice AST Go produzido pela ferramenta do projeto (localização
   e uso em `doc/transpilation/PROGRESS.md`) para localizar o símbolo upstream
   e identificar as funções e métodos chamados por ele;
2. resolver cada chamada relevante ao fluxo em análise até sua declaração,
   pacote e módulo proprietário (`go.mod`), conferindo a revisão em
   `UPSTREAM_LOCK.md`. Use imports e aliases; quando o índice sintático não
   resolver métodos, interfaces ou nomes ambíguos, use `gopls`/`go/types` e
   confirme no código. Não invente um destino para chamadas dinâmicas;
3. procurar o símbolo Go correspondente nos índices, notas de paridade e
   pacotes Dart existentes. Reutilize o port auditado; se ainda não estiver
   auditado, confira-o contra o upstream antes de reutilizar ou corrigir;
4. preservar a delegação: se a função Go chama outra função para realizar uma
   operação, a função Dart deve chamar o port correspondente, não copiar ou
   reimplementar a operação dentro do chamador. Uma dependência ausente deve
   ser portada no pacote da sua própria fronteira de `go.mod`, nunca embutida
   no pacote consumidor. Avise o mantenedor antes de implementar subsistema
   novo;
5. registrar em `PROGRESS.md` o rastreamento relevante
   `chamador Go → símbolo chamado → módulo/revisão → símbolo/pacote Dart`,
   indicando reutilização, lacunas e ambiguidades ainda não resolvidas.

O índice AST é ponto de partida, não prova isolada de resolução semântica ou
paridade. Se estiver indisponível ou desatualizado, registre essa condição e
use as declarações upstream e resolução semântica como alternativa verificável.
Qualquer fusão de funções ou eliminação de uma delegação exige justificativa
concreta de incompatibilidade Dart, conforme as regras de preservação da API.

Ao encontrar uma lacuna, limite ou defeito em código Dart correspondente a
Kubo, Boxo ou go-libp2p, siga obrigatoriamente esta ordem:

1. localize o símbolo e o fluxo autoritativos no módulo Go fixado em
   `doc/transpilation/UPSTREAM_LOCK.md`;
2. transpile para o pacote Dart da mesma fronteira de `go.mod`, preservando
   contrato, defaults, lifecycle, limites e erros observáveis;
3. comprove a paridade com vetores ou testes derivados do upstream;
4. somente depois adapte ao runtime ou ao sistema de tipos do Dart, no menor
   ponto necessário e com justificativa concreta documentada em
   `doc/transpilation/PROGRESS.md`.

Não trate placeholders, defaults arbitrários ou APIs originais de ports Dart
externos como equivalentes ao Go sem auditoria. Overrides que apenas elevem ou
desativem limites para fazer um teste passar são diagnósticos temporários, não
soluções finais; o comportamento upstream deve ser portado primeiro. Quando
uma adaptação temporária for indispensável para investigar, marque-a
explicitamente, mantenha-a fora do resultado final e registre o critério de
remoção.

## Preservação da API durante a transpilação

Para toda API pública reutilizável do upstream, preserve o nome conceitual, a
responsabilidade, os valores padrão e o comportamento observável. Adapte
somente o necessário às convenções e ao sistema de tipos do Dart:

- tipos públicos usam `UpperCamelCase` e funções, métodos e campos públicos
  usam `lowerCamelCase`, tratando acrônimos como palavras comuns (ex.: `Cid`,
  `IpfsNode`, `IpfsConfig`, `DhtClient`, `idFromP2pAddr`), sem blocos em All-Caps;
- proibido criar `typedef`s, aliases ou shims artificiais em Dart para acomodar
  compatibilidade retroativa ou nomes legados (ex.: `typedef CID = Cid;`,
  `typedef MultihashInfo = DecodedMultihash;`). Consumidores devem ser migrados
  na raiz para os tipos canônicos. Exceções são apenas os tipos primitivos da
  especificação Go em `packages/boilerplate/` ou type aliases declarados no
  próprio repositório upstream Go;
- a anotação `@Deprecated` só é permitida se o símbolo correspondente no
  upstream Go estiver explicitamente marcado com `// Deprecated:`. É proibido
  manter símbolos deprecados inventados exclusivamente no Dart;
- construtores `NewX` do Go viram construtores ou factories Dart quando isso
  preservar o contrato, sem criar funções `newX` artificiais;
- retornos `(valor, error)` viram retorno do valor com exceção tipada;
- variádicos, canais, goroutines e `context.Context` usam o equivalente Dart
  mais próximo (`List<T>`, `Stream`, `Future`, cancelamento), somente quando o
  comportamento exigir;
- símbolos internos do Go não precisam virar API pública Dart.

Toda renomeação não mecânica, fusão, remoção ou mudança de assinatura pública
deve ser registrada em `doc/transpilation/PROGRESS.md` junto ao símbolo Go
correspondente. Não substitua uma API pública upstream por uma abstração
original sem justificar uma incompatibilidade concreta.

Cada port deve manter uma checklist verificável de símbolos públicos Go → Dart
nas notas do pacote em `PROGRESS.md`, incluindo omissões deliberadas e suas
razões. Paridade exige preservar também wire format, ordenação, defaults e
erros observáveis relevantes; sem essa auditoria, use no máximo o status
`portado sem teste de paridade`.
