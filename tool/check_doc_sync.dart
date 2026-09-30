// 기준 문서(설계서 + docs/BALANCE.md) ↔ 개발 계획서 동기화 검사기 (ADR-008, ADR-037).
// 사용법: dart run tool/check_doc_sync.dart
// 계획서 머리의 `기준 문서 동기화: <해시>` 가 두 기준 문서의 해시와 다르면 exit 1.
// 설계서나 BALANCE.md 가 바뀌면 계획서에 변경 내용을 반영한 뒤 표시를 새 해시로 고친다.
import 'dart:convert';
import 'dart:io';

const designPath = 'Pirate Busters 게임 설계서.md';
const balancePath = 'docs/BALANCE.md';
const planPath = 'Pirate Busters 개발 계획서.md';
final markerPattern = RegExp('기준 문서 동기화: `([0-9a-f]{8})`');

/// 줄바꿈을 LF 로 맞춘 문서들을 순서대로 이어 붙인 뒤 FNV-1a 32비트 해시.
/// 체크아웃 설정과 무관하게 같은 값이 나온다.
String docsHash(List<String> texts) {
  var hash = 0x811c9dc5;
  final joined = texts.map((t) => t.replaceAll('\r\n', '\n')).join('\n');
  for (final byte in utf8.encode(joined)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

void main() {
  final current = docsHash([
    File(designPath).readAsStringSync(),
    File(balancePath).readAsStringSync(),
  ]);
  final match = markerPattern.firstMatch(File(planPath).readAsStringSync());
  if (match == null) {
    stderr.writeln('$planPath 에 "기준 문서 동기화: `$current`" 표시가 없다.');
    exitCode = 1;
    return;
  }
  if (match.group(1) == current) {
    stdout.writeln('doc sync OK ($current)');
    return;
  }
  stderr
    ..writeln('설계서나 $balancePath 가 바뀌었는데 개발 계획서에 반영되지 않았다 (ADR-008, ADR-037).')
    ..writeln('  1. git diff 로 설계서·BALANCE.md 의 변경 절을 확인한다.')
    ..writeln('  2. 계획서의 해당 작업·완료 조건·§ 참조를 고친다.')
    ..writeln('  3. 계획서 표시를 "기준 문서 동기화: `$current`" 로 바꾼다.');
  exitCode = 1;
}
