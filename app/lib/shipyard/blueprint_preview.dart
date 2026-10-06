import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';

/// 설계도 미리보기 (설계서 §13.3 전투 준비 ‘내 배 미리보기’). 조선소 격자 그림을
/// 읽기 전용으로 그린다. 입력은 받지 않는다.
class BlueprintPreview extends StatelessWidget {
  const BlueprintPreview({required this.blueprint, super.key});

  final Blueprint blueprint;

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
          child: ShipGridView(model: model, cell: cell),
        );
      },
    );
  }
}
