import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_stats.dart';
import 'package:pirate_busters/data/replay_store.dart';
import 'package:pirate_busters/platform/ads.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/platform/iap.dart';
import 'package:pirate_busters/platform/remote_values.dart';

import 'test_catalog.dart';

void main() {
  group('플랫폼 인터페이스 (개발 계획서 M7)', () {
    test('기본 구현은 아무것도 하지 않고 광고·결제는 없다고 답한다', () async {
      const NoopAnalytics().log(Events.matchStart, {'x': 1});
      expect(const NoAds().available, isFalse);
      expect(await const NoAds().show(AdPlacements.doubleReward), isFalse);
      expect(const NoIap().available, isFalse);
      expect(await const NoIap().buyRemoveAds(), isFalse);
      expect(const EmptyRemoteValues().intOr('turn_maxTurns'), isNull);
    });

    test('기록 구현은 이벤트 이름과 파라미터를 남긴다', () {
      final a = MemoryAnalytics()..log(Events.stageClear, {'stage': '1-1'});
      expect(a.names, [Events.stageClear]);
      expect(a.events.single.params, {'stage': '1-1'});
      final iap = FakeIap();
      expect(iap.adsRemoved, isFalse);
    });
  });

  group('원격 설정으로 규칙 덮어쓰기 (설계서 §7.4)', () {
    test('접두사 + 규칙 필드 이름으로 정수 값을 바꾼다', () {
      final rules = applyRemoteRules(
        const MatchRules(),
        MemoryRemoteValues({'turn_maxTurns': 20, 'fuel_fuelPerTurn': 40}),
      );
      expect(rules.maxTurns, 20);
      expect(rules.fuelPerTurn, 40);
      expect(rules.firesPerTurn, const MatchRules().firesPerTurn);
    });

    test('값이 없으면 기본 규칙 그대로, 범위 밖 값이면 기본 규칙으로 돌아간다', () {
      const base = MatchRules();
      expect(applyRemoteRules(base, const EmptyRemoteValues()), same(base));
      expect(
        applyRemoteRules(base, MemoryRemoteValues({'turn_maxTurns': -1})),
        same(base),
      );
    });
  });

  group('전투 통계 (설계서 §13.5)', () {
    test('발사·명중·해적 피해·부순 블록을 공격자 기준으로 센다', () {
      final s = BattleStats()
        ..record(const SimEvent(SimEventKind.fire, side: 0, slot: 0))
        ..record(const SimEvent(SimEventKind.fire, side: 0, slot: 1))
        ..record(const SimEvent(SimEventKind.impact, side: 1, cell: 3))
        ..record(const SimEvent(SimEventKind.pirateHit, side: 1, value: 80))
        ..record(const SimEvent(SimEventKind.blockDestroyed, side: 1, cell: 3))
        ..record(const SimEvent(SimEventKind.fire, side: 1, slot: 0));
      expect(s.shots, [2, 1]);
      expect(s.hits, [1, 0]);
      expect(s.pirateDamage, [80, 0]);
      expect(s.blocksDestroyed, [1, 0]);
      expect(s.hitPercent(0), 50);
      expect(s.hitPercent(1), 0);
    });
  });

  group('리플레이 저장 (설계서 §7.2, §13.5)', () {
    test('스테이지 판의 리플레이를 만들어 저장하고 다시 읽는다', () async {
      final prepared = testSetup.prepareStage(11, testCampaign.stage('1-1'));
      prepared.match.apply(const EndTurnCommand(t: 100));
      final replay = prepared.replay();
      expect(replay.seed, 11);
      expect(replay.turns, hasLength(1));
      final store = MemoryReplayStore();
      await store.save('1-1-a', replay);
      expect(store.names, ['1-1-a']);
      expect(store.load('1-1-a')!.seed, 11);
      expect(store.load('none'), isNull);
    });

    test('원격 규칙을 적용한 판은 그 규칙으로 시작한다', () {
      final prepared = testSetup.prepareStage(
        1,
        testCampaign.stage('1-1'),
        tune: (r) =>
            applyRemoteRules(r, MemoryRemoteValues({'turn_maxTurns': 10})),
      );
      expect(prepared.match.state.rules.maxTurns, 10);
      expect(prepared.replay().rules.maxTurns, 10);
    });
  });
}
