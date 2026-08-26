# Escopo do projeto

O objetivo deste projeto é portar para Dart apenas bibliotecas reutilizáveis
necessárias para executar um nó IPFS embutido em aplicações Dart ou Flutter.

Kubo, Boxo e go-libp2p são referências de comportamento, não superfícies de
produto que devam ser reproduzidas integralmente.

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
