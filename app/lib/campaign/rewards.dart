import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/meta/progress.dart';

/// 한 판이 끝난 뒤 받은 것 (설계서 §13.5 보상, §4.5 경험치, §4.6 확정 보상).
class StageReward {
  const StageReward({
    required this.gold,
    required this.xp,
    required this.firstClear,
    required this.newPirate,
    required this.levelBefore,
    required this.levelAfter,
    required this.stars,
  });

  final int gold;
  final int xp;
  final bool firstClear;

  /// 이번에 처음 합류한 해적 id. 없으면 null.
  final String? newPirate;
  final int levelBefore;
  final int levelAfter;
  final StarResult stars;

  bool get leveledUp => levelAfter > levelBefore;
}

/// 경험치 (수치: BALANCE.md A4.5). 승리 30, 패배·무승부 10, 캠페인 첫 클리어 +20.
abstract final class RewardRules {
  static const int xpWin = 30;
  static const int xpLoss = 10;
  static const int xpFirstClear = 20;

  /// 다시 깬 스테이지의 골드 비율(%). 첫 클리어는 전부 (임시값).
  static const int repeatGoldPercent = 50;
}

/// 판 결과를 진행에 반영한다. 순수 함수라 테스트하기 쉽다.
({PlayerProgress progress, StageReward reward}) applyStageResult(
  PlayerProgress progress,
  StageSpec stage,
  StarResult stars,
) {
  final won = stars.won;
  final firstClear = won && !progress.hasCleared(stage.id);
  final gold = !won
      ? 0
      : firstClear
      ? stage.rewardGold
      : stage.rewardGold * RewardRules.repeatGoldPercent ~/ 100;
  final xp =
      (won ? RewardRules.xpWin : RewardRules.xpLoss) +
      (firstClear ? RewardRules.xpFirstClear : 0);
  final pirate = stage.rewardPirate;
  final newPirate =
      won && pirate != null && !progress.ownedPirates.contains(pirate)
      ? pirate
      : null;

  var next = progress.countMatch().addXp(xp).addGold(gold);
  if (won) next = next.recordStage(stage.id, stars.count);
  if (newPirate != null) next = next.addPirate(newPirate);
  if (stage.kind == StageKind.tutorial && won) {
    next = next.finishTutorial(stage.tutorialStep);
  }
  return (
    progress: next,
    reward: StageReward(
      gold: gold,
      xp: xp,
      firstClear: firstClear,
      newPirate: newPirate,
      levelBefore: progress.level,
      levelAfter: next.level,
      stars: stars,
    ),
  );
}
