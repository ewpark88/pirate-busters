import 'dart:ui';

import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/coords.dart';

/// 물 위 안내 점선: 사거리 끝(설계서 §2.8)과 이동 끝 지점(§2.6). 시뮬레이션 값으로
/// 그리기만 한다.
abstract final class GuideMarks {
  static final Paint _movePaint = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..strokeWidth = 2;

  static final Paint _rangePaint = Paint()
    ..color = const Color(0xCCFFC24A)
    ..strokeWidth = 2;

  /// 사거리 끝: 발사 지점에서 사거리(칸)만큼 앞 물 위의 점선과 부표 (설계서 §2.8).
  static void rangeEnd(
    Canvas canvas,
    BattleSession session,
    int slot,
    int launchX,
  ) {
    final state = session.state;
    final side = state.activeSide;
    final range = state.sides[side].crew.pirates[slot].spec.range;
    final x = Coords.x(launchX + facingOf(side) * range.cells * cellUnit);
    for (var y = -36.0; y < 8; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), _rangePaint);
    }
    canvas.drawCircle(Offset(x, -40), 4, _rangePaint);
  }

  /// 이동 끝 지점 점선: 버튼을 누르는 동안 갈 곳 (설계서 §2.6).
  static void movePreview(Canvas canvas, BattleSession session) {
    final dx = session.movePreviewDx;
    if (dx == 0) return;
    final side = session.state.sides[session.state.activeSide];
    final x = Coords.x(side.bowX + dx * moveStep);
    for (var y = -40.0; y < 12; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), _movePaint);
    }
  }
}
