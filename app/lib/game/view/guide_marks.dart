import 'dart:ui';

import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/coords.dart';

/// 물 위 안내 점선: 이동 끝 지점(설계서 §2.5). 시뮬레이션 값으로 그리기만 한다.
abstract final class GuideMarks {
  static final Paint _movePaint = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..strokeWidth = 2;

  /// 이동 끝 지점 점선: 버튼을 누르는 동안 갈 곳 (설계서 §2.5).
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
