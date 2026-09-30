import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';

/// 날아가는 탄, 조준 궤적(앞 30% 점선), 이동 끝 지점 점선, 이동 한계 부표.
/// 모두 시뮬레이션 값으로 그린다 (개발 계획서 M4).
class ShotView extends Component {
  ShotView({required this.session, required this.sprites, super.priority});

  final BattleSession session;
  final BattleSprites sprites;

  /// 지금 날고 있는 탄들의 월드 위치.
  List<Vector2> get projectiles {
    final p = session.playback;
    if (p is! ShotPlayback) return const [];
    final t = p.tick;
    return [
      for (final trace in p.traces)
        if (t >= trace.startTick && t < trace.endTick) _at(trace, t),
    ];
  }

  /// 카메라가 따라갈 탄: 날고 있는 탄들의 가운데. 없으면 null.
  Vector2? get projectile {
    final all = projectiles;
    if (all.isEmpty) return null;
    final sum = Vector2.zero();
    all.forEach(sum.add);
    return sum..scale(1 / all.length);
  }

  static Vector2 _at(ShotTrace trace, double tick) {
    final last = trace.xs.length - 1;
    final t = (tick - trace.startTick).clamp(0, last.toDouble());
    final i = t.floor();
    final j = i + 1 > last ? i : i + 1;
    final f = t - i;
    return Vector2(
      Coords.x(trace.xs[i] + (trace.xs[j] - trace.xs[i]) * f),
      Coords.y(trace.ys[i] + (trace.ys[j] - trace.ys[i]) * f),
    );
  }

  static final Paint _limitPaint = Paint()..color = const Color(0xFFE8C9A0);
  static final Paint _movePaint = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    _renderLimits(canvas);
    _renderMovePreview(canvas);
    _renderAim(canvas);
    final ball = sprites.get('fx/cannonball.png');
    for (final pos in projectiles) {
      ball.render(
        canvas,
        position: pos,
        size: Vector2.all(18),
        anchor: Anchor.center,
      );
    }
  }

  void _renderAim(Canvas canvas) {
    final aim = session.aim;
    if (aim == null || !session.isHumanTurn) return;
    // 상대 턴 재생에는 궤적을 그리지 않는다 (설계서 §13.4).
    final path = session
        .previewShot(aim.slot, aim.shot.angle, aim.shot.power)
        .head(30);
    _renderRangeEnd(canvas, aim.slot, path.xs.first);
    final dot = sprites.get('fx/trajectory_dot.png');
    for (var i = 0; i <= path.lastTick; i += 2) {
      dot.render(
        canvas,
        position: Coords.point(path.xs[i], path.ys[i]),
        size: Vector2.all(8),
        anchor: Anchor.center,
      );
    }
  }

  static final Paint _rangePaint = Paint()
    ..color = const Color(0xCCFFC24A)
    ..strokeWidth = 2;

  /// 사거리 끝: 발사 지점에서 사거리(칸)만큼 앞 물 위의 점선과 부표 (설계서 §2.8).
  void _renderRangeEnd(Canvas canvas, int slot, int launchX) {
    final state = session.state;
    final side = state.activeSide;
    final range = state.sides[side].crew.pirates[slot].spec.range;
    final x = Coords.x(launchX + facingOf(side) * range.cells * cellUnit);
    for (var y = -36.0; y < 8; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), _rangePaint);
    }
    canvas.drawCircle(Offset(x, -40), 4, _rangePaint);
  }

  void _renderMovePreview(Canvas canvas) {
    final dx = session.movePreviewDx;
    if (dx == 0) return;
    final side = session.state.sides[session.state.activeSide];
    final x = Coords.x(side.bowX + dx * moveStep);
    for (var y = -40.0; y < 12; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), _movePaint);
    }
  }

  static final Paint _reef = Paint()..color = const Color(0xFF3A2E3F);
  static final Paint _rope = Paint()
    ..color = const Color(0xFFE8C9A0)
    ..strokeWidth = 1.5;
  static final Paint _buoyRed = Paint()..color = const Color(0xFFB3302B);

  /// 한계선 (설계서 §2.6): 전진 한계는 암초와 부표 줄, 후퇴 한계는 부표.
  void _renderLimits(Canvas canvas) {
    final state = session.state;
    final (lo, hi) = moveLimits(state.rules, state.turn);
    for (final side in state.sides) {
      final facing = facingOf(side.side);
      final start = startBowX(side.side);
      _renderReef(canvas, Coords.x(start + facing * hi), facing);
      _renderBuoy(canvas, Coords.x(start + facing * lo));
    }
  }

  /// 전진 한계: 물 위로 솟은 암초 두 덩이와 그 사이 부표 줄.
  void _renderReef(Canvas canvas, double x, int facing) {
    final ahead = facing * 20.0;
    canvas
      ..drawPath(
        Path()
          ..moveTo(x + ahead - 16, 6)
          ..lineTo(x + ahead - 8, -14)
          ..lineTo(x + ahead + 2, -8)
          ..lineTo(x + ahead + 12, -20)
          ..lineTo(x + ahead + 20, 6)
          ..close(),
        _reef,
      )
      ..drawLine(Offset(x - 40, -3), Offset(x + 40, -3), _rope);
    for (var d = -40.0; d <= 40; d += 20) {
      canvas.drawCircle(Offset(x + d, -3), 3.5, _limitPaint);
    }
  }

  /// 후퇴 한계: 줄무늬 부표 하나.
  void _renderBuoy(Canvas canvas, double x) {
    canvas
      ..drawRect(Rect.fromLTWH(x - 1.5, -30, 3, 26), _limitPaint)
      ..drawOval(
        Rect.fromCenter(center: Offset(x, -6), width: 16, height: 12),
        _buoyRed,
      )
      ..drawRect(Rect.fromLTWH(x - 8, -8, 16, 3), _limitPaint);
  }
}
