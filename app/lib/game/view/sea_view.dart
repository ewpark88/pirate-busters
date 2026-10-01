import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';

/// 전장 가로 범위(월드 px). 월드 ±100칸보다 넓게 그린다.
const double seaHalfWidth = 3600;
const double seaDepth = 900;

/// 화면에 고정된 하늘 그라데이션과 해 (설계서 §10.2).
class SkyBackdrop extends Component with HasGameReference<FlameGame> {
  SkyBackdrop(this.theme);

  final SeaTheme theme;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final rect = Offset.zero & Size(size.x, size.y);
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            theme.sky,
            [
              for (var i = 0; i < theme.sky.length; i++)
                i / (theme.sky.length - 1),
            ],
          ),
      )
      ..drawCircle(
        Offset(size.x * 0.78, size.y * 0.2),
        size.y * 0.07,
        Paint()..color = theme.sun,
      );
  }
}

/// 원경 한 겹(섬·등대·구름): 카메라보다 [factor] 배 느리게 움직인다(시차).
class ParallaxScenery extends PositionComponent
    with HasGameReference<FlameGame> {
  ParallaxScenery({
    required this.theme,
    required this.factor,
    required this.seed,
    super.priority,
  });

  final SeaTheme theme;

  /// 0 이면 화면에 붙고 1 이면 전장과 같이 움직인다.
  final double factor;
  final int seed;

  @override
  void update(double dt) {
    final cam = game.camera.viewfinder.position;
    position.setValues(cam.x * (1 - factor), cam.y * (1 - factor) * 0.3);
  }

  @override
  void render(Canvas canvas) {
    final land = Paint()..color = factor < 0.3 ? theme.farLand : theme.nearLand;
    final cloud = Paint()..color = theme.cloud;
    final light = Paint()..color = theme.light;
    for (var i = -8; i <= 8; i++) {
      final h = ((i * 37 + seed * 11) % 7 + 3) * 14.0;
      final x = i * 460.0 + seed * 90;
      canvas.drawPath(
        Path()
          ..moveTo(x - 160, 0)
          ..quadraticBezierTo(x - 60, -h, x + 20, -h * 0.7)
          ..quadraticBezierTo(x + 90, -h * 1.1, x + 170, 0)
          ..close(),
        land,
      );
      if ((i + seed).isEven) {
        canvas
          ..drawRect(Rect.fromLTWH(x + 10, -h - 40, 10, 40), land)
          ..drawCircle(Offset(x + 15, -h - 44), 5, light);
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + 200, -260 - h),
          width: 180,
          height: 36,
        ),
        cloud,
      );
    }
  }
}

/// 바다 (설계서 §10.2): 사인파 격자 + 포말 파티클 + 앞쪽은 측면 굴절 셰이더.
///
/// 수면 높이는 [swell] 로 두 배의 파도 위아래(시뮬레이션 값)를 따라 오르내려 배와
/// 물이 어긋나지 않는다. [front] 면 배 앞에 반투명으로 그려 잠긴 부분을 덮는다.
/// [lowEnd] 가 켜져 있거나 셰이더를 쓸 수 없으면 그라데이션으로 그린다 (ADR-030).
class SeaView extends Component {
  SeaView({
    required this.front,
    required this.theme,
    this.swell,
    this.shader,
    this.lowEnd,
    super.priority,
  });

  final bool front;
  final SeaTheme theme;
  final double Function(double x)? swell;
  final FragmentShader? shader;
  final ValueListenable<bool>? lowEnd;
  final math.Random _rnd = math.Random(3);
  final List<_Foam> _foam = [];
  double _t = 0;

  /// 포말 수. 저사양 모드에서는 절반 (설계서 §12).
  int get foamTarget => (lowEnd?.value ?? false) ? 70 : 140;

  @visibleForTesting
  int get foamCount => _foam.length;

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
    while (_foam.length < foamTarget) {
      _foam.add(
        _Foam(
          x: (_rnd.nextDouble() * 2 - 1) * seaHalfWidth,
          vx: (_rnd.nextDouble() - 0.5) * 16,
          life: 1 + _rnd.nextDouble() * 2.5,
        ),
      );
    }
  }

  /// 수면 높이(월드 px, 아래가 +).
  double surface(double x) =>
      (swell?.call(x) ?? 0) +
      math.sin(x / 90 + _t * 1.3) * 1.6 +
      math.sin(x / 37 - _t * 2.1) * 0.7;

  @override
  void render(Canvas canvas) {
    final path = Path()..moveTo(-seaHalfWidth, seaDepth);
    for (var x = -seaHalfWidth; x <= seaHalfWidth; x += 24) {
      path.lineTo(x, surface(x));
    }
    path
      ..lineTo(seaHalfWidth, seaDepth)
      ..close();
    final fx = shader;
    if (front && fx != null && !(lowEnd?.value ?? false)) {
      // FlutterFragCoord 는 캔버스 로컬(= 월드 px) 좌표라 해수면 0, 배율 1 이다.
      fx
        ..setFloat(0, _t)
        ..setFloat(1, 0)
        ..setFloat(2, 0)
        ..setFloat(3, 1);
      var i = 4;
      for (final c in [...theme.sea, theme.foam]) {
        fx
          ..setFloat(i++, c.r)
          ..setFloat(i++, c.g)
          ..setFloat(i++, c.b);
      }
      canvas.drawPath(path, Paint()..shader = fx);
    } else {
      _renderGradient(canvas, path);
    }
    if (!front) return;
    _renderLattice(canvas);
    final foam = Paint();
    for (final f in _foam) {
      foam.color = theme.foam.withValues(alpha: (f.life / 1.5).clamp(0, 0.8));
      canvas.drawCircle(Offset(f.x, surface(f.x) + 1), 2.2, foam);
    }
  }

  /// 수면 아래 사인파 격자: 깊어질수록 옅어진다.
  void _renderLattice(Canvas canvas) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final (depth, alpha) in const [
      (18.0, .22),
      (44.0, .15),
      (86.0, .09),
    ]) {
      line.color = theme.foam.withValues(alpha: alpha);
      final p = Path()..moveTo(-seaHalfWidth, surface(-seaHalfWidth) + depth);
      for (var x = -seaHalfWidth; x <= seaHalfWidth; x += 32) {
        final wave = math.sin(x / 55 + _t * 1.1 + depth) * 3;
        p.lineTo(x, surface(x) + depth + wave);
      }
      canvas.drawPath(p, line);
    }
  }

  void _renderGradient(Canvas canvas, Path path) {
    const rect = Rect.fromLTWH(-seaHalfWidth, 0, seaHalfWidth * 2, seaDepth);
    canvas.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [for (final c in theme.sea) c.withValues(alpha: front ? 0.62 : 1)],
          const [0, 0.35, 1],
        ),
    );
  }
}

class _Foam {
  _Foam({required this.x, required this.vx, required this.life});

  double x;
  final double vx;
  double life;
}
