import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/result_celebrate.dart';
import 'package:pirate_busters/campaign/result_hero.dart';
import 'package:pirate_busters/campaign/result_parts.dart';
import 'package:pirate_busters/campaign/result_rewards.dart';
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

/// 결과 화면 (설계서 §13.5, §13 공통): 해역 그림 위에 승패·승리 방식, 별 3개, 보상,
/// 전투 통계, 다시 하기·항구로. ‘광고 보고 2배’·리플레이 저장은 플랫폼 묶음에서 켠다.
class StageResultScreen extends ConsumerWidget {
  const StageResultScreen({
    required this.stage,
    required this.summary,
    required this.reward,
    this.replay,
    super.key,
  });

  final StageSpec stage;
  final MatchSummary summary;
  final StageReward reward;

  /// 저장할 수 있는 리플레이 (설계서 §7.2). 없으면 버튼이 안 보인다.
  final Replay? replay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // 승패·무승부는 pb_sim 의 판정을 그대로 쓴다 (설계서 §2.4, §13.5).
    final title = summary.won
        ? l10n.resultWin
        : summary.draw
        ? l10n.resultDraw
        : l10n.resultLose;
    final how = switch (summary.outcome) {
      MatchOutcome.captainLost => l10n.outcomeCaptainLost,
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
                    if (summary.outcome == MatchOutcome.timeDecision)
                      _hpCompare(l10n),
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
                            ResultRewards(reward: reward),
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
        'crew_hp_above' => l10n.mission_crew_hp_above(m.param('percent')),
        'turns_within' => l10n.mission_turns_within(m.param('turns')),
        _ => dataText(l10n, m.textKey),
      };

  /// 턴 제한으로 끝나면 양쪽 남은 해적 체력을 막대로 나란히 (설계서 §13.5).
  Widget _hpCompare(AppLocalizations l10n) => Padding(
    key: const ValueKey('result-hp-compare'),
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      width: 220,
      child: Column(
        children: [
          Text(
            l10n.timeVerdictHp(
              '${summary.crewPercent}',
              '${summary.foeCrewPercent}',
            ),
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
          const SizedBox(height: 4),
          HpBar(percent: summary.crewPercent, color: const Color(0xFF6F97E6)),
          const SizedBox(height: 4),
          HpBar(
            percent: summary.foeCrewPercent,
            color: const Color(0xFFE06A5A),
          ),
          // 체력 비율이 같아 선장실 내구도로 가렸으면 그 이유 (설계서 §2.7).
          if (summary.byCaptain)
            Padding(
              key: const ValueKey('result-by-captain'),
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.timeVerdictByHull,
                style: const TextStyle(color: AppColors.text, fontSize: 12),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _stars(AppLocalizations l10n, String missionText) {
    final s = reward.stars;
    final rows = [
      (l10n.resultWin, s.won),
      (l10n.resultInTurns(stage.starTurns), s.inTurns),
      (l10n.resultMission(missionText), s.mission),
    ];
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, (_, on)) in rows.indexed)
              // 별 도장: 크게 떨어져 찍히고 소리가 난다 (A55).
              StarStamp(
                on: on,
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
}
