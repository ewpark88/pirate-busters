import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/meta/progress.dart';

import 'test_catalog.dart';

void main() {
  final s12 = testCampaign.stage('1-2'); // 보상 골드 120, 수리 합류
  final t1 = testCampaign.stage('t-1');

  StarResult stars({
    bool won = true,
    bool inTurns = true,
    bool mission = false,
  }) => StarResult(won: won, inTurns: won && inTurns, mission: won && mission);

  group('스테이지 보상 (설계서 §4.5, §4.6, §6.1, BALANCE.md A4.5)', () {
    test('첫 클리어: 골드 전부, 경험치 30 + 20, 확정 해적 합류, 별 기록, 판 수 +1', () {
      final r = applyStageResult(
        const PlayerProgress(),
        s12,
        stars(mission: true),
      );
      expect(r.reward.gold, 120);
      expect(r.reward.xp, RewardRules.xpWin + RewardRules.xpFirstClear);
      expect(r.reward.firstClear, isTrue);
      expect(r.reward.newPirate, 'p16_suri');
      expect(r.progress.ownedPirates, contains('p16_suri'));
      expect(r.progress.starsOf('1-2'), 3);
      expect(r.progress.matchesPlayed, 1);
      expect(r.progress.gold, 120);
    });

    test('다시 깨면 골드는 절반, 첫 클리어 보너스와 해적은 없다', () {
      final first = applyStageResult(
        const PlayerProgress(),
        s12,
        stars(),
      ).progress;
      final r = applyStageResult(first, s12, stars(inTurns: false));
      expect(r.reward.gold, 60);
      expect(r.reward.xp, RewardRules.xpWin);
      expect(r.reward.firstClear, isFalse);
      expect(r.reward.newPirate, isNull);
      expect(r.progress.starsOf('1-2'), 2, reason: '별은 최고치 유지');
    });

    test('지면 경험치 10 뿐이고 별·해적·골드는 없다', () {
      final r = applyStageResult(
        const PlayerProgress(),
        s12,
        stars(won: false),
      );
      expect(r.reward.gold, 0);
      expect(r.reward.xp, RewardRules.xpLoss);
      expect(r.progress.hasCleared('1-2'), isFalse);
      expect(r.progress.ownedPirates, isEmpty);
      expect(r.progress.matchesPlayed, 1);
    });

    test('튜토리얼을 이기면 튜토리얼 진행이 남는다', () {
      final r = applyStageResult(const PlayerProgress(), t1, stars());
      expect(r.progress.tutorialDone, 1);
      expect(r.reward.stars.count, 2);
    });

    test('경험치가 차면 레벨 업이 보상에 표시된다', () {
      final r = applyStageResult(const PlayerProgress(xp: 60), s12, stars());
      expect(r.reward.leveledUp, isTrue);
      expect(r.reward.levelAfter, 2);
    });
  });

  test('MatchOutcome 별 결과 요약은 승자 기준이다', () {
    final match = testSetup.newMatch(3);
    expect(MatchSummary.fromState(match.state, 1).won, isFalse);
  });
}
