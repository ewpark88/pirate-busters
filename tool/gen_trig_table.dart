// 정수 sin 테이블 생성기 (개발 계획서 M1). 결정론 패키지 밖이라 dart:math 를 쓴다.
// 사용법: dart run tool/gen_trig_table.dart
// 결과: packages/pb_sim/lib/src/math/trig_table.dart (0~90°, 0.25° 간격, ×1,000,000)
import 'dart:io';
import 'dart:math' as math;

const int _steps = 360; // 90° ÷ 0.25°
const int _perLine = 10;

void main() {
  final values = [
    for (var i = 0; i <= _steps; i++)
      (math.sin(i * math.pi / (_steps * 2)) * 1000000).round(),
  ];
  final out = StringBuffer()
    ..writeln('// 생성 파일 — tool/gen_trig_table.dart 로 다시 만든다. 직접 고치지 않는다.')
    ..writeln()
    ..writeln('/// sin(i × 0.25°) × 1,000,000 (i = 0..360, 0°~90°).')
    ..writeln('// dart format off')
    ..writeln('const List<int> sinQuarterTable = [');
  for (var i = 0; i < values.length; i += _perLine) {
    final end = i + _perLine < values.length ? i + _perLine : values.length;
    out.writeln('  ${values.sublist(i, end).join(', ')},');
  }
  out
    ..writeln('];')
    ..writeln('// dart format on');
  File(
    'packages/pb_sim/lib/src/math/trig_table.dart',
  ).writeAsStringSync(out.toString());
  stdout.writeln('trig_table.dart: ${values.length} entries');
}
