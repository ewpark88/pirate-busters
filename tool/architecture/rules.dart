// 아키텍처·결정론 규칙. 개발 계획서 §2.1(의존 방향), §2.2(결정론 코딩 규칙).
// check_architecture.dart 가 파일마다 checkFile() 을 호출한다.

/// 워크스페이스 패키지 이름 → 소스 루트 경로(슬래시 구분, 워크스페이스 기준).
const Map<String, String> packageRoots = {
  'pb_sim': 'packages/pb_sim',
  'pb_ai': 'packages/pb_ai',
  'pb_data': 'packages/pb_data',
  'sim_runner': 'tools/sim_runner',
  'pirate_busters': 'app',
};

/// 패키지마다 import 해도 되는 워크스페이스 패키지.
const Map<String, Set<String>> allowedInternalDeps = {
  'pb_sim': {},
  'pb_ai': {'pb_sim'},
  'pb_data': {'pb_sim'},
  'sim_runner': {'pb_sim', 'pb_ai', 'pb_data'},
  'pirate_busters': {'pb_sim', 'pb_ai', 'pb_data'},
};

/// Flutter·플랫폼과 무관해야 하는 순수 Dart 패키지.
const Set<String> purePackages = {'pb_sim', 'pb_ai', 'pb_data'};

/// 결정론 규칙(§2.2)을 적용하는 패키지.
const Set<String> deterministicPackages = {'pb_sim', 'pb_ai'};

/// lib/ 파일 최대 줄 수.
const int maxLibLines = 300;

const List<String> _pureForbiddenImports = [
  'package:flutter/',
  'package:flame/',
  'dart:ui',
  'dart:io',
  'dart:html',
  'dart:isolate',
];

const List<String> _deterministicForbiddenImports = ['dart:math', 'dart:async'];

/// 결정론 패키지에서 금지하는 식별자와 그 이유.
const Map<String, String> _forbiddenIdentifiers = {
  'double': '부동소수점 금지 — ×1000 고정소수점 정수를 쓴다',
  'num': 'double 이 섞일 수 있는 num 금지 — int 를 쓴다',
  'toDouble': '부동소수점 변환 금지',
  'Random': 'Random 금지 — 매치 시드 xorshift32 를 쓴다',
  'DateTime': '실시간 시계 금지 — 틱 번호를 쓴다',
  'Stopwatch': '실시간 시계 금지 — 틱 번호를 쓴다',
  'identityHashCode': '실행마다 달라지는 해시 금지',
  'hashCode': '실행마다 달라질 수 있는 Object.hashCode 금지 — 상태 해시는 FNV-1a',
};

final RegExp _importRe = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);
final RegExp _identRe = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');
final RegExp _floatLiteralRe = RegExp(
  r'(?<![A-Za-z0-9_$.])(?:\d+(?:\.\d+[eE]?|[eE][+-]?\d)|\.\d)',
);

/// [relPath](워크스페이스 기준, 슬래시 구분) 파일의 위반 목록.
List<String> checkFile(String relPath, String source) {
  final pkg = packageOf(relPath);
  if (pkg == null) return const [];
  final violations = <String>[];
  final code = stripCommentsAndStrings(source);

  for (final m in _importRe.allMatches(source)) {
    final uri = m.group(1)!;
    final line = _lineOf(source, m.start);
    final target = _internalPackageOf(uri);
    if (target != null &&
        target != pkg &&
        !allowedInternalDeps[pkg]!.contains(target)) {
      violations.add('$relPath:$line — $pkg 는 $target 를 import 할 수 없다 ($uri)');
    }
    if (purePackages.contains(pkg) &&
        _pureForbiddenImports.any(uri.startsWith)) {
      violations.add('$relPath:$line — 순수 Dart 패키지에서 금지된 import ($uri)');
    }
    if (deterministicPackages.contains(pkg) &&
        _deterministicForbiddenImports.contains(uri)) {
      violations.add('$relPath:$line — 결정론 패키지에서 금지된 import ($uri)');
    }
  }

  if (deterministicPackages.contains(pkg)) {
    violations.addAll(_checkDeterminism(relPath, code));
  }

  final lines = '\n'.allMatches(source).length + 1;
  // gen-l10n 이 만드는 파일은 키 수만큼 길어진다 (ADR-029).
  final generated = relPath.contains('/lib/l10n/app_localizations');
  if (relPath.contains('/lib/') && !generated && lines > maxLibLines) {
    violations.add('$relPath — $lines 줄, lib 파일은 $maxLibLines 줄 이하');
  }
  return violations;
}

List<String> _checkDeterminism(String relPath, String code) {
  final out = <String>[];
  for (final m in _identRe.allMatches(code)) {
    final reason = _forbiddenIdentifiers[m.group(0)];
    if (reason != null) {
      out.add('$relPath:${_lineOf(code, m.start)} — `${m.group(0)}`: $reason');
    }
  }
  for (final m in _floatLiteralRe.allMatches(code)) {
    out.add('$relPath:${_lineOf(code, m.start)} — 실수 리터럴 `${m.group(0)}` 금지');
  }
  for (var i = 0; i < code.length; i++) {
    if (code[i] != '/') continue;
    final prev = i > 0 ? code[i - 1] : '';
    if (prev == '~') continue; // 정수 나눗셈 ~/ 와 ~/= 는 허용
    out.add('$relPath:${_lineOf(code, i)} — `/` 는 double 을 만든다. `~/` 를 쓴다');
  }
  return out;
}

/// 파일 경로가 속한 워크스페이스 패키지 이름. 검사 대상이 아니면 null.
String? packageOf(String relPath) {
  for (final e in packageRoots.entries) {
    if (relPath.startsWith('${e.value}/')) return e.key;
  }
  return null;
}

String? _internalPackageOf(String uri) {
  if (!uri.startsWith('package:')) return null;
  final name = uri.substring('package:'.length).split('/').first;
  return packageRoots.containsKey(name) ? name : null;
}

int _lineOf(String text, int offset) =>
    '\n'.allMatches(text.substring(0, offset)).length + 1;

/// 주석과 문자열 내용을 공백으로 바꾼다(줄바꿈은 유지해 줄 번호를 보존).
String stripCommentsAndStrings(String src) {
  final out = StringBuffer();
  var i = 0;
  void blank(int end) {
    for (; i < end && i < src.length; i++) {
      out.write(src[i] == '\n' ? '\n' : ' ');
    }
  }

  while (i < src.length) {
    if (src.startsWith('//', i)) {
      final end = src.indexOf('\n', i);
      blank(end < 0 ? src.length : end);
    } else if (src.startsWith('/*', i)) {
      final end = src.indexOf('*/', i + 2);
      blank(end < 0 ? src.length : end + 2);
    } else if (src[i] == "'" || src[i] == '"') {
      final raw = i > 0 && src[i - 1] == 'r';
      final quote = src.startsWith(src[i] * 3, i) ? src[i] * 3 : src[i];
      var j = i + quote.length;
      while (j < src.length && !src.startsWith(quote, j)) {
        j += (!raw && src[j] == r'\') ? 2 : 1;
      }
      blank(j + quote.length);
    } else {
      out.write(src[i]);
      i++;
    }
  }
  return out.toString();
}
