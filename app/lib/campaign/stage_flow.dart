import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_stats.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/campaign/stage_result_screen.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/battle_screen.dart';

/// 스테이지 한 판의 흐름: 전투 → 끝나면 별·보상을 진행에 반영 → 결과 화면 (설계서 §13.5).
abstract final class StageFlow {
  /// 판 시드. 앱 층이라 시계를 써도 된다(판정은 시드로만 정해진다, §7.1).
  static int newSeed() => DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  /// [stage] 전투 화면을 연다. 끝나면 결과 화면으로 바꿔 끼운다.
  static Future<void> play(
    BuildContext context,
    WidgetRef ref,
    StageSpec stage, {
    int? seed,
  }) {
    final navigator = Navigator.of(context);
    final matchSeed = seed ?? newSeed();
    final startedAt = DateTime.now();
    ref.read(analyticsProvider).log(Events.matchStart, {
      'stage': stage.id,
      'seed': matchSeed,
    });
    return navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          seed: matchSeed,
          stage: stage,
          onOver: (state, replay, stats) =>
              _finish(navigator, ref, stage, state, replay, stats, startedAt),
        ),
      ),
    );
  }

  static Future<void> _finish(
    NavigatorState navigator,
    WidgetRef ref,
    StageSpec stage,
    MatchState state,
    Replay? replay,
    BattleStats stats,
    DateTime startedAt,
  ) async {
    final mine = MatchSummary.fromState(
      state,
      0,
      hits: stats.hits[0],
      damageDealt: stats.pirateDamage[0],
      blocksDestroyed: stats.blocksDestroyed[0],
    );
    final enemyFlood = state.sides[1].flood * 100 ~/ fullFlood;
    final stars = const StarRules().evaluate(stage, mine);
    late StageReward reward;
    await ref.read(progressProvider.notifier).update((p) {
      final r = applyStageResult(p, stage, stars);
      reward = r.reward;
      return r.progress;
    });
    final analytics = ref.read(analyticsProvider);
    final progressNow = ref.read(progressProvider);
    analytics.log(Events.matchEnd, {
      'stage': stage.id,
      'won': mine.won,
      'outcome': state.outcome.name,
      'turns': mine.turns,
      'seconds': DateTime.now().difference(startedAt).inSeconds,
    });
    if (progressNow.matchesPlayed == 1) {
      analytics.log(Events.firstMatchComplete);
    }
    if (reward.firstClear) {
      analytics.log(Events.stageClear, {'stage': stage.id});
    }
    // 보스를 이기면 결과 앞에 뒤 컷신 (설계서 §15.4). 한 번만.
    final after = StoryData.bossAfter(stage.id);
    final cuts = StoryData.of(after);
    if (mine.won && stage.isBoss && cuts != null) {
      final progress = ref.read(progressProvider);
      if (!progress.hasSeen(after)) {
        await ref
            .read(progressProvider.notifier)
            .update((p) => p.seeStory(after));
        await navigator.pushReplacement(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => CutsceneScreen(cuts: cuts),
          ),
        );
      }
    }
    await navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => StageResultScreen(
          stage: stage,
          summary: mine,
          enemyFloodPercent: enemyFlood,
          reward: reward,
          replay: replay,
        ),
      ),
    );
  }
}
