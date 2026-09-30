import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/sprites.dart';

/// 날아가는 탄, 조준 궤적(앞 30% 점선), 이동 끝 지점 점선, 이동 한계 부표.
/// 모두 시뮬레이션 값으로 그린다 (개발 계획서 M4).
class ShotView extends Component {
  ShotView({required this.session, required this.sprites, super.priority});

  final BattleSession session;
  final BattleSprites sprites;

  /// 탄의 지금 월드 위치. 카메라가 따라간다. 날아가는 탄이 없으면 null.
  Vector2? get projectile {
    final p = session.playback;
    if (p is! ShotPlayback || p.landed) return null;
    final path = p.path;
    final t = p.tick.clamp(0, path.lastTick.toDouble());
    final i = t.floor();
    final j = i + 1 > path.lastTick ? i : i + 1;
    final f = t - i;
    return Vector2(
      Coords.x(path.xs[i] + (path.xs[j] - path.xs[i]) * f),
      Coords.y(path.ys[i] + (path.ys[j] - path.ys[i]) * f),
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
    final pos = projectile;
    if (pos != null) {
      sprites
          .get('fx/cannonball.png')
          .render(
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

  void _renderMovePreview(Canvas canvas) {
    final dx = session.movePreviewDx;
    if (dx == 0) return;
    final side = session.state.sides[session.state.activeSide];
    final x = Coords.x(side.bowX + dx * moveStep);
    for (var y = -40.0; y < 12; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), _movePaint);
    }
  }

  /// 전진·후퇴 한계 부표 (설계서 §2.6).
  void _renderLimits(Canvas canvas) {
    final state = session.state;
    final (lo, hi) = moveLimits(state.rules, state.turn);
    for (final side in state.sides) {
      final facing = facingOf(side.side);
      final start = startBowX(side.side);
      for (final off in [lo, hi]) {
        final x = Coords.x(start + facing * off);
        canvas
          ..drawCircle(Offset(x, -4), 6, _limitPaint)
          ..drawRect(Rect.fromLTWH(x - 1, -22, 2, 18), _limitPaint);
      }
    }
  }
}
