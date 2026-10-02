import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/result_hero.dart';
import 'package:pirate_busters/campaign/result_parts.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/campaign/stage_node.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/kit/pb_scaffold.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 결과 화면 (설계서 §13.5, §13 공통): 해역 그림 위에 승패·승리 방식(시간 판정이면 침수량 막대), 별 3개, 보상,
/// 전투 통계, 다시 하기·항구로. ‘광고 보고 2배’·리플레이 저장은 플랫폼 묶음에서 켠다.
class StageResultScreen extends ConsumerWidget {
  const StageResultScreen({
    required this.stage,
    required this.summary,
    required this.enemyFloodPercent,
    required this.reward,
    this.replay,
    super.key,
  });

  final StageSpec stage;
  final MatchSummary summary;
  final int enemyFloodPercent;
  final StageReward reward;

  /// 저장할 수 있는 리플레이 (설계서 §7.2). 없으면 버튼이 안 보인다.
  final Replay? replay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(gameCatalogProvider);
    // 승패·무승부는 pb_sim 의 판정을 그대로 쓴다 (설계서 §2.4, §13.5).
    final title = summary.won
        ? l10n.resultWin
        : summary.draw
        ? l10n.resultDraw
        : l10n.resultLose;
    final how = switch (summary.outcome) {
      MatchOutcome.sunk => l10n.outcomeSunk,
      MatchOutcome.floodSunk => l10n.outcomeFloodSunk,
      MatchOutcome.annihilation => l10n.outcomeAnnihilation,
      MatchOutcome.timeDecision => l10n.outcomeTimeDecision,
      MatchOutcome.surrender => l10n.outcomeSurrender,
      MatchOutcome.ongoing => '',
    };
    final missionText = _missionText(l10n, stage.mission);
    final banner = summary.won
        ? const Color(0xFFFFD45A)
        : summary.draw
        ? AppColors.text
        : const Color(0xFFE06A5A);
    // MVP 가 없으면(한 발도 못 맞힘) 덱 첫 해적이 나온다.
    final hero =
        summary.mvpPirate ??
        ref.watch(fleetStoreProvider).deck?.first ??
        BattleSetup.starterDeck.first;
    return PbScaffold(
      region: seaRegion(stage.sea),
      dim: 0.5,
      // 탭하면 연출을 건너뛴다 (설계서 §13.5).
      body: SkippableMotion(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              // 왼쪽: 승리면 MVP 해적, 패배면 젖은 해적과 기운 배 (설계서 §13.5).
              Expanded(
                flex: 3,
                child: PopIn(
                  order: 1,
                  child: ResultHero(
                    won: summary.won,
                    draw: summary.draw,
                    pirate: hero,
                  ),
                ),
              ),
              // 가운데: 승패 배너, 승리 방식, 별.
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PopIn(
                      child: FittedBox(
                        child: OutlinedText(
                          title,
                          size: 52,
                          color: banner,
                          font: AppFonts.display,
                          stroke: 7,
                        ),
                      ),
                    ),
                    OutlinedText(how, size: 18),
                    if (summary.outcome == MatchOutcome.timeDecision) ...[
                      const SizedBox(height: 6),
                      _floodBars(l10n),
                    ],
                    const SizedBox(height: 12),
                    _stars(l10n, missionText),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 오른쪽: 보상·통계·버튼.
              Expanded(
                flex: 4,
                child: Center(
                  child: PopIn(
                    order: 2,
                    child: PbPanel(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _rewards(l10n, catalog.def),
                            const SizedBox(height: 6),
                            Text(
                              '${l10n.statTurns(summary.turns)} · '
                              '${l10n.statShots(summary.shotsFired)} · '
                              '${l10n.statAccuracy(summary.hitPercent)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.mute,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              l10n.statDamage(
                                summary.damageDealt,
                                summary.blocksDestroyed,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.mute,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ResultActions(
                              stage: stage,
                              reward: reward,
                              replay: replay,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _missionText(AppLocalizations l10n, MissionSpec m) =>
      switch (m.type) {
        'flood_below' => l10n.mission_flood_below(m.param('percent')),
        'hull_above' => l10n.mission_hull_above(m.param('percent')),
        'turns_within' => l10n.mission_turns_within(m.param('turns')),
        _ => dataText(l10n, m.textKey),
      };

  Widget _floodBars(AppLocalizations l10n) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(
            child: OutlinedText(
              l10n.statFlood(summary.floodPercent, enemyFloodPercent),
              size: 13,
            ),
          ),
          const SizedBox(height: 3),
          FloodBar(percent: summary.floodPercent, color: AppColors.blue),
          const SizedBox(height: 3),
          FloodBar(percent: enemyFloodPercent, color: const Color(0xFFB3302B)),
        ],
      ),
    );
  }

  Widget _stars(AppLocalizations l10n, String missionText) {
    final s = reward.stars;
    final rows = [
      (l10n.resultWin, s.won),
      (l10n.resultInTurns(stage.starTurns), s.inTurns),
      (l10n.resultMission(missionText), s.mission),
    ];
    return Column(
      children: [
        // 큰 별 3개가 하나씩 찍힌다 (설계서 §13.5).
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, (_, on)) in rows.indexed)
              PopIn(
                order: 4 + i * 3,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4, i == 1 ? 0 : 10, 4, 0),
                  child: MetaIcons.image(
                    on ? MetaIcons.starOn : MetaIcons.starOff,
                    size: i == 1 ? 52 : 40,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final (label, on) in rows)
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: on ? AppColors.text : AppColors.mute,
            ),
          ),
      ],
    );
  }

  Widget _rewards(AppLocalizations l10n, PirateDef Function(String id) def) {
    const accent = TextStyle(color: Color(0xFFFFC24A), fontSize: 14);
    return Column(
      children: [
        if (reward.gold > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MetaIcons.image(MetaIcons.gold, size: 26),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  child: CountUp(
                    value: reward.gold,
                    builder: (context, v) =>
                        OutlinedText(l10n.rewardGold(v), size: 20),
                  ),
                ),
              ),
            ],
          ),
        CountUp(
          value: reward.xp,
          builder: (context, v) => OutlinedText(l10n.rewardXp(v), size: 17),
        ),
        if (reward.firstClear) Text(l10n.rewardFirstClear, style: accent),
        if (reward.newPirate != null)
          Text(
            l10n.rewardPirate(dataText(l10n, def(reward.newPirate!).nameKey)),
            textAlign: TextAlign.center,
            style: accent,
          ),
        if (reward.leveledUp)
          OutlinedText(
            l10n.levelUpTo(reward.levelAfter),
            size: 18,
            color: const Color(0xFFFFC24A),
          ),
      ],
    );
  }
}
