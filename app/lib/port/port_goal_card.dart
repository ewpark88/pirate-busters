import 'package:flutter/material.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/campaign/campaign_catalog.dart';
import 'package:pirate_busters/campaign/stage_node.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/my_ship.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 항구 ‘다음 목표’ 카드 (설계서 §13.2): 다음 스테이지 바로 가기, 별 진행, 배 확장까지
/// 남은 것. 다음에 할 일이 늘 보이게 한다.
class PortGoalCard extends StatelessWidget {
  const PortGoalCard({
    required this.progress,
    required this.campaign,
    required this.onStage,
    this.sea = 1,
    super.key,
  });

  final PlayerProgress progress;
  final CampaignCatalog campaign;
  final int sea;
  final void Function(StageSpec stage) onStage;

  /// 해역 [sea] 에서 아직 안 깬 첫 스테이지. 튜토리얼을 끝냈으면 튜토리얼은 건너뛴다.
  /// 다 깼으면 null.
  static StageSpec? nextStage(CampaignCatalog c, PlayerProgress p, int sea) {
    for (final s in c.sea(sea).stages) {
      if (s.kind == StageKind.tutorial && p.tutorialFinished) continue;
      if (!p.hasCleared(s.id)) return s;
    }
    return null;
  }

  /// 배 확장 안내 한 줄 (설계서 §3.1).
  static String shipLine(
    AppLocalizations l10n,
    CampaignCatalog c,
    PlayerProgress p,
  ) {
    if (openedStageOf(p, c) > p.ship.stage) return l10n.shipGrowReady;
    final next = p.ship.stage + 1;
    if (!ShipUpgrades.stageClears.containsKey(next)) return l10n.goalShipDone;
    return l10n.goalShipNeed(stageClearFor(next, c));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 별은 캠페인 지도의 스테이지만 센다(튜토리얼은 지도에 없다).
    final stages = [
      for (final s in campaign.sea(sea).stages)
        if (s.kind != StageKind.tutorial) s,
    ];
    final next = nextStage(campaign, progress, sea);
    final have = stages.fold(0, (sum, s) => sum + progress.starsOf(s.id));
    return PopIn(
      order: 3,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: PbPanel(
          title: l10n.goalTitle,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (next == null)
                Text(l10n.goalAllClear, style: _strong)
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(stageName(l10n, next), style: _strong),
                    ),
                    PbButton(
                      label: l10n.goalGo,
                      height: 34,
                      minWidth: 70,
                      fontSize: 15,
                      onPressed: () => onStage(next),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  MetaIcons.image(MetaIcons.starOn, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    l10n.goalStars(have, stages.length * 3),
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                shipLine(l10n, campaign, progress),
                style: const TextStyle(fontSize: 13, color: AppColors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _strong = TextStyle(
    fontSize: 16,
    color: AppColors.text,
    fontWeight: FontWeight.bold,
  );
}
