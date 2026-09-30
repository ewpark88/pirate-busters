// 한국어·영어 다국어 검사기 (설계서 §14, CLAUDE.md 절대 규칙 10, ADR-015).
// 사용법: dart run tool/check_l10n.dart
// 1) app/lib/l10n/app_ko.arb 와 app_en.arb 의 메시지 키·플레이스홀더가 다르면 exit 1.
// 2) app/lib 코드에 화면 문장을 직접 쓰면(한글 문자열, Text('영어 문장')) exit 1
//    (개발 계획서 M4, 설계서 §14.5). 로그·오류 메시지·주석은 빼고 본다.
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

final _stringRe = RegExp(r'''('(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")''');
final _hangulRe = RegExp('[가-힣]');
final _sentenceRe = RegExp(r'[A-Za-z]{2,}\s+[A-Za-z]{2,}');

/// 화면 문장이 아니라 로그·오류라서 봐 주는 줄.
const _allowedMarkers = [
  'debugPrint(',
  'print(',
  'throw ',
  'Error(',
  'Exception(',
  'assert(',
];

/// Dart [source] 에서 화면에 보일 문장을 직접 쓴 곳을 찾는다 ([path] 는 표시용).
List<String> findHardcodedText(String path, String source) {
  final errors = <String>[];
  final lines = const LineSplitter().convert(source);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('//')) continue;
    final code = _stripComment(line);
    if (_allowedMarkers.any(code.contains)) continue;
    for (final m in _stringRe.allMatches(code)) {
      final lit = m.group(0)!;
      final inText = code.substring(0, m.start).trimRight().endsWith('Text(');
      if (_hangulRe.hasMatch(lit) || (inText && _sentenceRe.hasMatch(lit))) {
        errors.add('$path:${i + 1} 문장을 직접 썼다: $lit → ARB 키로 옮긴다');
      }
    }
  }
  return errors;
}

/// 줄 끝 `//` 주석을 뗀다(문자열 안의 // 는 둔다).
String _stripComment(String line) {
  var quote = '';
  for (var i = 0; i < line.length - 1; i++) {
    final c = line[i];
    if (quote.isNotEmpty) {
      if (c == r'\') {
        i++;
      } else if (c == quote) {
        quote = '';
      }
    } else if (c == "'" || c == '"') {
      quote = c;
    } else if (c == '/' && line[i + 1] == '/') {
      return line.substring(0, i);
    }
  }
  return line;
}

List<String> _scanApp() {
  final dir = Directory('app/lib');
  if (!dir.existsSync()) return const [];
  final files =
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final errors = <String>[];
  for (final f in files) {
    final path = f.path.replaceAll(r'\', '/');
    if (path.contains('/lib/l10n/')) continue;
    errors.addAll(findHardcodedText(path, f.readAsStringSync()));
  }
  return errors;
}

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
  final errors = [...compareArb(maps['ko']!, maps['en']!), ..._scanApp()];
  if (errors.isEmpty) {
    stdout.writeln('l10n OK (${maps['ko']!.length} entries, 직접 쓴 문장 없음)');
    return;
  }
  stderr.writeln('다국어 위반 ${errors.length}건 (설계서 §14):');
  for (final e in errors) {
    stderr.writeln('  - $e');
  }
  exitCode = 1;
}
