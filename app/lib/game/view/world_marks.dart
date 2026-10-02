import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/effect_badges.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 고유 효과의 월드 표식 (설계서 §4.8, §10.4 턴을 넘기는 효과, ADR-075·078).
/// 산호 방벽(코리), 수면에 뜬 기뢰(젤리), 봉쇄된 선실(킹)·묶인 배(모비)의 자물쇠를
/// 시뮬레이션 상태에서 그리기만 한다.
class WorldMarks extends Component {
  WorldMarks({required this.session, required this.ships, super.priority});

  final BattleSession session;
  final List<ShipView> ships;

  /// 남은 턴 수 글자. 화면이 로케일 숫자 형식으로 바꿔 넣는다.
  String Function(int turns) turnsText = (turns) => '$turns';

  double _t = 0;

  static const double wallWidth = 12;
  static final Paint _coral = Paint()..color = const Color(0xFFF07A5F);
  static final Paint _coralDark = Paint()
    ..color = const Color(0xFF9C3B2B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _mine = Paint()..color = const Color(0xFF7FD3E8);
  static final Paint _mineRing = Paint()
    ..color = const Color(0xFF1E5E74)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final Paint _lock = Paint()..color = const Color(0xFFFFC24A);
  static final Paint _lockLine = Paint()
    ..color = const Color(0xFF14161C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final Paint _shackle = Paint()
    ..color = const Color(0xFF14161C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final state = session.state;
    for (final b in state.barriers) {
      _wall(canvas, b);
    }
    for (final e in state.effects) {
      if (e.kind == EffectKind.floatMine) _floatMine(canvas, e);
    }
    for (var side = 0; side < state.sides.length; side++) {
      _locks(canvas, side);
    }
  }

  /// 산호 방벽: 해수면부터 꼭대기까지 세로 기둥, 꼭대기에 남은 턴 배지.
  void _wall(Canvas canvas, Barrier b) {
    final x = Coords.x(b.x);
    final top = Coords.y(b.top);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(x - wallWidth / 2, top, x + wallWidth / 2, 0),
      const Radius.circular(5),
    );
    canvas
      ..drawRRect(rect, _coral)
      ..drawRRect(rect, _coralDark);
    for (var y = top + 10; y < -4; y += 14) {
      canvas.drawCircle(Offset(x + (y % 28 == 0 ? 5 : -5), y), 3, _coralDark);
    }
    EffectBadges.drawBadge(
      canvas,
      Vector2(x, top - 10),
      turnsText(b.turnsLeft),
    );
  }

  /// 떠 있는 기뢰: 수면에서 까딱이는 공과 가시, 위에 남은 턴 배지.
  void _floatMine(Canvas canvas, TurnEffect e) {
    final x = Coords.x(e.x);
    final y = -4 + math.sin(_t * 2.4 + x * 0.01) * 2;
    final c = Offset(x, y);
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3;
      canvas.drawLine(
        c,
        c + Offset(math.cos(a) * 9, math.sin(a) * 9),
        _mineRing,
      );
    }
    canvas
      ..drawCircle(c, 6, _mine)
      ..drawCircle(c, 6, _mineRing);
    EffectBadges.drawBadge(canvas, Vector2(x, y - 16), turnsText(e.turnsLeft));
  }

  /// 이번 턴이나 다음 턴에 걸린 봉쇄·이동 불가의 자물쇠.
  void _locks(Canvas canvas, int side) {
    final ship = session.state.sides[side];
    final turn = session.state.turn;
    final status = ship.status;
    bool soon(int t) => t == turn || t == turn + 1;
    if (soon(status.sealTurn) && status.sealedSlot >= 0) {
      final view = ships[side];
      final feet = view.cabinFeet(status.sealedSlot);
      _padlock(canvas, view.absolutePositionOf(feet - Vector2(0, 18)));
    }
    if (soon(status.moveLockTurn)) {
      _padlock(canvas, ships[side].position + Vector2(0, -8));
    }
  }

  static void _padlock(Canvas canvas, Vector2 at) {
    final body = Rect.fromCenter(
      center: at.toOffset() + const Offset(0, 3),
      width: 14,
      height: 11,
    );
    canvas
      ..drawArc(
        Rect.fromCenter(
          center: at.toOffset() - const Offset(0, 2),
          width: 9,
          height: 10,
        ),
        math.pi,
        math.pi,
        false,
        _shackle,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(2)),
        _lock,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(2)),
        _lockLine,
      );
  }
}
