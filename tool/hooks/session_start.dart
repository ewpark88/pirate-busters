// Claude Code SessionStart 훅: 세션 시작 때 현재 단계·브랜치·작업 트리·문서 동기화 상태를 알린다.
// 표준 출력은 에이전트 컨텍스트에 들어간다 (docs/HARNESS.md).
import 'dart:io';

Future<void> main() async {
  final out = StringBuffer('[pirate-busters 하네스]\n');
  final claude = File('CLAUDE.md');
  if (claude.existsSync()) {
    final stage = claude.readAsLinesSync().firstWhere(
      (l) => l.contains('현재 단계'),
      orElse: () => '',
    );
    if (stage.isNotEmpty) out.writeln(stage.replaceAll('**', '').trim());
  }
  final branch = await _run('git', ['branch', '--show-current']);
  out.writeln('브랜치: ${branch.isEmpty ? '(detached)' : branch}');
  if (branch == 'main') {
    out.writeln('주의: main 에서 작업하지 않는다. /step-start 로 feat/<단계>-<이름> 브랜치를 만든다.');
  }
  final status = await _run('git', ['status', '--short']);
  final changed = status.isEmpty ? 0 : status.split('\n').length;
  out.writeln('커밋 안 된 파일: $changed개');
  final sync = await Process.run('dart', [
    'run',
    'tool/check_doc_sync.dart',
  ], runInShell: true);
  if (sync.exitCode != 0) {
    out.writeln(
      '설계서가 바뀌었다. 다른 작업보다 먼저 CLAUDE.md 「설계서가 바뀌면」 절차(/doc-sync)를 따른다.',
    );
  }
  final hooks = await _run('git', ['config', 'core.hooksPath']);
  if (hooks != '.githooks') {
    out.writeln('git 훅이 꺼져 있다. 사용자에게 `bash tool/install_hooks.sh` 실행을 제안한다.');
  }
  stdout.write(out);
}

Future<String> _run(String exe, List<String> args) async {
  final r = await Process.run(exe, args, runInShell: true);
  return r.exitCode == 0 ? (r.stdout as String).trim() : '';
}
