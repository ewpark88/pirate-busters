import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/campaign/stage_flow.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 결과 화면 (설계서 §13.5): 승패·승리 방식(시간 판정이면 침수량 막대), 별 3개, 보상,
/// 전투 통계, 다시 하기·항구로. ‘광고 보고 2배’·리플레이 저장은 플랫폼 묶음에서 켠다.
class StageResultScreen extends ConsumerWidget {
  const StageResultScreen({
    required this.stage,
    required this.summary,
    required this.enemyFloodPercent,
    required this.reward,
    super.key,
  });

  final StageSpec stage;
  final MatchSummary summary;
  final int enemyFloodPercent;
  final StageReward reward;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(gameCatalogProvider);
    final title = summary.won
        ? l10n.resultWin
        : summary.outcome == MatchOutcome.timeDecision && !summary.won
        ? (enemyFloodPercent == summary.floodPercent
              ? l10n.resultDraw
              : l10n.resultLose)
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
    return Scaffold(
      backgroundColor: const Color(0xFF10141B),
      body: SafeArea(
        child: Center(
          child: HudPanel(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 34,
                      color: summary.won ? HudColors.blue : HudColors.red,
                    ),
                  ),
                  Text(how, style: const TextStyle(color: HudColors.mute)),
                  if (summary.outcome == MatchOutcome.timeDecision) ...[
                    const SizedBox(height: 6),
                    _floodBars(l10n),
                  ],
                  const SizedBox(height: 10),
                  _stars(l10n, missionText),
                  const SizedBox(height: 10),
                  _rewards(l10n, catalog.def),
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.statTurns(summary.turns)} · '
                    '${l10n.statShots(summary.shotsFired)}',
                    style: const TextStyle(color: HudColors.mute, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                        child: Text(l10n.resultToPort),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          unawaited(StageFlow.play(context, ref, stage));
                        },
                        child: Text(l10n.playAgain),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

  Widget _floodBars(AppLocalizations l10n) => SizedBox(
    width: 260,
    child: Column(
      children: [
        Text(
          l10n.statFlood(summary.floodPercent, enemyFloodPercent),
          style: const TextStyle(fontSize: 12),
        ),
        LinearProgressIndicator(
          value: summary.floodPercent / 100,
          color: HudColors.blue,
          backgroundColor: HudColors.panelHi,
        ),
        const SizedBox(height: 3),
        LinearProgressIndicator(
          value: enemyFloodPercent / 100,
          color: HudColors.red,
          backgroundColor: HudColors.panelHi,
        ),
      ],
    ),
  );

  Widget _stars(AppLocalizations l10n, String missionText) {
    final s = reward.stars;
    Widget star(String label, {required bool on}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          on ? Icons.star : Icons.star_border,
          color: HudColors.warn,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        star(l10n.resultWin, on: s.won),
        star(l10n.resultInTurns(stage.starTurns), on: s.inTurns),
        star(l10n.resultMission(missionText), on: s.mission),
      ],
    );
  }

  Widget _rewards(AppLocalizations l10n, PirateDef Function(String id) def) =>
      Column(
        children: [
          if (reward.gold > 0) Text(l10n.rewardGold(reward.gold)),
          Text(l10n.rewardXp(reward.xp)),
          if (reward.firstClear)
            Text(
              l10n.rewardFirstClear,
              style: const TextStyle(color: HudColors.warn),
            ),
          if (reward.newPirate != null)
            Text(
              l10n.rewardPirate(
                dataText(l10n, def(reward.newPirate!).nameKey),
              ),
              style: const TextStyle(color: HudColors.warn),
            ),
          if (reward.leveledUp)
            Text(
              l10n.levelUpTo(reward.levelAfter),
              style: const TextStyle(color: HudColors.warn, fontSize: 16),
            ),
        ],
      );
}
