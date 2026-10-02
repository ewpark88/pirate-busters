import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';

/// 선실 칸 안쪽과 돛대 그리기. 선실 칸은 블록 재질 타일을 테두리로 남기고 그 안에
/// 안쪽 벽 타일과 바닥 널을 그려, 해적이 칸 안에 서 있는 방으로 보이게 한다
/// (설계서 §10.2, ADR-057). 그리기만 한다. 판정은 격자 그대로다.
abstract final class CabinPainter {
  /// 재질 타일이 보이는 테두리 두께(월드 px).
  static const double frame = 2;

  static final Paint _edge = Paint()
    ..color = const Color(0xCC14161C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  static final Paint _floor = Paint()..color = const Color(0xFF6B4A2B);

  /// 칸 [cell] 안에서 방으로 보이는 영역.
  static Rect inner(Rect cell) => cell.deflate(frame);

  /// [cell] 칸에 안쪽 벽 [wall] 과 바닥 널을 그린다.
  static void room(Canvas canvas, Rect cell, Sprite wall) {
    final r = inner(cell);
    wall.render(
      canvas,
      position: Vector2(r.left, r.top),
      size: Vector2(r.width, r.height),
    );
    canvas
      ..drawRect(Rect.fromLTRB(r.left, r.bottom - 2, r.right, r.bottom), _floor)
      ..drawRect(r, _edge);
  }

  /// 돛대·돛·깃발 (장식, 판정 없음). 가장 높은 블록 위 가운데에 세운다. [materials]
  /// 는 칸별 재질(가로 [width] 칸), 좌표는 배 로컬(가운데 용골 바닥이 원점)이다.
  static void rig(
    Canvas canvas,
    BattleSprites sprites,
    List<int> materials,
    int width, {
    required bool blue,
  }) {
    var top = 0;
    for (var i = 0; i < materials.length; i++) {
      if (materials[i] != ShipGrid.emptyCell) top = i ~/ width + 1;
    }
    final team = blue ? 'blue' : 'red';
    final mast = sprites.get('ship/rig/mast.png');
    final mastSize = mast.srcSize / 3.2;
    final mastPos = Vector2(-mastSize.x / 2, -top * Coords.cell - mastSize.y);
    mast.render(canvas, position: mastPos, size: mastSize);
    final sail = sprites.get('ship/rig/sail_$team.png');
    final sailSize = sail.srcSize / 4.2;
    sail.render(
      canvas,
      position: Vector2(-sailSize.x / 2, mastPos.y + 16),
      size: sailSize,
    );
    final flag = sprites.get('ship/rig/flag_$team.png');
    flag.render(
      canvas,
      position: Vector2(4, mastPos.y - 10),
      size: flag.srcSize / 3.6,
    );
  }
}
