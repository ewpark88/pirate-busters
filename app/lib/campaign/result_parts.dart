import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/campaign/stage_flow.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/platform/ads.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 침수량 막대 하나 (설계서 §13.5 시간 판정). [percent] 0~100.
class FloodBar extends StatelessWidget {
  const FloodBar({required this.percent, required this.color, super.key});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 10,
    decoration: BoxDecoration(
      color: const Color(0xFF0E1014),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: AppColors.gold),
    ),
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: (percent / 100).clamp(0, 1).toDouble(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
  );
}

/// 아래 버튼: 광고 보고 2배(광고가 준비됐을 때만) · 리플레이 저장 · 항구로 · 다시 하기.
class ResultActions extends ConsumerStatefulWidget {
  const ResultActions({
    required this.stage,
    required this.reward,
    required this.replay,
    super.key,
  });

  final StageSpec stage;
  final StageReward reward;
  final Replay? replay;

  @override
  ConsumerState<ResultActions> createState() => _ResultActionsState();
}

class _ResultActionsState extends ConsumerState<ResultActions> {
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
        if (canDouble || widget.replay != null)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (canDouble)
                PbButton.small(
                  label: _doubled ? l10n.resultDoubleDone : l10n.resultDouble,
                  icon: MetaIcons.ad2x,
                  kind: PbButtonKind.gold,
                  onPressed: _doubled ? null : () => unawaited(_double()),
                ),
              if (widget.replay != null)
                PbButton.small(
                  label: _saved ? l10n.replaySaved : l10n.replaySave,
                  icon: MetaIcons.replay,
                  onPressed: _saved ? null : () => unawaited(_saveReplay()),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            PbButton(
              label: l10n.resultToPort,
              kind: PbButtonKind.secondary,
              height: 46,
              minWidth: 100,
              fontSize: 17,
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            PbButton(
              label: l10n.playAgain,
              height: 46,
              fontSize: 17,
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(StageFlow.play(context, ref, widget.stage));
              },
            ),
          ],
        ),
      ],
    );
  }
}
