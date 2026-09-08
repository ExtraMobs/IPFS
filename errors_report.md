# Relatório de Auditoria de AST e Nomenclatura (Dart <-> Go)

> Relatório gerado automaticamente por `tool/audit_ast_nomenclature.py`.
> **Símbolos Dart Auditados:** 4742 | **Símbolos Go Indexados:** 29657
> **Status Geral:** ❌ **0 Erros** | ⚠️ **0 Avisos** | ℹ️ **0 Notas de Cobertura**

## 1. Resumo Executivo das 23 Regras

| # | Regra | Severidade | Ocorrências | Status |
| :---: | :--- | :---: | :---: | :---: |
| `RULE_ALL_CAPS` | 1. Violação de UpperCamelCase / lowerCamelCase (Blocos em All-Caps) | `ERROR` | 0 | ✅ Conforme |
| `RULE_LOWER_CAMEL` | 2. Violação de lowerCamelCase (PascalCase em membros públicos) | `ERROR` | 0 | ✅ Conforme |
| `RULE_NO_TYPEDEF_SHIMS` | 3. Veto a Typedefs e Shims Artificiais | `ERROR` | 0 | ✅ Conforme |
| `RULE_NO_UNAUTHORIZED_DEPRECATED` | 4. Veto a @Deprecated Não Existente no Upstream Go | `ERROR` | 0 | ✅ Conforme |
| `RULE_NO_NEW_X_FUNCTIONS` | 5. Veto a Funções Livres newX(...) Artificiais | `ERROR` | 0 | ✅ Conforme |
| `RULE_CONSTANT_CASING` | 6. Veto a Constantes em SCREAMING_SNAKE_CASE | `ERROR` | 0 | ✅ Conforme |
| `RULE_REDUNDANT_CONSTRUCTOR_NAMES` | 7. Veto a Construtores Nomeados Redundantes ou com Prefixo 'new' | `ERROR` | 0 | ✅ Conforme |
| `RULE_NO_GO_STYLE_ERROR_TUPLES` | 8. Veto a Tuplas de Erro Go e Result Wrappers em APIs Públicas | `ERROR` | 0 | ✅ Conforme |
| `RULE_NO_CLI_IN_LIBRARIES` | 9. Veto a Código de CLI em Pacotes de Bibliotecas | `ERROR` | 0 | ✅ Conforme |
| `RULE_ENFORCE_BOILERPLATE_TYPES` | 10. Uso Obrigatório de fixed_types.Golang.* para Tipos Primitivos | `WARNING` | 0 | ✅ Conforme |
| `RULE_MODULE_BOUNDARY_LEAK` | 11. Veto a Violação de Fronteira de Módulo (go.mod) | `ERROR` | 0 | ✅ Conforme |
| `RULE_INVENTED_PUBLIC_SYMBOLS` | 12. Detecção de Símbolos Públicos Inventados (Sem Upstream Go) | `WARNING` | 0 | ✅ Conforme |
| `RULE_EXCEPTION_NAMING` | 13. Nomenclatura e Padrão de Exceções Dart (Veto a prefixo 'Err') | `ERROR` | 0 | ✅ Conforme |
| `RULE_NO_PRODUCTION_MOCKS` | 14. Veto a Mocks, Dummies e Stubs em Código de Biblioteca | `ERROR` | 0 | ✅ Conforme |
| `RULE_RESTRICTED_PLATFORM_IMPORTS` | 15. Veto a dart:io em Pacotes de Codecs/Formatos Puros | `ERROR` | 0 | ✅ Conforme |
| `RULE_NO_PRINT_IN_LIBRARIES` | 16. Veto a chamadas print(...) em Bibliotecas Reutilizáveis | `ERROR` | 0 | ✅ Conforme |
| `RULE_NO_ARTIFICIAL_CONCURRENCY` | 17. Veto a Primitivas Artificiais de Concorrência Go | `ERROR` | 0 | ✅ Conforme |
| `RULE_MISSING_GO_TYPES` | 18. Auditoria de Tipos e Interfaces do Upstream Go Ausentes | `INFO` | 0 | ✅ Conforme |
| `RULE_MISSING_GO_FIELDS` | 19. Auditoria de Campos de Structs do Upstream Go Ausentes | `INFO` | 0 | ✅ Conforme |
| `RULE_MISSING_GO_METHODS` | 20. Auditoria de Métodos do Upstream Go Ausentes | `INFO` | 0 | ✅ Conforme |
| `RULE_MISSING_GO_FUNCTIONS` | 21. Auditoria de Funções Top-Level do Upstream Go Ausentes | `INFO` | 0 | ✅ Conforme |
| `RULE_PUBSPEC_DEPENDENCIES` | 22. Validação de Dependências em pubspec.yaml | `WARNING` | 0 | ✅ Conforme |
| `RULE_EXPOSED_NON_PUBLIC_MEMBERS` | 23. Veto a Membros Públicos que Expõem Tipos Não-Públicos (Menor Permissão) | `ERROR` | 0 | ✅ Conforme |

## 2. Detalhamento dos Apontamentos

🎉 **Nenhuma inconsistência encontrada!** Todo o código auditado está 100% fiel às regras do AGENTS.md.
