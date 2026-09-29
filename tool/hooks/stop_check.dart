// Claude Code Stop 훅: 에이전트가 턴을 끝내기 전에 빠른 규칙 검사를 돌린다.
// 작업 트리에 바뀐 파일이 있을 때만 아키텍처·결정론, 문서 동기화, ARB 짝을 검사한다.
// 위반이면 exit 2 로 에이전트에게 되돌려 고치게 한다. 전체 게이트(verify)는 완료 선언 전에 에이전트가 직접 돌린다.
import 'dart:convert';
import 'dart:io';

const checks = [
  'tool/check_architecture.dart',
  'tool/check_doc_sync.dart',
  'tool/check_l10n.dart',
];

Future<void> main() async {
  final raw = await stdin.transform(utf8.decoder).join();
  try {
    final input = jsonDecode(raw);
    // 이미 한 번 막아서 다시 도는 중이면 무한 반복을 피하려고 통과시킨다.
    if (input is Map && input['stop_hook_active'] == true) return;
  } on FormatException {
    // 입력이 없으면 그냥 검사한다.
  }
  final status = await Process.run('git', [
    'status',
    '--porcelain',
  ], runInShell: true);
  if ((status.stdout as String).trim().isEmpty) return;

  final failures = StringBuffer();
  for (final check in checks) {
    final r = await Process.run('dart', ['run', check], runInShell: true);
    if (r.exitCode != 0) {
      failures
        ..writeln('✗ $check')
        ..write(r.stdout)
        ..write(r.stderr);
    }
  }
  if (failures.isEmpty) return;
  stderr
    ..writeln('하네스 규칙 위반이 남아 있다. 고친 뒤 끝낸다 (docs/HARNESS.md):')
    ..write(failures);
  exitCode = 2;
}
