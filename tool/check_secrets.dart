// 비밀 정보 유출 검사기 (CLAUDE.md 「출시」, docs/RELEASE.md §4, ADR-015).
// 사용법:
//   dart run tool/check_secrets.dart            # git 이 추적하는 모든 파일
//   dart run tool/check_secrets.dart --staged   # 커밋하려고 스테이징한 파일 (pre-commit 훅)
// 서명 키·설정 파일이나 키 모양 문자열이 있으면 exit 1.
import 'dart:io';

/// 커밋하면 안 되는 파일 이름(경로 끝 기준).
const forbiddenFileSuffixes = [
  'key.properties',
  '.jks',
  '.keystore',
  'google-services.json',
  'GoogleService-Info.plist',
  '.env',
  'upload_certificate.pem',
  'play-service-account.json',
];

/// 키 모양 문자열과 이름.
final Map<String, RegExp> secretPatterns = {
  '개인 키': RegExp('-----BEGIN (?:RSA |EC |OPENSSH |)PRIVATE KEY-----'),
  'Google API 키': RegExp(r'AIza[0-9A-Za-z_\-]{35}'),
  'GitHub 토큰': RegExp('gh[pousr]_[0-9A-Za-z]{36}'),
  'AWS 액세스 키': RegExp('AKIA[0-9A-Z]{16}'),
  '서비스 계정 JSON': RegExp(r'"type"\s*:\s*"service_account"'),
};

/// [path] 파일과 그 [content] 의 위반 목록. [content] 가 null 이면 이름만 검사한다.
List<String> checkSecrets(String path, String? content) {
  final errors = <String>[];
  final normalized = path.replaceAll(r'\', '/');
  final name = normalized.split('/').last;
  final isExample = name.contains('.example') || name.contains('.sample');
  if (!isExample &&
      forbiddenFileSuffixes.any(
        (s) => name == s || name.endsWith(s) || name.startsWith('.env'),
      )) {
    errors.add('$normalized — 비밀 파일은 커밋하지 않는다');
  }
  if (content == null || normalized.startsWith('tool/')) return errors;
  for (final e in secretPatterns.entries) {
    final m = e.value.firstMatch(content);
    if (m != null) {
      final line = '\n'.allMatches(content.substring(0, m.start)).length + 1;
      errors.add('$normalized:$line — ${e.key} 모양 문자열');
    }
  }
  return errors;
}

Future<void> main(List<String> args) async {
  final staged = args.contains('--staged');
  final list = await Process.run(
    'git',
    staged
        ? ['diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z']
        : ['ls-files', '-z'],
  );
  if (list.exitCode != 0) {
    stderr.write(list.stderr);
    exitCode = 2;
    return;
  }
  final paths = (list.stdout as String)
      .split('\x00')
      .where((p) => p.isNotEmpty);
  final errors = <String>[];
  var count = 0;
  for (final path in paths) {
    count++;
    final file = File(path);
    String? content;
    if (file.existsSync() && file.lengthSync() < 2 * 1024 * 1024) {
      try {
        content = file.readAsStringSync();
      } on FileSystemException {
        content = null; // 바이너리
      }
    }
    errors.addAll(checkSecrets(path, content));
  }
  if (errors.isEmpty) {
    stdout.writeln('secrets OK ($count files)');
    return;
  }
  stderr.writeln('비밀 정보 의심 ${errors.length}건. 커밋에서 빼고 키를 새로 발급한다:');
  for (final e in errors) {
    stderr.writeln('  - $e');
  }
  exitCode = 1;
}
