import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/module_painter.dart';
import 'package:pirate_busters/shipyard/ship_grid_editor.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';

/// 설계도 격자와 그 위의 선실·모듈 그림 (설계서 §13.6, 에셋 v0.23
/// `ship/modules/`, ADR-063). 조선소와 전투 준비 미리보기가 같이 쓴다.
///
/// 재질 칸·흘수선은 [ShipGridPainter] 가 그리고, 선실·모듈 그림은 전장과 같은 자리
/// (포문은 앞벽 밖으로, 망루는 위 칸으로)에 그림 위젯으로 겹친다.
class ShipGridView extends StatelessWidget {
  const ShipGridView({required this.model, required this.cell, super.key});

  final ShipyardModel model;

  /// 한 칸의 화면 크기.
  final double cell;

  /// 선실 칸 그림 (무늬 2가지, 칸 위치로 고정).
  static String cabinImage(int x, int y) =>
      'assets/images/ship/modules/cabin_${BattleSprites.variantOf(x, y) % 2}.png';

  /// 재질 칸 그림 (에셋 `ship/tiles_v2`, 무늬는 칸 위치로 고정). 전장과 같은 타일.
  static String tileImage(BlockMaterial m, int x, int y) => switch (m) {
    BlockMaterial.iron => 'assets/images/ship/tiles_v2/iron.png',
    BlockMaterial.net =>
      'assets/images/ship/tiles_v2/mesh_${BattleSprites.variantOf(x, y)}.png',
    _ =>
      'assets/images/ship/tiles_v2/${m.name}_${BattleSprites.variantOf(x, y)}.png',
  };

  static String moduleImage(ModuleKind kind) =>
      'assets/images/${BattleSprites.moduleFile(kind)}';

  @override
  Widget build(BuildContext context) {
    final h = model.height;
    final k = cell / 32;
    Rect at(int x, int y) =>
        Rect.fromLTWH(x * cell, (h - 1 - y) * cell, cell, cell);
    return SizedBox(
      width: cell * model.width,
      height: cell * h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: ShipGridPainter(model, cell)),
          ),
          for (var y = 0; y < h; y++)
            for (var x = 0; x < model.width; x++) ...[
              if (model.materialAt(x, y) case final m?)
                Positioned.fromRect(
                  rect: at(x, y).deflate(1),
                  child: Image.asset(tileImage(m, x, y), fit: BoxFit.fill),
                ),
              if (model.cabinSlotAt(x, y) >= 0)
                Positioned.fromRect(
                  rect: at(x, y).deflate(cell * 0.06),
                  child: Image.asset(cabinImage(x, y), fit: BoxFit.fill),
                ),
              if (model.moduleAt(x, y) case final kind?)
                Positioned.fromRect(
                  rect: _moduleRect(at(x, y), kind, k),
                  child: Image.asset(moduleImage(kind), fit: BoxFit.fill),
                ),
              if (model.cabinSlotAt(x, y) case final slot when slot >= 0)
                Positioned(
                  left: at(x, y).left + 3,
                  top: at(x, y).top + 1,
                  child: Text(
                    '${slot + 1}',
                    style: TextStyle(
                      fontSize: cell * 0.3,
                      color: Colors.white,
                      shadows: const [Shadow(blurRadius: 2)],
                    ),
                  ),
                ),
            ],
          Positioned.fill(
            child: CustomPaint(
              painter: ShipGridPainter(model, cell, overlay: true),
            ),
          ),
        ],
      ),
    );
  }

  static Rect _moduleRect(Rect cell, ModuleKind kind, double k) {
    final (offset, size) = ModulePainter.art[kind]!;
    return Rect.fromLTWH(
      cell.left + offset.dx * k,
      cell.top + offset.dy * k,
      size.width * k,
      size.height * k,
    );
  }
}
