import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/coords.dart';

/// 직전 착탄 표시 (설계서 §2.2, A37): 사람이 쏜 직전 한 발이 떨어진 자리를 그
/// 진영의 다음 턴 동안 흐린 고리로 남긴다. 새로 쏘면 그 발로 바뀐다. AI 의 착탄은
/// 남기지 않고, 궤적 점선(앞 20%) 규칙은 그대로다. 그리기만 한다.
class LastImpactMark extends Component {
  LastImpactMark({required this.session, super.priority});

  final BattleSession session;

  /// 진영별 직전 착탄 자리(월드 px). 없으면 null.
  final List<Vector2?> _last = [null, null];

  ShotPlayback? _seen;

  /// [side] 의 직전 착탄 자리. 테스트가 본다.
  Vector2? lastOf(int side) => _last[side];

  /// 지금 보이는 자리: 사람 진영의 턴이고, 그 진영이 쏜 탄이 날지 않을 때.
  Vector2? get shown {
    final side = session.state.activeSide;
    if (session.isOver || !session.humanSides.contains(side)) return null;
    final p = session.playback;
    if (p is ShotPlayback && p.side == side) return null;
    return _last[side];
  }

  @override
  void update(double dt) {
    final p = session.playback;
    if (p is! ShotPlayback || identical(p, _seen) || p.awaitingTap) return;
    if (!session.humanSides.contains(p.side) || p.traces.isEmpty) return;
    final t = p.traces.first;
    if (t.xs.isEmpty) return;
    _seen = p;
    _last[p.side] = Coords.point(t.xs.last, t.ys.last);
  }

  static final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0x8CFFFFFF);
  static final Paint _cross = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..color = const Color(0x8CFFFFFF);

  @override
  void render(Canvas canvas) {
    final at = shown;
    if (at == null) return;
    final c = Offset(at.x, at.y);
    const r = 9.0;
    canvas
      ..drawCircle(c, r, _ring)
      ..drawLine(c + const Offset(-4, -4), c + const Offset(4, 4), _cross)
      ..drawLine(c + const Offset(-4, 4), c + const Offset(4, -4), _cross);
  }
}
