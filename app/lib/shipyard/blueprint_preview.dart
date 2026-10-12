import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';

/// 설계도 미리보기 (설계서 §13.3 전투 준비 ‘내 배 미리보기’). 조선소 격자 그림을
/// 읽기 전용으로 그린다. 입력은 받지 않는다.
class BlueprintPreview extends StatelessWidget {
  const BlueprintPreview({
    required this.blueprint,
    this.bare = false,
    this.markBow = false,
    super.key,
  });

  final Blueprint blueprint;

  /// 격자선·흘수선·선실 번호 없이 배만 그린다.
  final bool bare;

  /// 뱃머리 방패 칸(블록이 있는 가장 앞 세로줄)에 금색 테를 두른다 (§5.4, A57).
  final bool markBow;

  /// 판 시작 때 방패가 되는 칸. 규칙은 pb_sim `bowShieldCells` 하나만 쓴다.
  static Set<int> bowCells(Blueprint blueprint) =>
      bowShieldCells(ShipGrid.fromBlueprint(blueprint)).toSet();

  @override
  Widget build(BuildContext context) {
    final model = ShipyardModel(hull: blueprint.hull)..load(blueprint);
    return LayoutBuilder(
      builder: (context, box) {
        // 패널 테두리 그림이 아래 줄을 덮지 않게 높이에 여유를 둔다.
        final cell = (box.maxWidth / model.width)
            .clamp(0, box.maxHeight * 0.88 / model.height)
            .toDouble();
        return Center(
          child: ShipGridView(
            model: model,
            cell: cell,
            bare: bare,
            marked: markBow ? bowCells(blueprint) : const {},
          ),
        );
      },
    );
  }
}
