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
- constantes públicas usam `lowerCamelCase` (ex.: `maxBlockSize`, `defaultTimeout`),
  sendo proibido o uso de `SCREAMING_SNAKE_CASE`;
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
  preservar o contrato, sem criar funções `newX` artificiais e sem prefixar
  construtores nomeados com `new` redundante (ex.: usar `IpfsNetwork.fromIpfsHost`,
  não `IpfsNetwork.newFromIpfsHost`);
- retornos `(valor, error)` viram retorno do valor com exceção tipada, sendo
  vedado retornar tuplas de erro Go `(T?, Exception?)` ou wrappers `Result<T, E>`
  em APIs públicas de biblioteca;
- variádicos, canais, goroutines e `context.Context` usam o equivalente Dart
  mais próximo (`List<T>`, `Stream`, `Future`, cancelamento), somente quando o
  comportamento exigir;
- símbolos internos do Go não precisam virar API pública Dart. Classes ou funções
  auxiliares não existentes no Go upstream devem ser privadas (prefixo `_`) para
  evitar expansão arbitrária de API pública.

Toda renomeação não mecânica, fusão, remoção ou mudança de assinatura pública
deve ser registrada em `doc/transpilation/PROGRESS.md` junto ao símbolo Go
correspondente. Não substitua uma API pública upstream por uma abstração
original sem justificar uma incompatibilidade concreta.

Cada port deve manter uma checklist verificável de símbolos públicos Go → Dart
nas notas do pacote em `PROGRESS.md`, incluindo omissões deliberadas e suas
razões. Paridade exige preservar também wire format, ordenação, defaults e
erros observáveis relevantes; sem essa auditoria, use no máximo o status
`portado sem teste de paridade`.

## Auditoria automatizada de AST, nomenclatura e fronteiras

Para garantir fidelidade contínua e prevenir regressões sintáticas ou de API, todo
agente deve validar seu código contra o auditor AST do projeto:
`tool/audit_ast_nomenclature.py`.

A ferramenta compara o índice AST do Go (`go-ipfs-reference/*-index/`) e as
definições de tipos upstream com as declarações Dart em `packages/` e `lib/`,
auditando automaticamente as 24 regras contratuais:

1. **`RULE_ALL_CAPS`**: Tipos públicos em `UpperCamelCase` e membros/funções em
   `lowerCamelCase`, tratando acrônimos como palavras comuns (ex.: `Cid`, `IpfsNode`,
   `DhtClient`, `idFromP2pAddr`), sem blocos em All-Caps.
2. **`RULE_LOWER_CAMEL`**: Membros, métodos e funções públicas devem usar
   estritamente `lowerCamelCase`, nunca `PascalCase`.
3. **`RULE_NO_TYPEDEF_SHIMS`**: Veto a `typedef`s e shims artificiais em Dart para
   compatibilidade retroativa, exceto os tipos primitivos em `packages/boilerplate/`
   ou type aliases declarados no próprio repositório upstream Go.
4. **`RULE_NO_UNAUTHORIZED_DEPRECATED`**: Veto a anotações `@Deprecated` inventadas
   em Dart sem a anotação `// Deprecated:` correspondente no Go upstream.
5. **`RULE_NO_NEW_X_FUNCTIONS`**: Veto a funções livres `newX(...)` que deveriam
   ser construtores ou factories de classe.
6. **`RULE_CONSTANT_CASING`**: Veto a constantes públicas em `SCREAMING_SNAKE_CASE`
   (ex.: `MAX_PACKET_SIZE`). No Dart oficial e no projeto, devem ser `lowerCamelCase`
   (`maxPacketSize`).
7. **`RULE_REDUNDANT_CONSTRUCTOR_NAMES`**: Veto a construtores nomeados prefixados
   com `new` ou repetindo o nome da classe (ex.: `IpfsNetwork.newFromIpfsHost` ➔
   `IpfsNetwork.fromIpfsHost`; `Blockstore.newBlockstore` ➔ `Blockstore`).
8. **`RULE_NO_GO_STYLE_ERROR_TUPLES`**: Veto a retornos públicos de tuplas com erro
   `(T?, Exception?)` ou wrappers `Result<T, E>`. Retornos `(valor, error)` do Go
   devem virar retorno direto do valor com exceção tipada via `throw`.
9. **`RULE_NO_CLI_IN_LIBRARIES`**: Veto a dependências e códigos de CLI em bibliotecas
   reutilizáveis `packages/transpiled_*` (`package:args/*`, `exitCode`, chamadas `exit()`).
10. **`RULE_ENFORCE_BOILERPLATE_TYPES`**: Uso obrigatório de `fixed_types.Golang.*`
    para centralizar semântica de tipos primitivos Go e máscaras manuais de 32/64 bits.
11. **`RULE_MODULE_BOUNDARY_LEAK`**: Veto a violação de fronteira de módulo `go.mod`,
    impedindo que um pacote declare tipos que pertencem a outro módulo upstream com
    pacote dedicado próprio.
12. **`RULE_INVENTED_PUBLIC_SYMBOLS`**: Alerta sobre tipos e abstrações públicas
    criadas em Dart sem símbolo exportado correspondente no upstream Go, orientando
    torná-los privados (`_Nome`) ou documentar sua necessidade.
13. **`RULE_EXCEPTION_NAMING`**: Nomenclatura e padrão de exceções Dart, exigindo
    que classes de erro usem o sufixo `Exception` e implementem `Exception`, vetando
    o prefixo legado `Err` do Go (ex.: `ErrTooShort` ➔ `TooShortException`).
14. **`RULE_NO_PRODUCTION_MOCKS`**: Veto a classes e implementações de teste
    (`Mock*`, `Dummy*`, `Stub*`, `Fake*`) no código de produção em `lib/`, devendo
    residir estritamente sob `test/`.
15. **`RULE_RESTRICTED_PLATFORM_IMPORTS`**: Veto a importação de `dart:io` em pacotes
    de codecs e multiformatos puros (`cid`, `multihash`, `multibase`, etc.),
    garantindo compatibilidade universal Web/Wasm.
16. **`RULE_NO_PRINT_IN_LIBRARIES`**: Veto a chamadas soltas a `print(...)` em pacotes
    de bibliotecas reutilizáveis.
17. **`RULE_NO_ARTIFICIAL_CONCURRENCY`**: Veto a primitivas de concorrência específicas
    do Go (`Chan`, `WaitGroup`, `Mutex`) em APIs públicas, exigindo as primitivas
    idiomáticas Dart (`Stream`, `Future`, `Completer`).
18. **`RULE_MISSING_GO_TYPES`**: Auditoria de tipos e interfaces do Upstream Go
    ainda não portados para o pacote Dart correspondente.
19. **`RULE_MISSING_GO_FIELDS`**: Auditoria de campos de structs do Upstream Go
    ainda não declarados na classe Dart correspondente.
20. **`RULE_MISSING_GO_METHODS`**: Auditoria de métodos do Upstream Go ainda não
    implementados na classe Dart correspondente.
21. **`RULE_MISSING_GO_FUNCTIONS`**: Auditoria de funções top-level do Upstream Go
    ainda não portadas para o pacote Dart correspondente.
22. **`RULE_PUBSPEC_DEPENDENCIES`**: Veto a dependências exclusivas de CLI (`args`, `dcli`)
    em `dependencies` de pacotes de bibliotecas reutilizáveis sob `packages/`,
    garantindo que utilitários de console residam estritamente sob `dev_dependencies`
    ou na raiz.
23. **`RULE_EXPOSED_NON_PUBLIC_MEMBERS`**: Veto a membros públicos que expõem
    tipos não-públicos (privados `_` ou de pacotes `internal/`), exigindo paridade
    estrita com o mesmo nível de visibilidade e permissão do Upstream Go, ou menor
    se não for possível. Membros públicos devem retornar interfaces públicas ou
    serem tornados privados (`_`) caso sejam detalhes internos de implementação.
24. **`RULE_MISSING_ATOMIC_TESTS`**: Auditoria de testes atômicos 1 para 1
    (`testes/<nivel>/<nome_modulo>_atomic_tests.dart`), exigindo que cada função,
    método, getter, setter e operador público possua um teste atômico correspondente.
    A ausência de teste é apontada como erro bloqueante (`ERROR`).

### Nível de visibilidade, permissão e tipos não-públicos

Ao portar e adaptar código onde membros públicos interagem com tipos não-públicos
(privados `unexported` ou pacotes `internal/` do Go), todo agente deve seguir o
**Princípio do Menor Privilégio e Paridade de Permissão**:

1. **Paridade com a Menor Permissão Possível:** Se um membro público da biblioteca
   precisa expor um objeto que no Go era um tipo interno, o tipo Dart deve conceder
   estritamente o mesmo nível de visibilidade e permissão do Upstream Go, ou menor
   se não for possível (ex.: interface somente-leitura ou `unmodifiable`). É vedado
   expor classes concretas mutáveis internas com campos desprotegidos.
2. **Veto a Tipos Privados em Assinaturas Públicas (`library_private_types_in_public_api`):**
   Membros públicos (métodos, getters, setters, campos) de classes públicas nunca devem
   ter tipo de retorno ou parâmetros com prefixo `_` (ex.: `_Scope get scope`,
   `_RecallWantlist bcstWants`).
3. **Mapeamento Caso a Caso dos Cenários Conhecidos:**
   - **Cenário A: Getters/Métodos de Interfaces Públicas (ex.: `ResourceManager` em `transpiled_libp2p`):**
     Getters como `systemScope`, `transientScope`, `peers`, `protocols` e `services`
     devem ser tipados com suas interfaces públicas canônicas (`Scope`, `PeerScope`,
     `ProtocolScope`, `ServiceScope`), e **nunca** com as classes de implementação
     privadas (`_Scope`, `_PeerScope`).
   - **Cenário B: Campos Internos de Classes de Submódulos (ex.: `MessageQueue` em `transpiled_boxo`):**
     Campos de classes internas que armazenam estado auxiliar (ex.: `bcstWants`,
     `peerWants`, `pending`, `sent`) devem ser tornados privados (`_bcstWants`,
     `_peerWants`, `_pending`, `_sent`), eliminando a exposição indevida.
   - **Cenário C: Estruturas Auxiliares Expostas Transitivamente (ex.: `ExploreRecursiveEdge` em `transpiled_ipld_prime`):**
     Promover a classe para pública (`ExploreRecursiveEdge`) ou expor apenas a
     interface necessária com campos imutáveis/somente-leitura.
4. **Fidelidade Integral da Implementação Não-Pública:**
   Tudo o que for acessado ou exposto através de métodos não-públicos (ou da cadeia
   interna de execução de métodos públicos) **deve ser implementado com estrita
   fidelidade ao upstream Golang**. O fato de um membro, tipo ou método ser privado
   (`_` em Dart, `unexported` ou `internal/` no Go) afeta estritamente sua visibilidade
   e escopo de acesso, **sendo expressamente proibido degradar a lógica interna**,
   criar simplificações arbitrárias, stubs parciais ou mocks em código de produção.
   Toda a cadeia de chamadas internas, estados, limites e algoritmos subjacentes
   deve reproduzir fielmente a implementação do módulo Go correspondente.

### Comandos de verificação recomendados

Antes de concluir qualquer alteração de código ou transpilação, o agente deve
executar o script e assegurar que nenhuma nova violação ou regressão foi introduzida:

- **Resumo quantitativo global:**
  `python tool/audit_ast_nomenclature.py --summary-only`
- **Auditoria detalhada do pacote alterado:**
  `python tool/audit_ast_nomenclature.py --package <nome_do_pacote>`
- **Auditoria de testes atômicos 1 para 1:**
  `python tool/audit_ast_nomenclature.py --tests`
- **Auditoria de testes atômicos por pacote:**
  `python tool/audit_ast_nomenclature.py --tests --package <nome_do_pacote>`
- **Geração determinística de esqueleto de testes atômicos (scaffold):**
  `python tool/audit_ast_nomenclature.py --scaffold <nome_modulo_ou_pacote> --level nivel_1`
- **Auditoria por regra específica:**
  `python tool/audit_ast_nomenclature.py --rule <NOME_DA_REGRA>`
- **Auditoria de cobertura incluindo símbolos não-públicos (privados/internos):**
  `python tool/audit_ast_nomenclature.py --include-non-public`
- **Filtrar por severidade (ERROR, WARNING, INFO):**
  `python tool/audit_ast_nomenclature.py --severity ERROR`
- **Exportar relatório completo em Markdown:**
  `python tool/audit_ast_nomenclature.py --markdown --output audit_report.md`
- **Atualizar relatório sintético de progresso da AST (`PROGRESS_RELATORY.md`):**
  `python tool/audit_ast_nomenclature.py --progress`
- **Correção automática mecânica determinística:**
  `python tool/audit_ast_nomenclature.py --fix`
- **Saída estruturada em JSON (integração e CI):**
  `python tool/audit_ast_nomenclature.py --json`
