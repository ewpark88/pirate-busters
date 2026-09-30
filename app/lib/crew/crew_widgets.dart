import 'package:flutter/material.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/crew/deck_eval.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/hud/ammo_label.dart';
import 'package:pirate_busters/ui/labels.dart';

String _portrait(String species) =>
    'assets/images/ui/portraits/${species}_blue.png';

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
          height: 84,
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
                  feedback: _Face(species: species(p.id)),
                  child: _Face(species: species(p.id)),
                ),
        ),
      );
    },
  );
}

class _Face extends StatelessWidget {
  const _Face({required this.species});

  final String species;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 80,
    child: Image.asset(_portrait(species), fit: BoxFit.contain),
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
            Expanded(
              child: Image.asset(_portrait(def.species), fit: BoxFit.contain),
            ),
            _line(dataText(l10n, def.nameKey), const Color(0xFFEFE6D2)),
            _line(
              '${Labels.rarity(l10n, def.rarity)} · '
              '${Labels.family(l10n, def.family)} · ${spec.cost}',
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

  Widget _line(String text, Color color) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(color: color, fontSize: 10),
  );
}
