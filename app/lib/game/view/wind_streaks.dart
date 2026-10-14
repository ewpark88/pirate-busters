import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/view/sea_view.dart';
import 'package:pirate_busters/game/view/wind_feel.dart';

/// 전장 하늘의 바람 줄 (설계서 §2.4·§10.2 ‘바람’, A35): 바람 방향으로 가는 줄이
/// 흐른다. 단계가 높을수록 줄이 많고 빠르고 길며, 무풍이면 없다. [feel] 이 있으면
/// 구름·포말·물보라와 같은 부드러운 바람을 따라 턴이 바뀔 때 한 번에 꺾이지 않는다. 저사양이면 줄 수를 절반으로 줄인다. 그리기만 한다.
class WindStreaks extends Component {
  WindStreaks({
    required this.session,
    this.feel,
    this.lowEnd,
    super.priority,
  });

  final BattleSession session;

  /// 부드럽게 따라가는 바람. 없으면 지금 턴 바람을 그대로 쓴다.
  final WindFeel? feel;
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

  /// 지금 느끼는 바람(−3~+3).
  double get _value => feel?.value ?? session.state.wind.toDouble();

  int get _wind => _value.round();

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
    final w = _value;
    final v = w.abs() < .05 ? 0.0 : w.sign * (70 + 90 * w.abs()) * dt;
    for (final s in _streaks) {
      s.x += v * s.pace;
      if (s.x > seaHalfWidth) s.x -= seaHalfWidth * 2;
      if (s.x < -seaHalfWidth) s.x += seaHalfWidth * 2;
    }
  }

  // 바람 단계가 바뀔 때만 다시 만드는 줄 모양 (A57 방식, 매 프레임 할당 없음).
  int? _shapeFor;
  final Path _path = Path();
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;

  /// 줄 한 개: 머리가 원점, 꼬리가 바람 반대쪽.
  void _shape(int wind) {
    if (_shapeFor == wind) return;
    _shapeFor = wind;
    final dir = wind.sign.toDouble();
    final len = lengthFor(wind);
    _path
      ..reset()
      ..moveTo(-dir * len, 0)
      ..quadraticBezierTo(-dir * len / 2, -4, 0, 0);
    _paint.shader = Gradient.linear(Offset(-dir * len, 0), Offset.zero, const [
      Color(0x00FFFFFF),
      Color(0xC0FFFFFF),
    ]);
  }

  @override
  void render(Canvas canvas) {
    if (_streaks.isEmpty) return;
    _shape(_wind);
    for (final s in _streaks) {
      final wobble = math.sin(_t * 2 + s.phase) * 3;
      canvas
        ..save()
        ..translate(s.x, s.y + wobble)
        ..scale(s.pace, 1)
        ..drawPath(_path, _paint)
        ..restore();
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
