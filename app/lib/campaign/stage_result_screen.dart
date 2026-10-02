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
import 'package:pirate_busters/platform/ads.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 결과 화면 (설계서 §13.5): 승패·승리 방식(시간 판정이면 침수량 막대), 별 3개, 보상,
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
                    '${l10n.statShots(summary.shotsFired)} · '
                    '${l10n.statAccuracy(summary.hitPercent)}',
                    style: const TextStyle(color: HudColors.mute, fontSize: 12),
                  ),
                  Text(
                    l10n.statDamage(
                      summary.damageDealt,
                      summary.blocksDestroyed,
                    ),
                    style: const TextStyle(color: HudColors.mute, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  _ResultActions(stage: stage, reward: reward, replay: replay),
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
        MetaIcons.image(on ? MetaIcons.starOn : MetaIcons.starOff),
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

/// 아래 버튼: 광고 보고 2배(광고가 준비됐을 때만) · 리플레이 저장 · 항구로 · 다시 하기.
class _ResultActions extends ConsumerStatefulWidget {
  const _ResultActions({
    required this.stage,
    required this.reward,
    required this.replay,
  });

  final StageSpec stage;
  final StageReward reward;
  final Replay? replay;

  @override
  ConsumerState<_ResultActions> createState() => _ResultActionsState();
}

class _ResultActionsState extends ConsumerState<_ResultActions> {
  bool _doubled = false;
  bool _saved = false;

  Future<void> _double() async {
    final ads = ref.read(adsProvider);
    if (!await ads.show(AdPlacements.doubleReward)) return;
    ref.read(analyticsProvider).log(Events.adRewardView, {
      'placement': AdPlacements.doubleReward,
      'gold': widget.reward.gold,
    });
    await ref
        .read(progressProvider.notifier)
        .update((p) => p.addGold(widget.reward.gold));
    if (mounted) setState(() => _doubled = true);
  }

  Future<void> _saveReplay() async {
    final replay = widget.replay;
    if (replay == null) return;
    final name = '${widget.stage.id}-${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(replayStoreProvider).save(name, replay);
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ads = ref.watch(adsProvider);
    final canDouble = ads.available && widget.reward.gold > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canDouble)
              FilledButton.tonalIcon(
                onPressed: _doubled ? null : () => unawaited(_double()),
                icon: MetaIcons.image(MetaIcons.ad2x),
                label: Text(
                  _doubled ? l10n.resultDoubleDone : l10n.resultDouble,
                ),
              ),
            if (canDouble && widget.replay != null) const SizedBox(width: 12),
            if (widget.replay != null)
              OutlinedButton.icon(
                onPressed: _saved ? null : () => unawaited(_saveReplay()),
                icon: MetaIcons.image(MetaIcons.replay),
                label: Text(_saved ? l10n.replaySaved : l10n.replaySave),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(l10n.resultToPort),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(StageFlow.play(context, ref, widget.stage));
              },
              child: Text(l10n.playAgain),
            ),
          ],
        ),
      ],
    );
  }
}
