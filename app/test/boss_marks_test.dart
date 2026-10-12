import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/game/view/boss_mark.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/boss_banner.dart';
import 'package:pirate_busters/ui/hud/boss_vignette.dart';

import 'test_catalog.dart';

Widget _app(Widget child, {bool disableAnimations = false}) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: const [Locale('ko'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: child),
  ),
);

void main() {
  group('보스전 표시 (설계서 §13.4, ADR-096)', () {
    test('1-5·1-12 는 상대 진영이 보스이고 1-3 은 보스 판이 아니다', () {
      int? side(String id) => BossMark.sideFor(
        isBoss: testCampaign.stage(id).isBoss,
        humanSides: const {0},
      );
      expect(side('1-5'), 1);
      expect(side('1-12'), 1);
      expect(side('1-3'), isNull);
      expect(BossMark.sideFor(isBoss: true, humanSides: const {0, 1}), isNull);
    });

    test('왕관은 보스 진영 배에만, 판이 끝나기 전까지만 그린다', () {
      expect(BossMark.showsOn(1, bossSide: 1, over: false), isTrue);
      expect(BossMark.showsOn(0, bossSide: 1, over: false), isFalse);
      expect(BossMark.showsOn(1, bossSide: null, over: false), isFalse);
      expect(BossMark.showsOn(1, bossSide: 1, over: true), isFalse);
    });

    testWidgets('기믹 없는 보스도 배너가 뜨고 기믹 줄은 없다', (tester) async {
      await tester.pumpWidget(_app(const BossBanner()));
      await tester.pump(const Duration(milliseconds: 500));
      final l10n = AppLocalizations.of(tester.element(find.byType(BossBanner)));
      expect(find.text(l10n.bossBanner), findsOneWidget);
      expect(find.text(l10n.gimmick_bow_iron_shield), findsNothing);
      await tester.pump(BossBanner.shown);
      await tester.pumpAndSettle();
    });

    testWidgets('붉은 테는 터치를 막지 않는다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                ),
              ),
              const Positioned.fill(child: BossVignette()),
            ],
          ),
        ),
      );
      await tester.tapAt(const Offset(20, 20));
      expect(taps, 1);
    });

    testWidgets('움직임 줄이기면 붉은 테가 멈춘다', (tester) async {
      await tester.pumpWidget(_app(const BossVignette(calm: true)));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(
        _app(const BossVignette(), disableAnimations: true),
      );
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(_app(const BossVignette()));
      expect(tester.hasRunningAnimations, isTrue);
    });

    test('왕관 표식은 그림 없이 바닥 위쪽에 붉게 그린다', () async {
      final recorder = ui.PictureRecorder();
      BossMark.crown(Canvas(recorder), const Offset(50, 90), 60, 0);
      final image = await recorder.endRecording().toImage(100, 100);
      final data = (await image.toByteData())!;
      int alphaAt(int x, int y) => data.getUint8((y * 100 + x) * 4 + 3);
      int redAt(int x, int y) => data.getUint8((y * 100 + x) * 4);
      expect(alphaAt(50, 75), greaterThan(200));
      expect(redAt(50, 75), greaterThan(150));
      expect(alphaAt(2, 2), lessThan(30));
    });
  });
}
