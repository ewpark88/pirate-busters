import 'package:test/test.dart';

import '../architecture/rules.dart';

void main() {
  group('메타 화면 기본 위젯 금지 (설계서 §13 공통, 계획서 A16)', () {
    test('메타 화면 폴더에서 기본 상단 바·대화상자·시스템 아이콘을 찾는다', () {
      const src = '''
Widget build() => Scaffold(
  appBar: AppBar(title: Text(t)),
  body: IconButton(icon: Icon(Icons.lock), onPressed: f),
);
''';
      final v = checkFile('app/lib/port/x_screen.dart', src);
      expect(v.where((e) => e.contains('메타 화면')), hasLength(3));
    });

    test('키트 위젯과 주석·문자열 속 이름은 봐 준다', () {
      const src = '''
// AppBar 대신 PbScaffold 를 쓴다.
Widget build() => PbScaffold(title: 'AppBar', body: PbButton(label: l));
''';
      expect(checkFile('app/lib/campaign/y.dart', src), isEmpty);
    });

    test('전투 HUD 본체와 개발 화면은 대상이 아니다', () {
      const src = 'Widget b() => FilledButton(onPressed: f, child: c);';
      expect(checkFile('app/lib/ui/hud/battle_hud.dart', src), isEmpty);
      expect(checkFile('app/lib/dev/test_battle_screen.dart', src), isEmpty);
    });
  });

  group('lib 300줄 규칙과 줄 수 예외 (절대 규칙 9, ADR-107)', () {
    String file(int lines, {String head = ''}) =>
        head +
        List.filled(lines - (head.isEmpty ? 0 : 1), 'var a = 1;').join('\n');
    const reason = '// 줄 수 예외: 탄종 분기 switch 하나라 나누면 흐름이 끊긴다\n';
    List<String> length(String src) =>
        checkFile('app/lib/x.dart', src).where((v) => v.contains('줄')).toList();

    test('표시 없이 300줄을 넘으면 위반이고 예외 방법을 알려 준다', () {
      expect(length(file(300)), isEmpty);
      final v = length(file(301));
      expect(v, hasLength(1));
      expect(v.single, contains('줄 수 예외'));
    });

    test('이유를 적은 예외 표시가 있으면 450줄까지 통과한다', () {
      expect(length(file(450, head: reason)), isEmpty);
      expect(length(file(451, head: reason)), hasLength(1));
    });

    test('이유가 짧거나 300줄 이하인 파일의 예외 표시는 위반이다', () {
      expect(length(file(320, head: '// 줄 수 예외: 길다\n')), hasLength(1));
      expect(length(file(200, head: reason)), hasLength(1));
    });

    test('예외 표시는 파일 머리 20줄 안에서만 찾는다', () {
      expect(lineExceptionReason(reason), startsWith('탄종'));
      final late = '${List.filled(20, '').join('\n')}\n$reason';
      expect(lineExceptionReason(late), isNull);
    });

    test('lib 밖 파일과 gen-l10n 생성 파일은 줄 수를 보지 않는다', () {
      expect(checkFile('app/test/x_test.dart', file(500)), isEmpty);
      expect(
        checkFile('app/lib/l10n/app_localizations_ko.dart', file(500)),
        isEmpty,
      );
    });
  });
}
