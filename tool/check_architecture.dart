// 아키텍처·결정론 규칙 검사기. 사용법: dart run tool/check_architecture.dart
// 위반이 있으면 목록을 출력하고 exit 1. 규칙: tool/architecture/rules.dart
import 'dart:io';

import 'architecture/rules.dart';

void main() {
  final violations = <String>[];
  var fileCount = 0;
  for (final root in packageRoots.values) {
    for (final sub in const ['lib', 'bin']) {
      final dir = Directory('$root/$sub');
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart')) continue;
        fileCount++;
        final rel = entity.path.replaceAll(r'\', '/');
        violations.addAll(checkFile(rel, entity.readAsStringSync()));
      }
    }
  }
  if (violations.isEmpty) {
    stdout.writeln('architecture OK ($fileCount files)');
    return;
  }
  stderr.writeln('아키텍처·결정론 규칙 위반 ${violations.length}건 (개발 계획서 §2):');
  for (final v in violations) {
    stderr.writeln('  - $v');
  }
  exitCode = 1;
}
