# Using the architecture index

This directory (`doc/architecture/`) is a generated audit index of `lib/src/`
and `test/`, meant to be consulted by an AI agent (or a human) before making
changes -- so structure and reference information doesn't need to be
re-derived from scratch every session. This file is hand-maintained; the
`lib/*.md`, `test/*.md`, and `README.md` files next to it are not (see
their own headers).

## How to use it

1. Start at [README.md](README.md), then open the module file for whatever
   you're about to touch.
2. Each module file lists, per source file: its own doc comment, whether any
   test imports it directly, and every declared type/function/variable with
   its own doc comment.
3. Before renaming, deleting, or changing the signature of anything, check
   its **referenced by** list -- but treat it as a lead, not proof. Matches
   are by identifier *name* only, not resolved type (the caveat is repeated
   at the top of every module file): a `start` referenced-by list includes
   every `start()` call in the codebase, not just calls to *this* `start()`.
   Confirm with a real search (grep, IDE go-to-definition) before acting on
   an ambiguous name. Short, specific names (`convertToProtoBlock`,
   `cborTags`) are far more trustworthy than common ones (`start`, `length`,
   `build`).
4. `calls` under a member is the reverse view: what that member's body
   invokes, under the same name-matching caveat.
5. The module-level "Depends on" line is the real import graph (regex over
   actual `import`/`export` statements, not name-matching) -- that part is
   reliable, unlike the by-name call/reference data.
6. `test/<group>.md` files list every `test()`/`group()` description found
   in that test directory -- check here before writing a new test to see if
   one already covers the case.

## Keeping it current

This index goes stale the moment source changes. Regenerate it after any
non-trivial edit, and especially before relying on it to plan a refactor
step:

```bash
dart run tool/generate_module_index.dart
```
