// tool/generate_module_index.dart
//
// Walks lib/src/<module>/**/*.dart, extracts import directives, maps each
// import target back to the top-level module that owns it, and writes a
// markdown+mermaid report to doc/architecture/module-index.md.
//
// This is a reporting aid, not a CI gate (see test/architecture_boundary_test.dart
// for the enforced version). Regenerate before/after each refactor phase per
// the "índice vivo" methodology in the approved plan.
//
// Known simplification: only the first URI in a conditional import
// (`import 'x' if (...) 'y'`) is followed; export directives are not tracked.
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

void main() {
  final libSrc = Directory('lib/src');
  if (!libSrc.existsSync()) {
    stderr.writeln('lib/src not found — run from the repo root.');
    exit(1);
  }

  final files = libSrc
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final fileCount = <String, int>{};
  final edges = <String, Set<String>>{};
  final importPattern = RegExp(
    r'''^\s*(?:export|import)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  for (final file in files) {
    final mod = _moduleOf(file.path);
    if (mod == null) continue;
    fileCount[mod] = (fileCount[mod] ?? 0) + 1;

    final content = file.readAsStringSync();
    final fileDir = _toForwardSlashes(file.parent.path);

    for (final match in importPattern.allMatches(content)) {
      final target = match.group(1)!;
      String? targetPath;

      if (target.startsWith('package:dart_ipfs/src/')) {
        targetPath = 'lib/src/${target.substring('package:dart_ipfs/src/'.length)}';
      } else if (target.startsWith('package:dart_ipfs_core')) {
        edges.putIfAbsent(mod, () => {}).add('dart_ipfs_core[pkg]');
        continue;
      } else if (target.startsWith('package:dart_ipfs_quic')) {
        edges.putIfAbsent(mod, () => {}).add('dart_ipfs_quic[pkg]');
        continue;
      } else if (target.startsWith('.')) {
        targetPath = _normalizePath('$fileDir/$target');
      } else {
        continue; // external package or dart: import
      }

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

  final buf = StringBuffer();
  buf.writeln('# Índice de módulos — estado atual do repositório\n');
  buf.writeln(
    'Gerado automaticamente por `tool/generate_module_index.dart` em ${DateTime.now().toIso8601String()}. '
    'Não editar à mão — regenerar com `dart run tool/generate_module_index.dart`.\n',
  );

  buf.writeln('## Tamanho por módulo (`lib/src/*`)\n');
  buf.writeln('| Módulo | Arquivos .dart |');
  buf.writeln('|---|---|');
  for (final m in modules) {
    buf.writeln('| $m | ${fileCount[m] ?? 0} |');
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

  final outDir = Directory('doc/architecture');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final outFile = File('doc/architecture/module-index.md');
  outFile.writeAsStringSync(buf.toString());
  stdout.writeln('Escrito em ${outFile.path}');
}
