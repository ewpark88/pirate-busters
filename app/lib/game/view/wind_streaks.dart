import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/view/sea_view.dart';

/// 전장 하늘의 바람 줄 (설계서 §2.3·§10.2 ‘바람’, A35): 지금 턴 바람(역풍·무풍
/// 상태 적용, §4.8) 방향으로 가는 줄이 흐른다. 단계가 높을수록 줄이 많고 빠르고
/// 길며, 무풍이면 없다. 저사양이면 줄 수를 절반으로 줄인다. 그리기만 한다.
class WindStreaks extends Component {
  WindStreaks({required this.session, this.lowEnd, super.priority});

  final BattleSession session;
  final ValueListenable<bool>? lowEnd;

  /// 단계당 줄 수(전장 전체), 하늘 높이 범위(월드 px, 위가 −).
  static const int perLevel = 22;
  static const double skyTop = -760;
  static const double skyBottom = -70;

  final math.Random _rnd = math.Random(11);
  final List<_Streak> _streaks = [];
  double _t = 0;

  /// [level] 단계 바람의 줄 수 (저사양 [low] 이면 절반).
  static int countFor(int level, {required bool low}) {
    final n = level.abs() * perLevel;
    return low ? n ~/ 2 : n;
  }

  /// [level] 단계 바람 줄이 흐르는 빠르기(월드 px/초)와 길이(월드 px).
  static double speedFor(int level) => 70 + 90.0 * level.abs();
  static double lengthFor(int level) => 26 + 18.0 * level.abs();

  /// 지금 보이는 줄 수. 테스트가 본다.
  @visibleForTesting
  int get count => _streaks.length;

  int get _wind => session.state.wind;

  @override
  void update(double dt) {
    _t += dt;
    final want = countFor(_wind, low: lowEnd?.value ?? false);
    while (_streaks.length > want) {
      _streaks.removeLast();
    }
    while (_streaks.length < want) {
      _streaks.add(
        _Streak(
          x: (_rnd.nextDouble() * 2 - 1) * seaHalfWidth,
          y: skyBottom + (skyTop - skyBottom) * _rnd.nextDouble(),
          phase: _rnd.nextDouble() * math.pi * 2,
          pace: .7 + _rnd.nextDouble() * .6,
        ),
      );
    }
    final v = _wind.sign * speedFor(_wind) * dt;
    for (final s in _streaks) {
      s.x += v * s.pace;
      if (s.x > seaHalfWidth) s.x -= seaHalfWidth * 2;
      if (s.x < -seaHalfWidth) s.x += seaHalfWidth * 2;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_streaks.isEmpty) return;
    final dir = _wind.sign.toDouble();
    final len = lengthFor(_wind);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final s in _streaks) {
      final wobble = math.sin(_t * 2 + s.phase) * 3;
      final head = Offset(s.x, s.y + wobble);
      final tail = head - Offset(dir * len * s.pace, 0);
      paint.shader = Gradient.linear(tail, head, const [
        Color(0x00FFFFFF),
        Color(0xC0FFFFFF),
      ]);
      canvas.drawPath(
        Path()
          ..moveTo(tail.dx, tail.dy)
          ..quadraticBezierTo(
            (tail.dx + head.dx) / 2,
            head.dy - 4,
            head.dx,
            head.dy,
          ),
        paint,
      );
    }
  }
}

class _Streak {
  _Streak({
    required this.x,
    required this.y,
    required this.phase,
    required this.pace,
  });

  double x;
  final double y;
  final double phase;
  final double pace;
}
