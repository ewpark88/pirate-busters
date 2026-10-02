import 'package:flutter/material.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/crew/deck_eval.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/cards/card_icons.dart';
import 'package:pirate_busters/ui/cards/rarity_card.dart';
import 'package:pirate_busters/ui/hud/ammo_label.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 선실 슬롯 하나: 해적을 끌어다 놓는 곳. 누르면 비운다.
class CabinSlot extends StatelessWidget {
  const CabinSlot({
    required this.slot,
    required this.pirate,
    required this.species,
    required this.canAccept,
    required this.onAccept,
    required this.onTap,
    super.key,
  });

  final int slot;
  final PirateDef? pirate;
  final String Function(String id) species;
  final bool Function(String id) canAccept;
  final void Function(String id) onAccept;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DragTarget<String>(
    onWillAcceptWithDetails: (d) => canAccept(d.data),
    onAcceptWithDetails: (d) => onAccept(d.data),
    builder: (context, candidates, rejected) {
      final p = pirate;
      final color = rejected.isNotEmpty
          ? const Color(0xFFE0402F)
          : candidates.isNotEmpty
          ? const Color(0xFFFFC24A)
          : const Color(0xFF2F62C4);
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 68,
          height: 96,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2129),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          child: p == null
              ? Center(
                  child: Text(
                    '${slot + 1}',
                    style: const TextStyle(color: Color(0xFF9A917F)),
                  ),
                )
              : Draggable<String>(
                  data: p.id,
                  feedback: _Face(p),
                  child: _Face(p),
                ),
        ),
      );
    },
  );
}

/// 선실에 탄 해적: 등급 프레임 카드 (설계서 §10.5).
class _Face extends StatelessWidget {
  const _Face(this.pirate);

  final PirateDef pirate;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 91,
    child: RarityCard(rarity: pirate.rarity, species: pirate.species),
  );
}

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
        Text(l10n.crewCost(used, limit)),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: limit == 0 ? 0 : (used / limit).clamp(0, 1).toDouble(),
          minHeight: 8,
        ),
      ],
    );
  }
}

/// 덱 평가: 계열 분포·사거리 분포·선호 거리 (설계서 §13.7).
class DeckEvalView extends StatelessWidget {
  const DeckEvalView(this.eval, {super.key});

  final DeckEval eval;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget chip(String text) => Chip(
      visualDensity: VisualDensity.compact,
      label: Text(text),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(switch (eval.preferred) {
          PreferredRange.near => l10n.preferNear,
          PreferredRange.far => l10n.preferFar,
          PreferredRange.mixed => l10n.preferMixed,
        }),
        Text(l10n.deckFamilies),
        Wrap(
          spacing: 4,
          children: [
            for (final e in eval.families.entries)
              chip('${Labels.family(l10n, e.key)} ${e.value}'),
          ],
        ),
        Text(l10n.deckRanges),
        Wrap(
          spacing: 4,
          children: [
            for (final e in eval.ranges.entries)
              chip('${rangeLabel(l10n, e.key)} ${e.value}'),
          ],
        ),
      ],
    );
  }
}

/// 보유 해적 목록의 카드 한 장. 끌어서 선실에 놓는다.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final card = Opacity(
      opacity: inDeck ? 0.4 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2129),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          children: [
            // 등급 프레임 카드 옆에 사거리·코스트·세트 아이콘 (설계서 §10.5, §13.7).
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
            _line(dataText(l10n, def.nameKey), const Color(0xFFEFE6D2)),
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
    return GestureDetector(
      onTap: onTap,
      child: Draggable<String>(
        data: def.id,
        maxSimultaneousDrags: inDeck ? 0 : 1,
        feedback: SizedBox(width: 80, height: 110, child: card),
        child: card,
      ),
    );
  }

  /// 한 줄 글자. 칸보다 길면 자르지 않고 줄여서 다 보여준다 (설계서 §14.4).
  Widget _line(String text, Color color) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      text,
      maxLines: 1,
      style: TextStyle(color: color, fontSize: 10),
    ),
  );
}
