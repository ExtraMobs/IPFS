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

## Preservação da API durante a transpilação

Para toda API pública reutilizável do upstream, preserve o nome conceitual, a
responsabilidade, os valores padrão e o comportamento observável. Adapte
somente o necessário às convenções e ao sistema de tipos do Dart:

- tipos públicos usam `UpperCamelCase` e funções, métodos e campos públicos
  usam `lowerCamelCase`;
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
