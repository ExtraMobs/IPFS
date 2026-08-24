# Índice de arquitetura — visão geral

Gerado por `tool/generate_module_index.dart` em 2026-08-24T07:44:28.732468. Um arquivo por módulo em [lib/](lib/) e [test/](test/), espelhando a estrutura real do repositório.

## Módulos (`lib/src/*`)

| Módulo | Arquivos | Depende de |
|---|---|---|
| [core](lib/core.md) | 123 | network, platform, proto, protocols, routing, services, transport, utils |
| [network](lib/network.md) | 6 | core, transport, utils |
| [platform](lib/platform.md) | 12 | — |
| [proto](lib/proto.md) | 166 | — |
| [protocols](lib/protocols.md) | 76 | core, proto, storage, transport, utils |
| [routing](lib/routing.md) | 5 | core, protocols, utils |
| [services](lib/services.md) | 31 | core, platform, proto, protocols, utils |
| [storage](lib/storage.md) | 1 | core, utils |
| [transport](lib/transport.md) | 34 | core, dart_ipfs_quic[pkg], platform, proto, protocols, utils |
| [utils](lib/utils.md) | 12 | core, platform, proto |

## Grupos de teste (`test/*`)

- [test/(raiz)](test/(raiz).md) (6 arquivos)
- [test/bin](test/bin.md) (1 arquivos)
- [test/core](test/core.md) (141 arquivos)
- [test/e2e](test/e2e.md) (1 arquivos)
- [test/fakes](test/fakes.md) (1 arquivos)
- [test/fuzz](test/fuzz.md) (6 arquivos)
- [test/integration](test/integration.md) (2 arquivos)
- [test/interop](test/interop.md) (11 arquivos)
- [test/mocks](test/mocks.md) (11 arquivos)
- [test/network](test/network.md) (8 arquivos)
- [test/platform](test/platform.md) (2 arquivos)
- [test/property](test/property.md) (4 arquivos)
- [test/proto](test/proto.md) (1 arquivos)
- [test/proto_generated](test/proto_generated.md) (15 arquivos)
- [test/protocols](test/protocols.md) (73 arquivos)
- [test/routing](test/routing.md) (8 arquivos)
- [test/services](test/services.md) (45 arquivos)
- [test/storage](test/storage.md) (1 arquivos)
- [test/transport](test/transport.md) (18 arquivos)
- [test/utils](test/utils.md) (13 arquivos)
- [test/web](test/web.md) (1 arquivos)
