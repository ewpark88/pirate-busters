import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/boss_banner.dart';

import 'test_catalog.dart';

void main() {
  group('해역 1 보스 기믹 (설계서 §5.4)', () {
    test('1-5 는 뱃머리 방패, 1-12 는 다가오는 초계선이 상대 쪽 규칙에 걸린다', () {
      final setup = BattleSetup(testCatalog);
      final shield = setup.newStageMatch(3, testCampaign.stage('1-5'));
      expect(shield.state.rules.gimmick, BossGimmick.bowIronShield.index);
      expect(shield.state.rules.gimmickSide, 1);
      expect(shield.state.sides[1].shieldCells, isNotEmpty);
      expect(shield.state.sides[0].shieldCells, isEmpty);
      final patrol = setup.newStageMatch(3, testCampaign.stage('1-12'));
      expect(patrol.state.rules.gimmick, BossGimmick.patrolClosingIn.index);
      final normal = setup.newStageMatch(3, testCampaign.stage('1-3'));
      expect(normal.state.rules.gimmick, 0);
    });

    testWidgets('보스 배너는 기믹 한 줄을 띄웠다가 사라진다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ko'),
          supportedLocales: [Locale('ko'), Locale('en')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: BossBanner(gimmick: 'bow_iron_shield')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final l10n = AppLocalizations.of(tester.element(find.byType(BossBanner)));
      expect(find.text(l10n.bossBanner), findsOneWidget);
      expect(find.text(l10n.gimmick_bow_iron_shield), findsOneWidget);
      await tester.pump(BossBanner.shown);
      await tester.pumpAndSettle();
      final fade = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(fade.opacity, 0);
    });
  });
}
