// tool/generate_module_index.dart
//
// Walks lib/src/<module>/**/*.dart AND test/**/*.dart, extracts import
// directives, maps each import target back to the top-level module that
// owns it, and writes a markdown+mermaid report to
// doc/architecture/module-index.md.
//
// This is a reporting aid, not a CI gate (see test/architecture_boundary_test.dart
// for the enforced version). Regenerate before/after each refactor phase per
// the "índice vivo" methodology in the approved plan.
//
// Known simplification: only the first URI in a conditional import
// (`import 'x' if (...) 'y'`) is followed; export directives are counted as
// edges but a file is not considered "tested" via export-only reachability.
//
// Usage: dart run tool/generate_module_index.dart

import 'dart:io';

const List<String> modules = [
  'core',
  'network',
  'platform',
  'proto',
  'protocols',
  'routing',
  'services',
  'storage',
  'transport',
  'utils',
];

String _toForwardSlashes(String path) => path.replaceAll(r'\', '/');

String? _moduleOf(String path) {
  final normalized = path.replaceAll('\\', '/');
  final idx = normalized.indexOf('lib/src/');
  if (idx == -1) return null;
  final rest = normalized.substring(idx + 'lib/src/'.length);
  final parts = rest.split('/');
  if (parts.isEmpty) return null;
  final top = parts.first;
  return modules.contains(top) ? top : null;
}

/// Top-level directory under test/ that [path] lives in, e.g. "protocols"
/// for "test/protocols/dht/foo_test.dart", or null if directly under test/.
String? _testGroupOf(String path) {
  final normalized = path.replaceAll('\\', '/');
  final idx = normalized.indexOf('test/');
  if (idx == -1) return null;
  final rest = normalized.substring(idx + 'test/'.length);
  final parts = rest.split('/');
  if (parts.length < 2) return null; // file directly under test/
  return parts.first;
}

String _normalizePath(String path) {
  final parts = path.split('/');
  final result = <String>[];
  for (final part in parts) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (result.isNotEmpty) result.removeLast();
    } else {
      result.add(part);
    }
  }
  return result.join('/');
}

/// Resolves an import/export [target] found inside a file at [fileDir] to a
/// repo-relative path, or null if it's an external package / dart: import
/// this tool doesn't track path-wise.
String? _resolveTarget(String target, String fileDir) {
  if (target.startsWith('package:dart_ipfs/src/')) {
    return 'lib/src/${target.substring('package:dart_ipfs/src/'.length)}';
  }
  if (target.startsWith('.')) {
    return _normalizePath('$fileDir/$target');
  }
  return null;
}

final _docLine = RegExp(r'^///\s?(.*)$', multiLine: true);
final _typeDecl = RegExp(
  r'^(?:abstract\s+)?(?:class|mixin|enum)\s+(\w+)',
  multiLine: true,
);

/// First `///` line in [content] (the file's own doc comment), or '' if
/// none. Pulled verbatim from source, never authored by this tool.
String _docSummary(String content) => _docLine.firstMatch(content)?.group(1)?.trim() ?? '';

/// Top-level class/mixin/enum names declared in [content].
List<String> _declaredTypes(String content) =>
    _typeDecl.allMatches(content).map((m) => m.group(1)!).toList();

void main() {
  final libSrc = Directory('lib/src');
  final testDir = Directory('test');
  if (!libSrc.existsSync()) {
    stderr.writeln('lib/src not found — run from the repo root.');
    exit(1);
  }

  final libFiles = libSrc
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
  final testFiles = testDir.existsSync()
      ? testDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList()
      : <File>[];

  final importPattern = RegExp(
    r'''^\s*(?:export|import)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  // --- lib/src module-to-module dependency graph, and per-file audit info ---
  final fileCount = <String, int>{};
  final edges = <String, Set<String>>{};
  // path -> (doc summary, declared types), for the per-file audit section.
  final fileInfo = <String, (String, List<String>)>{};

  for (final file in libFiles) {
    final mod = _moduleOf(file.path);
    if (mod == null) continue;
    fileCount[mod] = (fileCount[mod] ?? 0) + 1;

    final content = file.readAsStringSync();
    final fileDir = _toForwardSlashes(file.parent.path);
    final rel = _toForwardSlashes(file.path);
    fileInfo[rel.substring(rel.indexOf('lib/src/'))] = (
      _docSummary(content),
      _declaredTypes(content),
    );

    for (final match in importPattern.allMatches(content)) {
      final target = match.group(1)!;
      String? targetPath;
      if (target.startsWith('package:dart_ipfs_core')) {
        edges.putIfAbsent(mod, () => {}).add('dart_ipfs_core[pkg]');
        continue;
      } else if (target.startsWith('package:dart_ipfs_quic')) {
        edges.putIfAbsent(mod, () => {}).add('dart_ipfs_quic[pkg]');
        continue;
      }
      targetPath = _resolveTarget(target, fileDir);
      if (targetPath == null) continue;
      final targetMod = _moduleOf(targetPath);
      if (targetMod != null && targetMod != mod) {
        edges.putIfAbsent(mod, () => {}).add(targetMod);
      }
    }
  }

  final reverseEdges = <String, Set<String>>{};
  for (final entry in edges.entries) {
    for (final target in entry.value) {
      reverseEdges.putIfAbsent(target, () => {}).add(entry.key);
    }
  }

  // --- test/ coverage: file counts per group + which lib/src files are
  // directly imported by at least one test file ---
  final testGroupCount = <String, int>{};
  final directlyTested = <String>{}; // repo-relative lib/src/... paths

  for (final file in testFiles) {
    final group = _testGroupOf(file.path) ?? '(raiz)';
    testGroupCount[group] = (testGroupCount[group] ?? 0) + 1;

    final content = file.readAsStringSync();
    final fileDir = _toForwardSlashes(file.parent.path);
    for (final match in importPattern.allMatches(content)) {
      final target = _resolveTarget(match.group(1)!, fileDir);
      if (target != null && target.startsWith('lib/src/')) {
        directlyTested.add(target);
      }
    }
  }

  final untestedByModule = <String, List<String>>{};
  for (final file in libFiles) {
    final mod = _moduleOf(file.path);
    if (mod == null) continue;
    final rel = _toForwardSlashes(file.path);
    final relFromLib = rel.substring(rel.indexOf('lib/src/'));
    if (!directlyTested.contains(relFromLib)) {
      untestedByModule.putIfAbsent(mod, () => []).add(relFromLib);
    }
  }

  // --- write report ---
  final buf = StringBuffer();
  buf.writeln('# Índice de módulos e testes — estado atual do repositório\n');
  buf.writeln(
    'Gerado automaticamente por `tool/generate_module_index.dart` em ${DateTime.now().toIso8601String()}. '
    'Não editar à mão — regenerar com `dart run tool/generate_module_index.dart`.\n',
  );

  buf.writeln('## Tamanho por módulo (`lib/src/*`)\n');
  buf.writeln('| Módulo | Arquivos .dart | Sem teste direto |');
  buf.writeln('|---|---|---|');
  for (final m in modules) {
    final untested = untestedByModule[m]?.length ?? 0;
    buf.writeln('| $m | ${fileCount[m] ?? 0} | $untested |');
  }

  buf.writeln('\n## Grafo de dependências real entre módulos (mermaid)\n');
  buf.writeln('```mermaid');
  buf.writeln('graph LR');
  final drawn = <String>{};
  for (final m in modules) {
    if ((fileCount[m] ?? 0) > 0) {
      buf.writeln('    $m["$m (${fileCount[m]})"]');
    }
  }
  for (final entry in edges.entries) {
    for (final target in entry.value) {
      final safeTarget = target.replaceAll('[', '_').replaceAll(']', '');
      final edgeKey = '${entry.key}->$safeTarget';
      if (drawn.add(edgeKey)) {
        buf.writeln('    ${entry.key} --> $safeTarget');
      }
    }
  }
  buf.writeln('```\n');

  buf.writeln('## Módulo → depende de\n');
  buf.writeln('| Módulo | Depende de |');
  buf.writeln('|---|---|');
  for (final m in modules) {
    final deps = (edges[m]?.toList() ?? [])..sort();
    buf.writeln('| $m | ${deps.isEmpty ? "—" : deps.join(", ")} |');
  }

  buf.writeln('\n## Módulo → é usado por\n');
  buf.writeln('| Módulo | Usado por |');
  buf.writeln('|---|---|');
  for (final m in modules) {
    final users = (reverseEdges[m]?.toList() ?? [])..sort();
    buf.writeln('| $m | ${users.isEmpty ? "—" : users.join(", ")} |');
  }

  buf.writeln('\n## Arquivos de teste por grupo (`test/*`)\n');
  buf.writeln('| Grupo | Arquivos .dart |');
  buf.writeln('|---|---|');
  final sortedGroups = testGroupCount.keys.toList()..sort();
  for (final g in sortedGroups) {
    buf.writeln('| test/$g | ${testGroupCount[g]} |');
  }
  buf.writeln(
    '\nTotal de arquivos em `lib/src/` importados diretamente por algum '
    'teste: ${directlyTested.length} de ${libFiles.length}.\n',
  );
  buf.writeln(
    '_Nota: "sem teste direto" conta arquivos que nenhum arquivo em `test/` '
    'importa pelo caminho `package:dart_ipfs/src/...` -- um arquivo pode '
    'estar coberto indiretamente (via um arquivo que o importa e que é '
    'testado) sem aparecer aqui como testado. Não é prova de cobertura '
    'zero, é um sinal de onde checar com mais atenção antes de mexer._\n',
  );

  buf.writeln('## Auditoria por arquivo (`lib/src/*`)\n');
  buf.writeln(
    '_Resumo extraído do primeiro comentário `///` de cada arquivo -- não '
    'escrito por esta ferramenta, é o que o próprio código já documenta._\n',
  );
  for (final m in modules) {
    final files = fileInfo.keys.where((f) => _moduleOf(f) == m).toList()
      ..sort();
    if (files.isEmpty) continue;
    buf.writeln('<details><summary><code>$m</code> (${files.length})</summary>\n');
    buf.writeln('| Arquivo | Resumo | Declara | Testado |');
    buf.writeln('|---|---|---|---|');
    for (final f in files) {
      final (doc, types) = fileInfo[f]!;
      final tested = directlyTested.contains(f) ? '✓' : '—';
      final typesCell = types.isEmpty ? '—' : types.join(', ');
      final docCell = doc.isEmpty ? '—' : doc.replaceAll('|', r'\|');
      buf.writeln('| `$f` | $docCell | $typesCell | $tested |');
    }
    buf.writeln('\n</details>\n');
  }

  final outDir = Directory('doc/architecture');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final outFile = File('doc/architecture/module-index.md');
  outFile.writeAsStringSync(buf.toString());
  stdout.writeln('Escrito em ${outFile.path}');
}
