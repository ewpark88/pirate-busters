import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// 하늘·원경·바다 (설계서 §10.2, ADR-029). 셰이더 없이 코드 도형으로 그린다.
/// 색은 에셋 tokens.json `palette`.
abstract final class SeaPalette {
  static const List<Color> sky = [
    Color(0xFF161631),
    Color(0xFF4A2645),
    Color(0xFFB8553A),
    Color(0xFFE98A45),
  ];
  static const Color sun = Color(0xFFFFD28A);
  static const Color rocks = Color(0xFF1C1428);
  static const List<Color> sea = [
    Color(0xFF2A4A5A),
    Color(0xFF173446),
    Color(0xFF0B1B28),
  ];
  static const Color foam = Color(0xFFE8C9A0);
}

/// 전장 가로 범위(월드 px). 월드 ±100칸보다 넓게 그린다.
const double seaHalfWidth = 3600;
const double seaDepth = 900;

/// 화면에 고정된 하늘 그라데이션과 해.
class SkyBackdrop extends Component with HasGameReference<FlameGame> {
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
            SeaPalette.sky,
            const [0, 0.45, 0.8, 1],
          ),
      )
      ..drawCircle(
        Offset(size.x * 0.7, size.y * 0.62),
        size.y * 0.12,
        Paint()..color = SeaPalette.sun.withValues(alpha: 0.85),
      );
  }
}

/// 원경 한 겹: 카메라보다 [factor] 배 느리게 움직인다(시차).
class ParallaxScenery extends PositionComponent
    with HasGameReference<FlameGame> {
  ParallaxScenery({required this.factor, required this.seed, super.priority});

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
    final paint = Paint()
      ..color = Color.lerp(SeaPalette.rocks, SeaPalette.sky[2], 1 - factor)!;
    final cloud = Paint()..color = const Color(0x55FFE6C8);
    for (var i = -8; i <= 8; i++) {
      final h = ((i * 37 + seed * 11) % 7 + 3) * 14.0;
      final x = i * 460.0 + seed * 90;
      // 섬
      final island = Path()
        ..moveTo(x - 160, 0)
        ..quadraticBezierTo(x - 60, -h, x + 20, -h * 0.7)
        ..quadraticBezierTo(x + 90, -h * 1.1, x + 170, 0)
        ..close();
      canvas.drawPath(island, paint);
      if ((i + seed).isEven) {
        // 등대
        canvas
          ..drawRect(Rect.fromLTWH(x + 10, -h - 40, 10, 40), paint)
          ..drawCircle(
            Offset(x + 15, -h - 44),
            5,
            Paint()..color = const Color(0xFFFFC24A),
          );
      }
      // 구름
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

/// 바다. [front] 면 배 앞에 반투명으로 그려 물에 잠긴 부분을 물빛으로 덮는다.
class SeaView extends Component {
  SeaView({required this.front, super.priority});

  final bool front;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  double _surface(double x) =>
      math.sin(x / 90 + _t * 1.3) * 3 + math.sin(x / 37 - _t * 2.1) * 1.2;

  @override
  void render(Canvas canvas) {
    final path = Path()..moveTo(-seaHalfWidth, seaDepth);
    for (var x = -seaHalfWidth; x <= seaHalfWidth; x += 24) {
      path.lineTo(x, _surface(x));
    }
    path
      ..lineTo(seaHalfWidth, seaDepth)
      ..close();
    const rect = Rect.fromLTWH(-seaHalfWidth, 0, seaHalfWidth * 2, seaDepth);
    canvas.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [
            for (final c in SeaPalette.sea)
              c.withValues(alpha: front ? 0.62 : 1),
          ],
          const [0, 0.35, 1],
        ),
    );
    if (!front) return;
    final foam = Paint()..color = SeaPalette.foam.withValues(alpha: 0.7);
    for (var x = -seaHalfWidth; x <= seaHalfWidth; x += 53) {
      final wobble = math.sin(x * 0.7 + _t * 2) * 6;
      canvas.drawCircle(Offset(x + wobble, _surface(x) + 1), 2.2, foam);
    }
  }
}
