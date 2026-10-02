import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/ui/cards/rarity_card.dart';

/// 더미배 연습 해적 줄 (ADR-073): 전투 화면 위쪽에 해적 전원을 작은 카드로 띄운다.
/// 누르면 그 해적이 맨 앞 선실인 새 연습판을 연다. 덱에 탄 해적은 금 테두리.
class PracticeBar extends ConsumerWidget {
  const PracticeBar({required this.deck, required this.onPick, super.key});

  final List<String> deck;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pirates = ref.watch(gameCatalogProvider).data.pirates;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 56),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final def in pirates)
                    GestureDetector(
                      key: ValueKey('practice_${def.id}'),
                      onTap: () => onPick(def.id),
                      child: Container(
                        width: 38,
                        height: 54,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            width: 2,
                            color: deck.contains(def.id)
                                ? AppColors.gold
                                : Colors.transparent,
                          ),
                        ),
                        child: RarityCard(
                          rarity: def.rarity,
                          species: def.species,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
