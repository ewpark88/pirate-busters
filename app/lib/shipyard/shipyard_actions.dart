import 'package:flutter/material.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 조선소 아래 줄 (설계서 §13.6): 왼쪽 설계도 3칸, 오른쪽 되돌리기·저장·출전.
class ShipyardActions extends StatelessWidget {
  const ShipyardActions({
    required this.model,
    required this.slot,
    required this.active,
    required this.saved,
    required this.onSlot,
    required this.onSave,
    required this.onSail,
    super.key,
  });

  final ShipyardModel model;
  final int slot;

  /// 지금 칸이 출전 배인지.
  final bool active;

  /// 지금 칸에 저장된 설계도가 있는지.
  final bool saved;
  final ValueChanged<int> onSlot;
  final VoidCallback onSave;
  final VoidCallback onSail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              child: PbTabs(
                labels: [
                  for (var i = 0; i < FleetStore.slots; i++)
                    l10n.planSlot(i + 1),
                ],
                selected: slot,
                onSelect: onSlot,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PbIconButton(
          icon: MetaIcons.replay,
          tooltip: l10n.undo,
          size: 42,
          onPressed: model.canUndo ? model.undo : null,
        ),
        const SizedBox(width: 8),
        PbButton(
          label: l10n.save,
          kind: PbButtonKind.gold,
          height: 42,
          minWidth: 96,
          fontSize: 17,
          onPressed: model.canSave ? onSave : null,
        ),
        const SizedBox(width: 8),
        PbButton(
          label: active ? l10n.sailing : l10n.sailWithThis,
          kind: PbButtonKind.secondary,
          height: 42,
          minWidth: 96,
          fontSize: 16,
          onPressed: saved && !active ? onSail : null,
        ),
      ],
    );
  }
}
