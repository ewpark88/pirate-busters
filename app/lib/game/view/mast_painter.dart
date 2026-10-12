import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 돛·깃발에 닿는 바람 (설계서 §10.2 ‘바람’, A35): 세기 0~1, 배 로컬 기준 바람이
/// 부는 쪽(−1·0·+1), 시각(초).
typedef Breeze = ({double strength, int dir, double t});

/// 돛대 그리기 (설계서 §3.3 돛대 칸, §10.2): 돛대 모듈 칸 위로 돛대 칸을 따라 기둥을
/// 세우고, 다 서 있으면 돛·깃발을 단다. 돛대 칸이 부서지면 남은 높이까지만 그루터기로
/// 그리고 돛은 없다. 꼭대기가 돛 자리면 발판을 그린다. 판정은 시뮬레이션에 있고
/// 여기는 그리기만 한다.
abstract final class MastPainter {
  static final Paint _outline = Paint()
    ..color = const Color(0xFF2A160B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  /// 종류별 기둥 색·굵기(px).
  static (Color, double) look(ModuleKind kind) => switch (kind) {
    ModuleKind.mastBamboo => (const Color(0xFFB9A35A), 6),
    ModuleKind.mastOak => (const Color(0xFF6B4528), 9),
    ModuleKind.mastIron => (const Color(0xFF7D8590), 9),
    ModuleKind.mastCrow => (const Color(0xFF8B5A2B), 8),
    _ => (const Color(0xFFB07A45), 8),
  };

  /// 아래에서부터 이어서 남은 돛대 칸 수.
  static int standing(
    ModuleCell m,
    List<int> materials,
    int width,
    int height,
  ) {
    var n = 0;
    for (final (x, y) in m.rigCells(height)) {
      if (materials[y * width + x] == ShipGrid.emptyCell) break;
      n++;
    }
    return n;
  }

  /// [view] 배의 바람: 지금 턴 바람(역풍·무풍 상태 적용, §4.8)을 배 로컬 방향으로.
  /// 오른쪽 배는 좌우가 뒤집혀 그려지므로 방향도 뒤집는다.
  static Breeze breezeOf(ShipView view) {
    final state = view.session.state;
    final max = math.max(1, state.rules.maxWind);
    return (
      strength: (state.wind.abs() / max).clamp(0.0, 1.0),
      dir: state.wind.sign * view.scale.x.sign.toInt(),
      t: view.session.turnMs / 1000,
    );
  }

  /// 돛 아래쪽이 바람 쪽으로 밀리는 기울기: 세기에 비례하고 조금씩 펄럭인다.
  /// 무풍이면 0.
  static double sailSkew(Breeze b) =>
      b.dir *
      b.strength *
      (0.16 + 0.03 * math.sin(b.t * (2.5 + 5 * b.strength)));

  /// 깃발이 아래로 처지는 각(라디안): 무풍이면 가장 처지고 세질수록 펴진다.
  static double flagDroop(Breeze b) => (1 - b.strength) * 1.1;

  /// [view] 배의 돛대를 모두 그린다. [materials] 는 지금 그리는 격자(착탄 전 모습일
  /// 수 있다). 돛·깃발은 바람 세기·방향으로 펄럭인다 (§10.2, A35).
  static void paint(Canvas canvas, ShipView view, List<int> materials) {
    final sprites = view.sprites;
    final ship = view.session.state.sides[view.side];
    final cellRect = view.cellRect;
    final breeze = breezeOf(view);
    final width = ship.grid.width;
    final height = ship.grid.height;
    final seats = ship.cabins;
    final blue = ship.side == 0;
    for (final m in [for (final s in ship.modules.list) s.cell]) {
      if (!m.kind.isMast) continue;
      if (materials[m.y * width + m.x] == ShipGrid.emptyCell) continue;
      final rig = m.rigCells(height);
      final n = standing(m, materials, width, height);
      final base = cellRect(m.x, m.y);
      final whole = n == rig.length && n > 0;
      final top = n == 0
          ? base.top - 6
          : cellRect(rig[n - 1].$1, rig[n - 1].$2).top + (whole ? -6 : 8);
      final (color, w) = look(m.kind);
      final pole = Rect.fromLTRB(
        base.center.dx - w / 2,
        top,
        base.center.dx + w / 2,
        base.top + 6,
      );
      if (whole) _sail(canvas, sprites, rig, cellRect, breeze, blue: blue);
      canvas
        ..drawRect(pole, Paint()..color = color)
        ..drawRect(pole, _outline);
      _bands(canvas, m.kind, pole);
      if (!whole) {
        _splinters(canvas, pole, color);
        continue;
      }
      final (tx, ty) = rig.last;
      final seat = seats.any((c) => c.x == tx && c.y == ty);
      if (seat || m.kind == ModuleKind.mastCrow) {
        _platform(canvas, cellRect(tx, ty));
      }
      _flag(canvas, sprites, Offset(pole.center.dx, top), breeze, blue: blue);
    }
  }

  static void _sail(
    Canvas canvas,
    BattleSprites sprites,
    List<(int, int)> rig,
    Rect Function(int x, int y) cellRect,
    Breeze breeze, {
    required bool blue,
  }) {
    final low = cellRect(rig.first.$1, rig.first.$2);
    final high = cellRect(rig.last.$1, rig.last.$2);
    final sail = sprites.get('ship/rig/sail_${blue ? 'blue' : 'red'}.png');
    final h = low.bottom - high.top - low.height * 0.55;
    final w = h * sail.srcSize.x / sail.srcSize.y;
    final top = Offset(low.center.dx, high.top + high.height * 0.35);
    // 활대(위 가운데)를 축으로: 바람에 부풀어 아래가 밀리고, 무풍이면 처진다.
    final s = breeze.strength;
    canvas
      ..save()
      ..translate(top.dx, top.dy)
      ..skew(sailSkew(breeze), 0)
      ..scale(s == 0 ? .92 : 1 + .08 * s, s == 0 ? .9 : 1);
    sail.render(canvas, position: Vector2(-w / 2, 0), size: Vector2(w, h));
    canvas.restore();
  }

  /// 대나무 마디·철 띠.
  static void _bands(Canvas canvas, ModuleKind kind, Rect pole) {
    if (kind != ModuleKind.mastBamboo && kind != ModuleKind.mastIron) return;
    final band = Paint()
      ..color = const Color(0xFF3B2414)
      ..strokeWidth = kind == ModuleKind.mastIron ? 3 : 1.5;
    for (var y = pole.bottom - 12; y > pole.top + 4; y -= 16) {
      canvas.drawLine(Offset(pole.left, y), Offset(pole.right, y), band);
    }
  }

  /// 부러진 끝의 뾰족한 나뭇결.
  static void _splinters(Canvas canvas, Rect pole, Color color) {
    final path = Path()
      ..moveTo(pole.left, pole.top)
      ..lineTo(pole.left + pole.width * 0.25, pole.top - 7)
      ..lineTo(pole.center.dx, pole.top - 2)
      ..lineTo(pole.right - pole.width * 0.2, pole.top - 9)
      ..lineTo(pole.right, pole.top)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = color)
      ..drawPath(path, _outline);
  }

  /// 돛 자리 발판(망대 바구니). 해적은 이 위에 선다.
  static void _platform(Canvas canvas, Rect cell) {
    final r = Rect.fromLTRB(
      cell.left + 3,
      cell.bottom - 8,
      cell.right - 3,
      cell.bottom,
    );
    canvas
      ..drawRect(r, Paint()..color = const Color(0xFF6B4528))
      ..drawRect(r, _outline);
  }

  static void _flag(
    Canvas canvas,
    BattleSprites sprites,
    Offset top,
    Breeze breeze, {
    required bool blue,
  }) {
    final flag = sprites.get('ship/rig/flag_${blue ? 'blue' : 'red'}.png');
    final s = breeze.strength;
    // 깃대에 붙은 자리를 축으로 바람 쪽을 향하고, 세기만큼 펄럭이며, 약하면 처진다.
    final wave = 1 + .14 * s * math.sin(breeze.t * (5 + 8 * s));
    canvas
      ..save()
      ..translate(top.dx, top.dy - 14)
      ..scale(breeze.dir < 0 ? -1 : 1, 1)
      ..rotate(flagDroop(breeze))
      ..scale(.75 + .25 * s, wave);
    flag.render(canvas, position: Vector2(3, 0), size: flag.srcSize / 3.6);
    canvas.restore();
  }
}
