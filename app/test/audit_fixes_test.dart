import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/shipyard/blueprint_preview.dart';
import 'package:pirate_busters/shipyard/ship_grid_editor.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';

import 'test_catalog.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: const [Locale('ko'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  group('A25 점검 후속 (A38)', () {
    test('시간 판정으로 끝난 판도 사용 턴은 최대 턴을 넘지 않는다', () {
      final m = BattleSetup(testCatalog).newMatch(3);
      while (!m.state.isOver) {
        m.apply(const EndTurnCommand(t: 10));
      }
      expect(m.state.turn, greaterThan(m.state.rules.maxTurns));
      final s = MatchSummary.fromState(m.state, 0);
      expect(s.turns, m.state.rules.maxTurns);
    });

    test('굵은 제목 글꼴은 외곽선이 글자 크기의 12% 를 넘지 않는다', () {
      const title = OutlinedText(
        '캠페인',
        size: 22,
        font: AppFonts.display,
        stroke: 4,
      );
      expect(title.strokeWidth, closeTo(2.64, 0.01));
      const body = OutlinedText('글자', stroke: 4);
      expect(body.strokeWidth, 4, reason: '둥근 본문 글꼴은 그대로');
    });

    testWidgets('알림 글자는 Material 안에 있어 겹밑줄이 없다', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showPbToast(context, '저장했다'),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump(const Duration(milliseconds: 100));
      final text = find.text('저장했다');
      expect(text, findsWidgets);
      expect(
        find.ancestor(of: text.first, matching: find.byType(Material)),
        findsWidgets,
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('결과 화면의 장식용 배 미리보기에는 격자선이 없다', (tester) async {
      final ship = testCatalog.preset('balanced').blueprint;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            height: 300,
            child: BlueprintPreview(blueprint: ship, bare: true),
          ),
        ),
      );
      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((p) => p.painter is ShipGridPainter);
      expect(painters, isEmpty);
    });
  });
}
