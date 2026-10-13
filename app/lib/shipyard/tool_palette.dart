import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/shipyard/tool_card.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/labels.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 팔레트 묶음: 재질 3종, 선장실, 돛대 (설계서 §13.6, §3.3).
enum ToolGroup { materials, modules, masts }

/// 재질·모듈·돛대 팔레트 (설계서 §13.6). 묶음 탭 아래에 같은 크기 카드를 2열로 두고,
/// 쓸 수 있는 것을 먼저, 잠긴 것은 자물쇠와 여는 골드로 뒤에 둔다. 선실·지우기는
/// 어느 탭에서나 아래 줄에 보인다. 지금 골드로 열 수 있는 것에는 빨간 점을 붙인다.
class ToolPalette extends StatefulWidget {
  const ToolPalette({
    required this.model,
    this.ship = const ShipUpgrades(),
    this.gold = 0,
    this.onLocked,
    super.key,
  });

  final ShipyardModel model;
  final ShipUpgrades ship;

  /// 가진 골드. 빨간 점(지금 열 수 있음)에 쓴다.
  final int gold;
  final void Function(ShipTool tool, int gold)? onLocked;

  @override
  State<ToolPalette> createState() => _ToolPaletteState();
}

class _ToolPaletteState extends State<ToolPalette> {
  late ToolGroup _group = switch (widget.model.tool) {
    ModuleTool(:final kind) =>
      kind.isMast ? ToolGroup.masts : ToolGroup.modules,
    _ => ToolGroup.materials,
  };

  /// 잠긴 도구면 여는 골드, 아니면 null (BALANCE.md A13.6·A3.2).
  int? _lockedGold(ShipTool tool) => switch (tool) {
    MaterialTool(:final material) when !widget.ship.hasMaterial(material) =>
      ShipUpgrades.materialGold[material],
    ModuleTool(:final kind) when !widget.ship.hasModule(kind) =>
      ShipUpgrades.moduleGold[kind],
    _ => null,
  };

  List<ShipTool> _tools(ToolGroup g) {
    final all = <ShipTool>[
      if (g == ToolGroup.materials)
        for (final m in BlockMaterial.blocks) MaterialTool(m),
      if (g != ToolGroup.materials)
        for (final k in ModuleKind.values)
          if (k.isMast == (g == ToolGroup.masts)) ModuleTool(k),
    ];
    return [
      ...all.where((t) => _lockedGold(t) == null),
      ...all.where((t) => _lockedGold(t) != null),
    ];
  }

  bool _affordable(ShipTool t) {
    final g = _lockedGold(t);
    return g != null && g <= widget.gold;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final names = [
      l10n.toolTabMaterials,
      l10n.toolTabModules,
      l10n.toolTabMasts,
    ];
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final g in ToolGroup.values)
                Expanded(
                  child: _GroupTab(
                    label: names[g.index],
                    selected: g == _group,
                    dot: _tools(g).any(_affordable),
                    onTap: () => setState(() => _group = g),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                // 넓은 화면에서는 카드가 늘어지지 않게 열을 늘린다(2~4열).
                final cols = (box.maxWidth ~/ 170).clamp(2, 4);
                final w = (box.maxWidth - 4 * (cols - 1)) / cols;
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final t in _tools(_group))
                        SizedBox(width: w, child: _card(l10n, t)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _card(l10n, const CabinTool())),
              const SizedBox(width: 4),
              Expanded(child: _card(l10n, const EraseTool())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(AppLocalizations l10n, ShipTool tool) {
    final (label, image, cost) = switch (tool) {
      MaterialTool(:final material) => (
        Labels.material(l10n, material),
        ShipGridView.tileImage(material, 0, 0),
        material.cost,
      ),
      ModuleTool(:final kind) => (
        Labels.module(l10n, kind),
        ShipGridView.moduleImage(kind),
        kind.cost,
      ),
      CabinTool() => (l10n.toolCabin, ShipGridView.cabinImage(0, 0), null),
      EraseTool() => (l10n.toolErase, MetaIcons.cancel, null),
    };
    final gold = _lockedGold(tool);
    return ToolCard(
      label: label,
      image: image,
      costText: cost == null ? null : l10n.toolPoints(cost),
      lockedGold: gold,
      dot: _affordable(tool),
      selected: sameTool(widget.model.tool, tool),
      onTap: gold == null
          ? () => widget.model.selectTool(tool)
          : () => widget.onLocked?.call(tool, gold),
    );
  }
}

/// 묶음 탭 한 칸: 고르면 금 테두리, 열 수 있는 것이 있으면 빨간 점.
class _GroupTab extends StatelessWidget {
  const _GroupTab({
    required this.label,
    required this.selected,
    required this.dot,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: Pressable(
      onTap: onTap,
      child: Container(
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3A2F18) : const Color(0xFF1E222A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.gold : const Color(0xFF3A3F4A),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selected ? AppColors.gold : AppColors.mute,
                  ),
                ),
              ),
            ),
            if (dot) ...[
              const SizedBox(width: 3),
              Image.asset(MetaIcons.redDot, width: 9, height: 9),
            ],
          ],
        ),
      ),
    ),
  );
}
