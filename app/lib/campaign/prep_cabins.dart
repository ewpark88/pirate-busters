import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';

/// 전투 준비의 선실·망대 배치 (설계서 §13.3): 덱 순서가 자리 번호다(선원 화면과 같다,
/// 선실 다음이 망대). 아래에 코스트 사용량 / 한도를 둔다.
class PrepCabins extends ConsumerWidget {
  const PrepCabins({
    required this.deck,
    required this.used,
    required this.limit,
    required this.seats,
    required this.cabins,
    super.key,
  });

  final List<String> deck;
  final int used;
  final int limit;

  /// 해적이 탈 자리 수(선실 + 망대, 설계도 `seatCount`).
  final int seats;

  /// 그중 선실 수. 그 뒤 자리는 망대다.
  final int cabins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(gameCatalogProvider);
    return PbPanel(
      title: l10n.prepCabins,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < seats; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        OutlinedText(
                          i < cabins ? '${i + 1}' : l10n.prepNest,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        if (i < deck.length)
                          Image.asset(
                            'assets/images/ui/portraits/'
                            '${catalog.speciesOf(deck[i])}_blue.png',
                            width: 26,
                            height: 26,
                          )
                        else
                          const SizedBox(width: 26, height: 26),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            i < deck.length
                                ? dataText(l10n, catalog.def(deck[i]).nameKey)
                                : l10n.prepCabinEmpty,
                            style: TextStyle(
                              fontSize: 14,
                              color: i < deck.length
                                  ? AppColors.text
                                  : AppColors.mute,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PbChip(label: l10n.prepCost(used, limit), warn: used > limit),
        ],
      ),
    );
  }
}
