import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/meta/progress.dart';
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
      );
      final collapsed = events.where(
        (e) => e.kind == SimEventKind.blockCollapsed,
      );
      expect(collapsed.length, greaterThanOrEqualTo(6));
    });

    test('손가락 안내: 카드 누르기 → 당기기, 튜토리얼 2·3 은 이동부터', () {
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
      final s3 = _tutorial(3);
      expect(TutorialFinger.cueOf(s3, 3), FingerCue.move, reason: '파도 구간');
    });

    test('튜토리얼 2 는 잔잔한 바다에 바람, 3 은 파도 구간이 있다 (설계서 §13.1)', () {
      final t2 = testCampaign.sea(1).stages[1];
      final t3 = testCampaign.sea(1).stages[2];
      expect((t2.tutorialStep, t2.calmSea), (2, true));
      expect(t2.maxWind, greaterThan(0));
      expect((t3.tutorialStep, t3.calmSea), (3, false));
    });

    test('당기기 안내는 해적 몸에서 시작해 뒤·아래로 뻗는다', () {
      const body = Offset(300, 200);
      final (from, to) = TutorialFinger.pullPath(body, 1);
      expect(from, body);
      expect(to.dx, lessThan(body.dx), reason: '오른쪽을 보는 배는 왼쪽이 뒤');
      expect(to.dy, greaterThan(body.dy));
      final (_, back) = TutorialFinger.pullPath(body, -1);
      expect(back.dx, greaterThan(body.dx));
    });

    test('카메라 기본 화면은 지금 턴 배, 판이 끝나면 보는 사람 배', () {
      final s = _tutorial(1).state;
      final first = s.activeSide;
      expect(CameraDirector.anchorSide(s, 0), first);
      s.turn += 1;
      expect(CameraDirector.anchorSide(s, 0), 1 - first, reason: '상대 턴');
      s.outcome = MatchOutcome.surrender;
      expect(CameraDirector.anchorSide(s, 0), 0);
    });

    test('다음 목표: 튜토리얼을 끝냈으면 안 깬 첫 지도 스테이지', () {
      const fresh = PlayerProgress();
      expect(PortGoalCard.nextStage(testCampaign, fresh, 1)!.id, 't-1');
      const after = PlayerProgress(tutorialDone: 3, stars: {'1-1': 2});
      expect(PortGoalCard.nextStage(testCampaign, after, 1)!.id, '1-2');
    });
  });
}
