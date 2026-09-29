// 한국어·영어 ARB 짝 검사기 (설계서 §14, CLAUDE.md 절대 규칙 10, ADR-015).
// 사용법: dart run tool/check_l10n.dart
// app/lib/l10n/app_ko.arb 와 app_en.arb 의 메시지 키·플레이스홀더가 다르면 exit 1.
// l10n 디렉터리가 아직 없으면(M4 이전) 통과한다.
import 'dart:convert';
import 'dart:io';

const l10nDir = 'app/lib/l10n';
const locales = ['ko', 'en'];

final _placeholderRe = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)');

/// 두 ARB 맵을 비교해 위반 목록을 돌려준다. `@` 로 시작하는 메타 키는 비교하지 않는다.
List<String> compareArb(Map<String, dynamic> ko, Map<String, dynamic> en) {
  Set<String> keys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@')).toSet();
  final errors = <String>[];
  final koKeys = keys(ko);
  final enKeys = keys(en);
  for (final k in (koKeys.difference(enKeys).toList()..sort())) {
    errors.add('app_en.arb 에 `$k` 가 없다');
  }
  for (final k in (enKeys.difference(koKeys).toList()..sort())) {
    errors.add('app_ko.arb 에 `$k` 가 없다');
  }
  for (final k in (koKeys.intersection(enKeys).toList()..sort())) {
    final a = _placeholders(ko[k]);
    final b = _placeholders(en[k]);
    if (a.length != b.length || !a.containsAll(b)) {
      errors.add('`$k` 플레이스홀더가 다르다: ko $a, en $b');
    }
    if ('${ko[k]}'.trim().isEmpty || '${en[k]}'.trim().isEmpty) {
      errors.add('`$k` 값이 비어 있다');
    }
  }
  return errors;
}

Set<String> _placeholders(Object? value) =>
    _placeholderRe.allMatches('$value').map((m) => m.group(1)!).toSet();

void main() {
  if (!Directory(l10nDir).existsSync()) {
    stdout.writeln('l10n OK (아직 $l10nDir 없음)');
    return;
  }
  final maps = <String, Map<String, dynamic>>{};
  for (final loc in locales) {
    final file = File('$l10nDir/app_$loc.arb');
    if (!file.existsSync()) {
      stderr.writeln('${file.path} 가 없다. 두 언어 파일을 같이 만든다 (설계서 §14)');
      exitCode = 1;
      return;
    }
    maps[loc] = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
  final errors = compareArb(maps['ko']!, maps['en']!);
  if (errors.isEmpty) {
    stdout.writeln('l10n OK (${maps['ko']!.length} entries)');
    return;
  }
  stderr.writeln('ARB 짝 위반 ${errors.length}건 (설계서 §14):');
  for (final e in errors) {
    stderr.writeln('  - $e');
  }
  exitCode = 1;
}
