import 'package:flutter/material.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/crew/deck_eval.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/cards/card_icons.dart';
import 'package:pirate_busters/ui/cards/rarity_card.dart';
import 'package:pirate_busters/ui/hud/ammo_label.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 코스트 사용량 / 한도 막대 (설계서 §4.5, §13.7).
class CostBar extends StatelessWidget {
  const CostBar({required this.used, required this.limit, super.key});

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedText(l10n.crewCost(used, limit), size: 15),
        const SizedBox(height: 3),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF0E1014),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.gold, width: 1.5),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: limit == 0 ? 0 : (used / limit).clamp(0, 1).toDouble(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: used > limit
                    ? AppColors.danger
                    : const Color(0xFFFFC24A),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 덱 평가: 계열 분포 (설계서 §13.7).
class DeckEvalView extends StatelessWidget {
  const DeckEvalView(this.eval, {super.key});

  final DeckEval eval;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget chip(String text) => PbChip(label: text);
    const head = TextStyle(color: AppColors.mute, fontSize: 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.deckFamilies, style: head),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final e in eval.families.entries)
              chip('${Labels.family(l10n, e.key)} ${e.value}'),
          ],
        ),
      ],
    );
  }
}

/// 보유 해적 목록의 카드 한 장. 누르면 상세, 길게 눌러 끌면 선실에 놓는다 (A63).
/// 그냥 밀면 목록이 스크롤된다: 즉시 끌기는 세로 스크롤을 가로챘다.
class PirateTile extends StatelessWidget {
  const PirateTile({
    required this.def,
    required this.spec,
    required this.inDeck,
    required this.onTap,
    super.key,
  });

  final PirateDef def;
  final PirateSpec spec;
  final bool inDeck;
  final VoidCallback onTap;

  /// 이만큼 누르고 있어야 끌려 나온다.
  static const Duration longPressDelay = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final card = Opacity(
      opacity: inDeck ? 0.45 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF262A33),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), offset: Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          children: [
            // 등급 프레임 카드 옆에 코스트·세트 아이콘 (설계서 §10.5, §13.7).
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: RarityCard(
                      rarity: def.rarity,
                      species: def.species,
                    ),
                  ),
                  CardIcons.column(spec, def.species),
                ],
              ),
            ),
            _line(dataText(l10n, def.nameKey), AppColors.text, size: 12),
            _line(
              '${Labels.rarity(l10n, def.rarity)} · '
              '${Labels.family(l10n, def.family)}',
              const Color(0xFF9A917F),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(ammoIconPath(spec.ammo), width: 12, height: 12),
                Flexible(
                  child: _line(
                    ammoLabel(l10n, spec, locale),
                    const Color(0xFFFFC24A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return Pressable(
      onTap: onTap,
      child: LongPressDraggable<String>(
        data: def.id,
        delay: longPressDelay,
        maxSimultaneousDrags: inDeck ? 0 : 1,
        // 들어 올린 카드: 살짝 크게, 그림자를 짙게.
        feedback: Transform.scale(
          scale: 1.08,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(color: Color(0xAA000000), blurRadius: 12)],
            ),
            child: SizedBox(width: 80, height: 110, child: card),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: card),
        child: card,
      ),
    );
  }

  /// 한 줄 글자. 칸보다 길면 자르지 않고 줄여서 다 보여준다 (설계서 §14.4).
  Widget _line(String text, Color color, {double size = 10}) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      text,
      maxLines: 1,
      style: TextStyle(color: color, fontSize: size),
    ),
  );
}
