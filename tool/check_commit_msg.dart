// 커밋 메시지 검사기 (CLAUDE.md 「브랜치·커밋·버전」, ADR-015).
// 사용법:
//   dart run tool/check_commit_msg.dart <메시지 파일>     # git commit-msg 훅
//   dart run tool/check_commit_msg.dart --range A..B      # CI: 범위 안의 모든 커밋
// 규칙 위반이면 이유를 출력하고 exit 1.
import 'dart:io';

const allowedTypes = {
  'feat',
  'fix',
  'refactor',
  'test',
  'docs',
  'chore',
  'build',
  'ci',
  'perf',
  'balance',
};

const allowedScopes = {
  'sim',
  'ai',
  'data',
  'app',
  'render',
  'input',
  'shipyard',
  'meta',
  'tool',
  'docs',
  'release',
  'deps',
};

const maxSubjectLength = 72;

final _headerRe = RegExp(r'^([a-z]+)\(([a-z]+)\)(!)?: (.+)$');

/// 자동 생성 메시지(머지·되돌리기·fixup)는 검사하지 않는다.
final _exemptRe = RegExp('^(Merge |Revert "|fixup! |squash! |amend! )');

/// [message] 의 첫 줄이 Conventional Commits 규칙을 어기면 이유 목록, 맞으면 빈 목록.
List<String> checkCommitMessage(String message) {
  final lines = message
      .replaceAll('\r\n', '\n')
      .split('\n')
      .where((l) => !l.startsWith('#'))
      .toList();
  final header = lines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  if (header.isEmpty) return ['커밋 메시지가 비어 있다'];
  if (_exemptRe.hasMatch(header)) return const [];

  final m = _headerRe.firstMatch(header);
  if (m == null) {
    return ['첫 줄 형식은 `<type>(<scope>): <요약>` 이다: "$header"'];
  }
  final errors = <String>[];
  final type = m.group(1)!;
  final scope = m.group(2)!;
  final subject = m.group(4)!;
  if (!allowedTypes.contains(type)) {
    errors.add('type `$type` 은 허용되지 않는다. 허용: ${allowedTypes.join(', ')}');
  }
  if (!allowedScopes.contains(scope)) {
    errors.add('scope `$scope` 은 허용되지 않는다. 허용: ${allowedScopes.join(', ')}');
  }
  if (header.runes.length > maxSubjectLength) {
    errors.add('첫 줄이 ${header.runes.length}자다. $maxSubjectLength자 이하로 줄인다');
  }
  if (subject.endsWith('.')) errors.add('요약 끝에 마침표를 찍지 않는다');
  final headerIndex = lines.indexOf(header);
  if (headerIndex + 1 < lines.length &&
      lines[headerIndex + 1].trim().isNotEmpty) {
    errors.add('첫 줄과 본문 사이는 빈 줄로 띄운다');
  }
  return errors;
}

Future<void> main(List<String> args) async {
  final messages = <String, String>{};
  if (args.length == 2 && args[0] == '--range') {
    final log = await Process.run('git', [
      'log',
      '--format=%H%x00%B%x01',
      args[1],
    ]);
    if (log.exitCode != 0) {
      stderr.write(log.stderr);
      exitCode = 2;
      return;
    }
    for (final entry in (log.stdout as String).split('\x01')) {
      final parts = entry.trim().split('\x00');
      if (parts.length == 2) messages[parts[0].substring(0, 7)] = parts[1];
    }
  } else if (args.length == 1) {
    messages['message'] = File(args[0]).readAsStringSync();
  } else {
    stderr.writeln('사용법: check_commit_msg.dart <파일> | --range A..B');
    exitCode = 2;
    return;
  }

  var failed = false;
  for (final e in messages.entries) {
    final errors = checkCommitMessage(e.value);
    if (errors.isEmpty) continue;
    failed = true;
    stderr.writeln('커밋 메시지 규칙 위반 (${e.key}):');
    for (final err in errors) {
      stderr.writeln('  - $err');
    }
  }
  if (failed) {
    stderr.writeln('예: feat(sim): 파도 높이에 따라 흘수선을 바꾼다');
    exitCode = 1;
  } else {
    stdout.writeln('commit message OK (${messages.length})');
  }
}
