import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/labels.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

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
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: Pressable(
        onTap: () => model.selectTool(tool),
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
              Image.asset(image, width: 22, height: 22),
              const SizedBox(width: 4),
              Text(
                cost == null ? label : '$label $cost',
                style: TextStyle(
                  fontSize: 13,
                  color: on ? AppColors.gold : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
