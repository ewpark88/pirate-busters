// 게임 데이터 글자 키 조회 표 생성기 (설계서 §14.3, 개발 계획서 M5).
// 데이터 JSON 에는 글자 대신 문자열 키만 있고(`pirate_p01_name` 등), gen-l10n 은
// 키 문자열로 글자를 찾지 못한다. 영어 템플릿 ARB 에서 데이터 접두사 키를 모아
// 키 → getter 표를 만든다.
// 사용법: dart run tool/gen_data_text.dart
// 결과: app/lib/l10n/data_text.dart
import 'dart:convert';
import 'dart:io';

const List<String> _prefixes = [
  'pirate_',
  'blueprint_',
  'mission_',
  'story_',
  'sea_',
  'gimmick_',
  'personality_',
];

void main() {
  final arb =
      jsonDecode(File('app/lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, Object?>;
  // 자리표시자가 있는 키(`{n}`)는 getter 가 아니라 함수라 표에 넣지 않는다.
  final keys = [
    for (final e in arb.entries)
      if (_prefixes.any(e.key.startsWith) &&
          e.value is String &&
          !(e.value! as String).contains('{'))
        e.key,
  ]..sort();
  final out = StringBuffer()
    ..writeln('// 생성 파일 — tool/gen_data_text.dart 로 다시 만든다. 직접 고치지 않는다.')
    ..writeln("import 'package:pirate_busters/l10n/app_localizations.dart';")
    ..writeln()
    ..writeln('/// 데이터 글자 키([key])의 지금 언어 글자. 없는 키면 키 그대로.')
    ..writeln('String dataText(AppLocalizations l10n, String key) =>')
    ..writeln('    switch (key) {');
  for (final k in keys) {
    out.writeln("      '$k' => l10n.$k,");
  }
  out
    ..writeln('      _ => key,')
    ..writeln('    };');
  File('app/lib/l10n/data_text.dart').writeAsStringSync(out.toString());
  stdout.writeln('data_text.dart: ${keys.length} keys');
}
