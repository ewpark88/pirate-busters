import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 상대가 조준하는 해적 강조 (설계서 §2.3 “상대의 조준 과정을 그대로 보여주되 궤적
/// 점선은 숨긴다”, §13.4, A34). 조준 진행에 맞춰 붉은 조준 고리가 좁혀 들고, 머리
/// 위에 붉은 화살표가 까딱인다. 궤적·힘은 보이지 않는다. 그리기만 한다.
class FoeAimMark extends Component {
  FoeAimMark({required this.session, required this.ships, super.priority});

  final BattleSession session;
  final List<ShipView> ships;

  double _t = 0;

  static final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..color = const Color(0xFFE5483A);
  static final Paint _arrow = Paint()..color = const Color(0xFFE5483A);
  static final Paint _edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = const Color(0xFF3A0E08);

  /// 지금 강조하는 (진영, 슬롯). 없으면 null. 테스트가 본다.
  (int, int)? get target {
    final aim = session.opponentAim;
    if (aim == null) return null;
    return (session.state.activeSide, aim.slot);
  }

  /// 조준 고리 반지름: 진행 [progress] 0 → 1 에 따라 넓게에서 몸에 맞게 좁혀 든다.
  static double ringRadius(double progress) =>
      Coords.pirateHeight * (1.1 - 0.45 * progress.clamp(0, 1));

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final aim = session.opponentAim;
    final at = target;
    if (aim == null || at == null) return;
    final (side, slot) = at;
    if (side >= ships.length || slot >= ships[side].rigs.length) return;
    final rig = ships[side].rigs[slot];
    final body = rig.absolutePosition - Vector2(0, Coords.pirateHeight * .5);
    final r = ringRadius(aim.progress);
    final c = Offset(body.x, body.y);
    canvas
      ..drawCircle(c, r, _ring)
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(_t * 1.6);
    // 고리에 걸친 조준 눈금 네 개.
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(d * (r - 5), d * (r + 5), _ring);
    }
    canvas.restore();
    final bob = math.sin(_t * 6) * 3;
    final tip = Offset(c.dx, c.dy - Coords.pirateHeight * 1.05 + bob);
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 7, tip.dy - 10)
      ..lineTo(tip.dx + 7, tip.dy - 10)
      ..close();
    canvas
      ..drawPath(arrow, _arrow)
      ..drawPath(arrow, _edge);
  }
}
