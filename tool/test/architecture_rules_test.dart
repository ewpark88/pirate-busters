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
}
