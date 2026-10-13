import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/sea_shape.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';

/// 물 위 이동 안내 (설계서 §2.5 “이동 버튼을 누르고 있으면 갈 수 있는 끝 지점이 물
/// 위에 점선으로 보인다”). 뱃머리에서 끝 지점까지 수면을 따라 점선을 긋고, 끝에
/// 작은 부표를 세운다. 부표 머리 색은 그 자리 파도 구간 물빛이라 잔잔한 구간에
/// 들어가는지 미리 보인다. 상대 배 앞에서 막히면 멈춤 막대 두 줄을 더 그린다.
/// 시뮬레이션 값(`moveReach`)으로 그리기만 한다.
class GuideMarks extends Component {
  GuideMarks({
    required this.session,
    required this.sea,
    required this.theme,
    super.priority,
  });

  final BattleSession session;
  final SeaShape sea;
  final SeaTheme theme;

  /// 점선 점 간격(월드 px).
  static const double dotGap = 10;

  final Paint _dot = Paint()..color = const Color(0xE6FFFFFF);
  final Paint _pole = Paint()
    ..color = const Color(0xFF3A2414)
    ..strokeWidth = 2.4;
  final Paint _head = Paint();
  final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..color = const Color(0xFF14202B);
  final Paint _stop = Paint()
    ..color = const Color(0xFFFF5A4A)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;

  /// 끝 지점의 월드 x(px): 지금 진영 뱃머리에서 [dx](1/10칸, 전진 +)만큼.
  static double endX(SideState side, int dx) =>
      Coords.x(side.bowX + facingOf(side.side) * dx * moveStep);

  /// 세기 [level] 구간 부표 머리 색.
  Color headColor(int level) => switch (level) {
    0 => theme.calmTint.withValues(alpha: 1),
    1 => theme.foam,
    _ => theme.roughTint.withValues(alpha: 1),
  };

  @override
  void render(Canvas canvas) {
    final dx = session.movePreviewDx;
    if (dx == 0) return;
    final side = session.state.sides[session.state.activeSide];
    final from = Coords.x(side.bowX);
    final to = endX(side, dx);
    final step = to > from ? dotGap : -dotGap;
    for (var x = from + step; (to - x) * step.sign > 0; x += step) {
      canvas.drawCircle(Offset(x, sea(x) - 3), 1.8, _dot);
    }
    final y = sea(to);
    final head = Offset(to, y - 22);
    canvas
      ..drawLine(Offset(to, y + 4), head, _pole)
      ..drawCircle(
        head,
        5,
        _head..color = headColor(sea.zones?.levelAt(to) ?? 1),
      )
      ..drawCircle(head, 5, _ring);
    if (session.moveStopFor(dx.sign) == MoveStop.foe) {
      // 상대 배 쪽으로 멈춤 막대 두 줄.
      final f = facingOf(side.side) * dx.sign * 8.0;
      for (final k in const [1.0, 1.6]) {
        canvas.drawLine(
          Offset(to + f * k, y - 18),
          Offset(to + f * k, y + 2),
          _stop,
        );
      }
    }
  }
}
