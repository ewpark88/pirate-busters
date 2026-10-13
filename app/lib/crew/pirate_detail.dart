import 'package:flutter/material.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/ui/cards/rarity_card.dart';
import 'package:pirate_busters/ui/hud/ammo_label.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 상세 창에서 고른 일.
enum PirateDetailAction { board, unboard }

/// 해적 상세 (설계서 §13.7, A63): 그림·등급·계열·코스트·체력·쉬는 턴·탄종·사거리·
/// 설명·이야기. 해적보감(§13.9)이 생기기 전까지 그 자리를 대신하고, 레벨업은 R4.
/// [canBoard]·[canUnboard] 가 켜지면 태우기·내리기 버튼을 둔다.
Future<PirateDetailAction?> showPirateDetail(
  BuildContext context, {
  required PirateDef def,
  required PirateSpec spec,
  required bool inDeck,
  required bool canBoard,
  required bool canUnboard,
}) => showPbDialog<PirateDetailAction>(
  context,
  (context) => PirateDetail(
    def: def,
    spec: spec,
    inDeck: inDeck,
    canBoard: canBoard,
    canUnboard: canUnboard,
  ),
);

class PirateDetail extends StatelessWidget {
  const PirateDetail({
    required this.def,
    required this.spec,
    required this.inDeck,
    required this.canBoard,
    required this.canUnboard,
    super.key,
  });

  final PirateDef def;
  final PirateSpec spec;
  final bool inDeck;
  final bool canBoard;
  final bool canUnboard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    const body = TextStyle(color: AppColors.text, fontSize: 14, height: 1.35);
    const lore = TextStyle(
      color: AppColors.mute,
      fontSize: 13,
      height: 1.35,
      fontStyle: FontStyle.italic,
    );
    void pop(PirateDetailAction? a) => Navigator.of(context).pop(a);
    return PbPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: RarityCard(
                        rarity: def.rarity,
                        species: def.species,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedText(
                            dataText(l10n, def.nameKey),
                            size: 20,
                            font: AppFonts.display,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Labels.rarity(l10n, def.rarity)} · '
                            '${Labels.family(l10n, def.family)}',
                            style: const TextStyle(color: Color(0xFF9A917F)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              PbChip(label: l10n.pirateCost(spec.cost)),
                              PbChip(label: l10n.pirateHp(spec.hp)),
                              PbChip(
                                label: l10n.cooldown(spec.cooldownTurns),
                              ),
                              PbChip(
                                label: l10n.pirateRange(
                                  rangeLabel(l10n, spec.range),
                                ),
                              ),
                              PbChip(
                                label: ammoLabel(l10n, spec, locale),
                                icon: ammoIconPath(spec.ammo),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(dataText(l10n, def.descKey), style: body),
                          const SizedBox(height: 6),
                          Text(dataText(l10n, def.loreKey), style: lore),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PbButton(
                  label: l10n.pirateClose,
                  kind: PbButtonKind.secondary,
                  height: 42,
                  fontSize: 16,
                  onPressed: () => pop(null),
                ),
                const SizedBox(width: 10),
                if (inDeck)
                  PbButton(
                    key: const ValueKey('pirate-unboard'),
                    label: l10n.pirateUnboard,
                    kind: PbButtonKind.secondary,
                    height: 42,
                    fontSize: 16,
                    onPressed: canUnboard
                        ? () => pop(PirateDetailAction.unboard)
                        : null,
                  )
                else
                  PbButton(
                    key: const ValueKey('pirate-board'),
                    label: l10n.pirateBoard,
                    height: 42,
                    fontSize: 16,
                    onPressed: canBoard
                        ? () => pop(PirateDetailAction.board)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
