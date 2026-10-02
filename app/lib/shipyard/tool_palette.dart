import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 재질 5종·선실·모듈 8종·지우기 팔레트 (설계서 §13.6). 칩에 건조 포인트를 적는다.
class ToolPalette extends StatelessWidget {
  const ToolPalette({required this.model, super.key});

  final ShipyardModel model;

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
            for (final m in BlockMaterial.values)
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
            _chip(const EraseTool(), l10n.toolErase, icon: Icons.backspace),
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

  Widget _chip(
    ShipTool tool,
    String label, {
    int? cost,
    IconData? icon,
    String? image,
  }) => ChoiceChip(
    selected: _same(model.tool, tool),
    onSelected: (_) => model.selectTool(tool),
    visualDensity: VisualDensity.compact,
    avatar: image != null
        ? Image.asset(image, width: 18, height: 18)
        : Icon(icon, size: 16),
    label: Text(cost == null ? label : '$label $cost'),
  );
}
