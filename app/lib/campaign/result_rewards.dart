import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/campaign/result_celebrate.dart';
import 'package:pirate_busters/campaign/result_reveal.dart';
import 'package:pirate_busters/campaign/rewards.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 결과 화면 보상 (설계서 §13.5): 골드·경험치가 세어 올라가고, 새 해적은 등급
/// 카드가 뒤집히며, 레벨업은 빛 배너로 나온다 (§10.5, §13.8, A55).
class ResultRewards extends ConsumerWidget {
  const ResultRewards({
    required this.reward,
    this.growReady = false,
    super.key,
  });

  final StageReward reward;

  /// 배 키우기가 열렸다 (첫 클리어).
  final bool growReady;

  /// 새 해적·레벨업이 나오는 차례(별 3개 뒤).
  static const int revealOrder = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(gameCatalogProvider);
    const accent = TextStyle(color: Color(0xFFFFC24A), fontSize: 14);
    final pirate = reward.newPirate;
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
        if (growReady) Text(l10n.shipGrowReady, style: accent),
        if (pirate != null)
          // 작은 등급 카드가 뒤집히며 나오고 옆에 이름 (버튼을 밀어내지 않게 한 줄).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NewPirateReveal(
                rarity: catalog.def(pirate).rarity,
                species: catalog.speciesOf(pirate),
                order: revealOrder,
                height: 40,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.rewardPirate(
                    dataText(l10n, catalog.def(pirate).nameKey),
                  ),
                  style: accent,
                ),
              ),
            ],
          ),
        if (reward.leveledUp) ...[
          const SizedBox(height: 4),
          LevelUpBanner(
            text: l10n.levelUpTo(reward.levelAfter),
            order: revealOrder + (pirate != null ? 6 : 0),
          ),
        ],
      ],
    );
  }
}
