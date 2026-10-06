import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/sprites.dart';

/// 기능 모듈 그림 (설계서 §3.3, 에셋 v0.23 `ship/modules/`, ADR-063). 그리기만
/// 한다. 판정은 격자 그대로다.
///
/// 그림은 오른쪽(뱃머리)을 보는 배 기준이고, 배 로컬 좌표(+x 가 뱃머리)에 그리므로
/// 적 배는 `ShipView` 의 좌우 반전을 그대로 따른다. 포문은 선실 앞벽에서 칸 밖으로
/// 8px 나가고, 망루는 선실 위로 1칸 솟는다(에셋 README v0.23).
abstract final class ModulePainter {
  /// 모듈 → (칸 왼쪽 위에서 그림 왼쪽 위까지, 그림 크기). 에셋 SVG `viewBox` 와
  /// 같다(1 그림 px = 1 월드 px). 그림 경로는 [BattleSprites.moduleFile].
  static const Map<ModuleKind, (Offset, Size)> art = {
    ModuleKind.gunPort: (Offset.zero, Size(40, 32)),
    ModuleKind.lookout: (Offset(0, -32), Size(32, 64)),
    ModuleKind.magazine: (Offset(0, -6), Size(32, 38)),
    ModuleKind.pump: (Offset(0, -6), Size(32, 38)),
    ModuleKind.workshop: (Offset(0, -6), Size(32, 38)),
    ModuleKind.captain: (Offset.zero, Size(32, 32)),
    ModuleKind.fuelTank: (Offset.zero, Size(32, 32)),
    ModuleKind.mast: (Offset.zero, Size(32, 32)),
    ModuleKind.mastBamboo: (Offset.zero, Size(32, 32)),
    ModuleKind.mastOak: (Offset.zero, Size(32, 32)),
    ModuleKind.mastIron: (Offset.zero, Size(32, 32)),
    ModuleKind.mastCrow: (Offset.zero, Size(32, 32)),
  };

  /// 칸 [cell] 에 [kind] 모듈을 그린다.
  static void draw(
    Canvas canvas,
    BattleSprites sprites,
    Rect cell,
    ModuleKind kind,
  ) {
    final (at, size) = art[kind]!;
    sprites
        .get(BattleSprites.moduleFile(kind))
        .render(
          canvas,
          position: Vector2(cell.left + at.dx, cell.top + at.dy),
          size: Vector2(size.width, size.height),
        );
  }

  /// 칸 번호(y × [width] + x) → 모듈.
  static Map<int, ModuleKind> byCell(ShipModules modules, int width) => {
    for (final m in modules.list) m.y * width + m.x: m.kind,
  };
}
