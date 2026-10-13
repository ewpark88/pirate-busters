import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pirate_busters/game/view/sea_shape.dart';
import 'package:pirate_busters/game/view/sea_view.dart';
import 'package:pirate_busters/game/view/wind_feel.dart';

/// 바람 물보라 (설계서 §2.4 “바람이 셀수록 물보라가 날린다”, §10.2).
///
/// 바람 2단계 이상이면 파도가 있는 구간의 물마루 꼭대기에서 작은 물방울이 바람
/// 쪽으로 날려 짧은 포물선을 그린다. 단계가 높을수록 많다. 저사양이면 절반이다.
/// 점 하나씩이라 매 프레임 할당이 없다. 그리기 전용이라 판정과 무관하다.
class WindSpray extends Component {
  WindSpray({
    required this.shape,
    required this.wind,
    this.lowEnd,
    super.priority,
  });

  final SeaShape shape;
  final WindFeel wind;
  final ValueListenable<bool>? lowEnd;

  final math.Random _rnd = math.Random(23);
  final List<_Drop> _drops = [];
  double _due = 0;

  /// 바람 [level] 단계에서 동시에 날리는 물방울 상한 (저사양 [low] 이면 절반).
  static int capFor(int level, {required bool low}) {
    final n = switch (level.abs()) {
      >= 3 => 48,
      2 => 24,
      _ => 0,
    };
    return low ? n ~/ 2 : n;
  }

  /// 지금 날리는 물방울 수. 테스트가 본다.
  @visibleForTesting
  int get count => _drops.length;

  static const double gravity = 260;

  @override
  void update(double dt) {
    for (final d in _drops) {
      d
        ..life -= dt
        ..x += d.vx * dt
        ..y += d.vy * dt
        ..vy += gravity * dt;
    }
    _drops.removeWhere((d) => d.life <= 0);
    final level = wind.value.round();
    final cap = capFor(level, low: lowEnd?.value ?? false);
    if (cap == 0) return;
    // 물마루 하나에서 한 번에 두세 방울씩, 상한까지 고르게 채운다.
    _due += dt * cap * 1.6;
    // 더 띄울 수 없으면 물마루 목록을 만들지 않는다(매 프레임 할당 줄이기).
    if (_drops.length >= cap) {
      if (_due > 4) _due = 0;
      return;
    }
    if (_due < 1) return;
    final crests = shape.crests(-seaHalfWidth, seaHalfWidth).toList();
    if (crests.isEmpty) return;
    while (_due >= 1 && _drops.length < cap) {
      _due -= 1;
      final x = crests[_rnd.nextInt(crests.length)];
      if (shape.levelAt(x) < .6) continue;
      if (SeaShape.calm(shape.current, x) < .5) continue;
      _drops.add(
        _Drop(
          x: x + (_rnd.nextDouble() - .5) * 30,
          y: shape(x) - 2,
          vx: level.sign * (60 + _rnd.nextDouble() * 80),
          vy: -40 - _rnd.nextDouble() * 50,
          life: .6 + _rnd.nextDouble() * .4,
        ),
      );
    }
    if (_due > 4) _due = 0;
  }

  final Paint _paint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.4;

  @override
  void render(Canvas canvas) {
    for (final d in _drops) {
      _paint.color = Color.fromRGBO(244, 251, 255, (d.life * 1.2).clamp(0, .8));
      canvas.drawLine(
        Offset(d.x, d.y),
        Offset(d.x - d.vx * .03, d.y - d.vy * .03),
        _paint,
      );
    }
  }
}

class _Drop {
  _Drop({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
  });

  double x;
  double y;
  final double vx;
  double vy;
  double life;
}
