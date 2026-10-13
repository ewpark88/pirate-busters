import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pirate_busters/game/view/sea_crests.dart';
import 'package:pirate_busters/game/view/sea_shape.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/wind_feel.dart';

/// 전장 가로 범위(월드 px). 월드 ±100칸보다 넓게 그린다.
const double seaHalfWidth = 3600;
const double seaDepth = 900;

/// 바다 (설계서 §10.2): 사인파 격자 + 큰 너울·물마루 + 포말 파티클(배 둘레
/// 물갈림·이동 항적) + 앞쪽은 측면 굴절 셰이더.
///
/// 수면 높이는 [swell] 로 두 배의 파도 위아래(시뮬레이션 값)를 따라 오르내려 배와
/// 물이 어긋나지 않는다. [front] 면 배 앞에 얇은 물 막으로 그린다. 잠긴 선체의
/// 물빛은 배가 직접 그린다(`HullWater`, A24). [shape] 가 있으면 너울 꼭대기에 흰
/// 물마루를, 배 앞뒤에 물갈림을, 움직이는 배 뒤에 항적을 그린다.
/// [lowEnd] 가 켜져 있거나 셰이더를 쓸 수 없으면 그라데이션으로 그리고 항적을 끈다
/// (ADR-030).
///
/// 파도 구간(§2.6): 잔물결·포말·물마루가 그 자리 구간 세기를 따른다. 잔잔한 구간은
/// 평평하고 포말이 거의 없고, 거친 구간은 물마루가 많다. 바람(§2.4, [wind]): 포말이
/// 바람 쪽으로 흐르고 늘어나며, 물마루가 바람 쪽으로 눕는다.
class SeaView extends Component {
  SeaView({
    required this.front,
    required this.theme,
    this.swell,
    this.shape,
    this.shader,
    this.lowEnd,
    this.wind,
    super.priority,
  });

  final bool front;
  final SeaTheme theme;
  final double Function(double x)? swell;
  final SeaShape? shape;
  final FragmentShader? shader;
  final ValueListenable<bool>? lowEnd;
  final WindFeel? wind;
  final math.Random _rnd = math.Random(3);
  final List<_Foam> _foam = [];
  final List<_Foam> _wake = [];
  double _t = 0;

  /// 포말 수. 저사양 모드에서는 절반 (설계서 §12).
  int get foamTarget => (lowEnd?.value ?? false) ? 70 : 140;

  @visibleForTesting
  int get foamCount => _foam.length;

  /// 배 둘레 물갈림·항적 포말 수.
  @visibleForTesting
  int get wakeCount => _wake.length;

  bool get _low => lowEnd?.value ?? false;

  @override
  void update(double dt) {
    _t += dt;
    if (!front) return;
    for (final f in _foam) {
      f
        ..life -= dt
        ..x += f.vx * dt;
    }
    _foam.removeWhere((f) => f.life <= 0);
    _updateWake(dt);
    final drift = SeaCrests.foamDrift(wind?.value ?? 0);
    while (_foam.length < foamTarget) {
      _foam.add(
        _Foam(
          x: _foamX(),
          vx: drift + (_rnd.nextDouble() - 0.5) * 8,
          life: 1 + _rnd.nextDouble() * 2.5,
        ),
      );
    }
  }

  /// 새 포말 x: 거친 구간일수록 자주 고른다.
  double _foamX() {
    var x = 0.0;
    for (var i = 0; i < 6; i++) {
      x = (_rnd.nextDouble() * 2 - 1) * seaHalfWidth;
      if (_rnd.nextDouble() < SeaCrests.foamWeight(_level(x))) break;
    }
    return x;
  }

  double _level(double x) => shape?.levelAt(x) ?? 1;

  /// 배 앞뒤 끝 물갈림(늘 조금)과 움직이는 배 선미 뒤 항적(저사양이면 끔).
  void _updateWake(double dt) {
    for (final f in _wake) {
      f
        ..life -= dt
        ..x += f.vx * dt;
    }
    _wake.removeWhere((f) => f.life <= 0);
    for (final ship in shape?.current ?? const <ShipOnSea>[]) {
      for (final end in const [-1, 1]) {
        if (_rnd.nextDouble() < dt * 6) {
          _wake.add(
            _Foam(
              x: ship.x + end * (ship.half + _rnd.nextDouble() * 10),
              vx: end * (4 + _rnd.nextDouble() * 8),
              life: .6 + _rnd.nextDouble() * .6,
            ),
          );
        }
      }
      if (!ship.moving || _low) continue;
      final stern = ship.x - ship.facing * ship.half;
      for (var i = 0; i < 3; i++) {
        _wake.add(
          _Foam(
            x: stern - ship.facing * _rnd.nextDouble() * 24,
            vx: -ship.facing * (10 + _rnd.nextDouble() * 18),
            life: 1.2 + _rnd.nextDouble() * 1.4,
          ),
        );
      }
    }
  }

  /// 수면 높이(월드 px, 아래가 +).
  double surface(double x) =>
      (swell?.call(x) ?? 0) +
      SeaCrests.rippleFor(_level(x)) *
          (math.sin(x / 90 + _t * 1.3) * 1.6 +
              math.sin(x / 37 - _t * 2.1) * 0.7);

  // 매 프레임 다시 쓰는 그리기 도구 (A57, 할당 줄이기).
  final Path _path = Path();
  final Path _line = Path();
  final Paint _fill = Paint();
  final Paint _foamPaint = Paint();
  final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  Shader? _gradient;
  SeaTheme? _gradientTheme;

  @override
  void render(Canvas canvas) {
    final path = _path
      ..reset()
      ..moveTo(-seaHalfWidth, seaDepth);
    for (var x = -seaHalfWidth; x <= seaHalfWidth; x += 24) {
      path.lineTo(x, surface(x));
    }
    path
      ..lineTo(seaHalfWidth, seaDepth)
      ..close();
    final fx = shader;
    if (front && fx != null && !_low) {
      // FlutterFragCoord 는 캔버스 로컬(= 월드 px) 좌표라 해수면 0, 배율 1 이다.
      fx
        ..setFloat(0, _t)
        ..setFloat(1, 0)
        ..setFloat(2, 0)
        ..setFloat(3, 1);
      var i = 4;
      for (var k = 0; k <= theme.sea.length; k++) {
        final c = k < theme.sea.length ? theme.sea[k] : theme.foam;
        fx
          ..setFloat(i++, c.r)
          ..setFloat(i++, c.g)
          ..setFloat(i++, c.b);
      }
      canvas.drawPath(path, _fill..shader = fx);
    } else {
      _renderGradient(canvas, path);
    }
    if (!front) return;
    _renderLattice(canvas);
    final foam = _foamPaint;
    // 포말은 바람 쪽으로 늘어난다.
    final stretch = 2.2 * (1 + 0.7 * (wind?.strength ?? 0));
    for (final f in _foam) {
      foam.color = theme.foam.withValues(alpha: (f.life / 1.5).clamp(0, 0.8));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(f.x, surface(f.x) + 1),
          width: stretch * 2,
          height: 4.4,
        ),
        foam,
      );
    }
    for (final f in _wake) {
      foam.color = theme.foam.withValues(alpha: (f.life / 1.2).clamp(0, 0.9));
      canvas.drawCircle(Offset(f.x, surface(f.x) + 1), 2.8, foam);
    }
    _renderCrests(canvas, foam);
  }

  /// 너울 꼭대기의 흰 물마루: 배 둘레와 잔잔한 구간에는 없다. 보통 구간은 둘에
  /// 하나, 거친 구간은 모든 꼭대기에 선다. 바람이 불면 바람 쪽으로 눕는다.
  void _renderCrests(Canvas canvas, Paint foam) {
    final sea = shape;
    if (sea == null) return;
    final ships = sea.current;
    final lean = (wind?.value ?? 0) / 3;
    for (final x in sea.crests(-seaHalfWidth, seaHalfWidth)) {
      final w = SeaShape.calm(ships, x);
      final level = sea.levelAt(x);
      if (!SeaCrests.shown(level, x) || w < .4) continue;
      foam.color = theme.foam.withValues(
        alpha: .55 * w * math.min(1, level / 1.5),
      );
      for (final (dx, lift, r) in SeaCrests.dots(lean)) {
        final cx = x + dx;
        canvas.drawCircle(Offset(cx, surface(cx) + 1 - lift), r, foam);
      }
    }
  }

  /// 수면 아래 사인파 격자: 깊어질수록 옅어진다.
  void _renderLattice(Canvas canvas) {
    final line = _linePaint;
    for (final (depth, alpha) in const [
      (18.0, .22),
      (44.0, .15),
      (86.0, .09),
    ]) {
      line.color = theme.foam.withValues(alpha: alpha);
      final p = _line
        ..reset()
        ..moveTo(-seaHalfWidth, surface(-seaHalfWidth) + depth);
      for (var x = -seaHalfWidth; x <= seaHalfWidth; x += 32) {
        final wave = math.sin(x / 55 + _t * 1.1 + depth) * 3;
        p.lineTo(x, surface(x) + depth + wave);
      }
      canvas.drawPath(p, line);
    }
  }

  void _renderGradient(Canvas canvas, Path path) {
    const rect = Rect.fromLTWH(-seaHalfWidth, 0, seaHalfWidth * 2, seaDepth);
    // 테마가 같으면 그라데이션을 다시 만들지 않는다 (A57).
    if (_gradient == null || !identical(_gradientTheme, theme)) {
      _gradientTheme = theme;
      _gradient = Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        // 앞 바다는 얇은 막: 잠긴 선체가 비쳐 보인다 (A24).
        [for (final c in theme.sea) c.withValues(alpha: front ? 0.32 : 1)],
        const [0, 0.35, 1],
      );
    }
    canvas.drawPath(path, _fill..shader = _gradient);
  }
}

class _Foam {
  _Foam({required this.x, required this.vx, required this.life});

  double x;
  final double vx;
  double life;
}
