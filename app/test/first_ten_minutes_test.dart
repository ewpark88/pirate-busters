import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';
import 'package:pirate_busters/port/port_goal_card.dart';
import 'package:pirate_busters/ui/hud/tutorial_finger.dart';

import 'test_catalog.dart';

BattleSession _tutorial(int step) => BattleSession(
  BattleSetup(testCatalog).newStageMatch(3, testCampaign.stage('t-$step')),
  humanSides: const {0, 1},
  speciesOf: testCatalog.speciesOf,
);

void main() {
  group('첫 10분 (설계서 §13.1~§13.3)', () {
    test('첫 판 적 배는 기둥 하나를 맞히면 위 갑판이 통째로 무너진다', () {
      final b = testCampaign.stage('t-1').enemyBlueprint!;
      final ship = SideState(
        side: 1,
        blueprint: b,
        lineup: [testCatalog.pirates.byId('p16_suri')],
        rules: const MatchRules(),
      );
      final events = <SimEvent>[];
      resolveImpact(
        ship,
        spec: testCatalog.pirates.byId('p01_octo'),
        cx: 2,
        cy: 2,
        x: 0,
        y: 0,
        events: events,
        rng: XorShift32(1),
      );
      final collapsed = events.where(
        (e) => e.kind == SimEventKind.blockCollapsed,
      );
      expect(collapsed.length, greaterThanOrEqualTo(6));
    });

    test('손가락 안내: 카드 누르기 → 당기기, 튜토리얼 2 는 이동부터', () {
      final s1 = _tutorial(1);
      expect(TutorialFinger.cueOf(s1, 1), FingerCue.tapCard);
      s1.selected = 0;
      expect(TutorialFinger.cueOf(s1, 1), FingerCue.pullBack);
      s1.state.sides[s1.activeSide].shotsFired = 1;
      expect(TutorialFinger.cueOf(s1, 1), isNull, reason: '한 번 쏘면 끝');
      final s2 = _tutorial(2);
      expect(TutorialFinger.cueOf(s2, 2), FingerCue.move);
      s2.state.sides[s2.activeSide].offset = 1000;
      expect(TutorialFinger.cueOf(s2, 2), FingerCue.tapCard);
    });

    test('다음 목표: 튜토리얼을 끝냈으면 안 깬 첫 지도 스테이지, 배 확장 안내', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      const fresh = PlayerProgress();
      expect(PortGoalCard.nextStage(testCampaign, fresh, 1)!.id, 't-1');
      const after = PlayerProgress(tutorialDone: 3, stars: {'1-1': 2});
      expect(PortGoalCard.nextStage(testCampaign, after, 1)!.id, '1-2');
      expect(
        PortGoalCard.shipLine(l10n, testCampaign, after),
        l10n.goalShipNeed('1-4'),
      );
      const ready = PlayerProgress(
        tutorialDone: 3,
        stars: {'1-1': 1, '1-2': 1, '1-3': 1, '1-4': 1},
      );
      expect(
        PortGoalCard.shipLine(l10n, testCampaign, ready),
        l10n.shipGrowReady,
      );
      const grown = PlayerProgress(ship: ShipUpgrades(stage: 4));
      expect(
        PortGoalCard.shipLine(l10n, testCampaign, grown),
        l10n.goalShipDone,
      );
    });
  });
}
