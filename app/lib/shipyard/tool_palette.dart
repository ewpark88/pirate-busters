import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/labels.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 재질 5종·선실·모듈·돛대 5종·지우기 팔레트 (설계서 §13.6). 칩에 건조 포인트를
/// 적는다. 아직 열지 않은 것은 자물쇠와 여는 골드를 보이고, 누르면 [onLocked].
class ToolPalette extends StatelessWidget {
  const ToolPalette({
    required this.model,
    this.ship = const ShipUpgrades(),
    this.onLocked,
    super.key,
  });

  final ShipyardModel model;
  final ShipUpgrades ship;
  final void Function(ShipTool tool, int gold)? onLocked;

  /// 잠긴 도구면 여는 골드, 아니면 null (BALANCE.md A13.6·A3.2).
  int? lockedGold(ShipTool tool) => switch (tool) {
    MaterialTool(:final material) when !ship.hasMaterial(material) =>
      ShipUpgrades.materialGold[material],
    ModuleTool(:final kind) when !ship.hasModule(kind) =>
      ShipUpgrades.moduleGold[kind],
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => SingleChildScrollView(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final m in BlockMaterial.blocks)
              _chip(
                MaterialTool(m),
                Labels.material(l10n, m),
                cost: m.cost,
                image: ShipGridView.tileImage(m, 0, 0),
              ),
            _chip(
              const CabinTool(),
              l10n.toolCabin,
              image: ShipGridView.cabinImage(0, 0),
            ),
            for (final k in ModuleKind.values)
              _chip(
                ModuleTool(k),
                Labels.module(l10n, k),
                cost: k.cost,
                image: ShipGridView.moduleImage(k),
              ),
            _chip(const EraseTool(), l10n.toolErase, image: MetaIcons.cancel),
          ],
        ),
      ),
    );
  }

  bool _same(ShipTool a, ShipTool b) => switch ((a, b)) {
    (MaterialTool(material: final x), MaterialTool(material: final y)) =>
      x == y,
    (ModuleTool(kind: final x), ModuleTool(kind: final y)) => x == y,
    (CabinTool(), CabinTool()) || (EraseTool(), EraseTool()) => true,
    _ => false,
  };

  /// 도구 한 칸: 그림·이름·건조 포인트. 고른 도구는 금 테두리 (설계서 §13 공통).
  Widget _chip(
    ShipTool tool,
    String label, {
    required String image,
    int? cost,
  }) {
    final on = _same(model.tool, tool);
    final gold = lockedGold(tool);
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: Pressable(
        onTap: gold == null
            ? () => model.selectTool(tool)
            : () => onLocked?.call(tool, gold),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF3A2F18) : const Color(0xFF262A33),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: on ? AppColors.gold : const Color(0xFF3A3F4A),
              width: on ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: gold == null ? 1 : 0.45,
                child: Image.asset(image, width: 22, height: 22),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  cost == null || gold != null ? label : '$label $cost',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: gold != null
                        ? AppColors.mute
                        : (on ? AppColors.gold : AppColors.text),
                  ),
                ),
              ),
              if (gold != null) ...[
                const SizedBox(width: 4),
                Image.asset(MetaIcons.lock, width: 14, height: 14),
                Image.asset(MetaIcons.gold, width: 14, height: 14),
                Text(
                  '$gold',
                  style: const TextStyle(fontSize: 12, color: AppColors.gold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
