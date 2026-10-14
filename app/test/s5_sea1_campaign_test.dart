import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/campaign_map_screen.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/meta/progress.dart';

import 'test_catalog.dart';

/// 한 스테이지를 이길 때까지 두는 판 수 상한.
const int _maxTries = 10;

/// 해역 1 을 튜토리얼부터 1-12 까지 앱과 같은 경로로 둔다 (계획서 0장 S3 완료 조건
/// ‘해역 1 을 처음부터 끝까지 할 수 있다’, S5 준비). 판은 `prepareStage` 로 열고(배는
/// 처음 진행의 기본 설계도, 덱은 시작 덱 + 합류한 해적, 코스트 한도는 레벨), 플레이어
/// 쪽은 손에 익은 사람 대신 어려움 AI 가 둔다(난이도 곡선 측정은 ADR-114 보강). 판이 끝나면 별 판정·보상(`applyStageResult`)을 진행에 반영하고,
/// 다음 스테이지가 열리는지 본다. [seedBase] 마다 시드가 다르다.
({PlayerProgress progress, int matches, List<String> log}) _playSea1(
  int seedBase,
) {
  final sea = testCampaign.sea(1);
  final campaign = sea.campaign;
  var progress = const PlayerProgress();
  var matches = 0;
  final log = <String>[];
  final blueprint = progress.ship.unlockedOnly(
    testCatalog.preset(BattleSetup.defaultPreset).blueprint,
  );
  for (final stage in [...sea.tutorial, ...campaign]) {
    final index = campaign.indexOf(stage);
    if (index >= 0) {
      expect(
        CampaignMapScreen.unlocked(campaign, index, progress),
        isTrue,
        reason: '${stage.id} 가 앞 스테이지를 깬 뒤 열리지 않았다',
      );
    }
    var won = false;
    for (var t = 0; t < _maxTries && !won; t++) {
      final seed = seedBase * 1000 + matches;
      matches++;
      final match = testSetup
          .prepareStage(
            seed,
            stage,
            blueprint: blueprint,
            deck: [...BattleSetup.starterDeck, ...progress.ownedPirates],
            costLimit: progress.costLimit,
          )
          .match;
      runMatch(
        match,
        const AiController(level: AiLevel.hard),
        AiController(level: stage.aiLevel, personality: stage.personality),
      );
      expect(match.isOver, isTrue, reason: '${stage.id} seed $seed 가 안 끝남');
      final summary = MatchSummary.fromState(match.state, 0);
      final stars = const StarRules().evaluate(stage, summary);
      expect(stars.won, summary.won);
      expect(stars.count, inInclusiveRange(summary.won ? 1 : 0, 3));
      final before = progress;
      final r = applyStageResult(progress, stage, stars);
      progress = r.progress;
      expect(progress.matchesPlayed, before.matchesPlayed + 1);
      expect(progress.xp + progress.level, isNot(before.xp + before.level));
      won = summary.won;
      if (won) {
        expect(progress.hasCleared(stage.id), isTrue);
        expect(progress.starsOf(stage.id), stars.count);
        if (r.reward.firstClear) {
          expect(r.reward.gold, stage.rewardGold, reason: stage.id);
        }
        final pirate = stage.rewardPirate;
        if (pirate != null) {
          expect(progress.ownedPirates, contains(pirate), reason: stage.id);
        }
        if (stage.kind == StageKind.tutorial) {
          expect(
            progress.tutorialDone,
            greaterThanOrEqualTo(stage.tutorialStep),
          );
        }
      }
      log.add(
        '${stage.id} seed $seed ${match.state.outcome.name} '
        '${summary.won ? '승' : '패'} 별 ${stars.count} 턴 ${summary.turns}',
      );
    }
    expect(won, isTrue, reason: '${stage.id} 를 $_maxTries 판 안에 못 이김\n$log');
  }
  return (progress: progress, matches: matches, log: log);
}

void main() {
  for (final base in const [1, 2, 3]) {
    test(
      '해역 1 을 튜토리얼부터 1-12 까지 앱 경로로 끝까지 깨고 별·보상·다음 스테이지가 맞다 (시드 묶음 $base)',
      () {
        final (:progress, :matches, :log) = _playSea1(base);
        final sea = testCampaign.sea(1);
        // 튜토리얼 3판 + 캠페인 12판 (설계서 §6.1).
        expect(sea.stages.length, 15);
        for (final s in sea.stages) {
          expect(progress.hasCleared(s.id), isTrue, reason: s.id);
        }
        expect(progress.level, greaterThan(1));
        expect(progress.gold, greaterThan(0));
        expect(progress.tutorialFinished, isTrue);
        // 어떤 판이 몇 번 만에 깼는지 남긴다(S5 점검 참고).
        // ignore: avoid_print
        print('시드 묶음 $base: $matches판\n${log.join('\n')}');
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );
  }
}
