import 'dart:math' as math;
import 'dart:ui';

import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/view/damage_painter.dart';

/// 부서진 칸의 가장자리를 이웃 블록 쪽으로 찢긴 모양으로 덧그리고, 금간·구멍 칸의
/// 금을 이웃 부서진 칸 방향으로 돌려 이어지게 한다 (설계서 §10.2, ADR-052).
///
/// 판정은 격자 그대로다. 모양은 칸 번호와 이웃 마스크로 정해지는 고정 패턴이라
/// 리플레이에서도 같고, Path 는 (패턴, 마스크) 로 캐시한다.
abstract final class TornEdgePainter {
  /// 이웃 마스크 비트.
  static const int left = 1;
  static const int right = 2;
  static const int up = 4;
  static const int down = 8;

  static final Paint _splinter = Paint()..color = const Color(0xE0120A06);
  static final Paint _fiber = Paint()
    ..color = const Color(0xFF8A5A34)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..strokeJoin = StrokeJoin.round;
  static final Map<int, Path> _cache = {};

  /// 단위 칸 크기. Path 는 이 크기로 만들고 그릴 때 칸 크기에 맞춘다.
  static const double _unit = 32;

  /// 부서진 칸 [r] 의 둘레에서, 블록이 남은 이웃([mask]) 쪽으로 톱니처럼 파고드는
  /// 그림자를 그린다. 타일을 모두 그린 뒤에 불러야 이웃 타일 위에 얹힌다.
  static void torn(Canvas canvas, Rect r, int seed, int mask) {
    if (mask == 0) return;
    final pattern = seed % 16;
    final path = _cache.putIfAbsent(
      pattern << 4 | mask,
      () => _build(pattern, mask),
    );
    canvas
      ..save()
      ..translate(r.left, r.top)
      ..scale(r.width / _unit, r.height / _unit)
      ..drawPath(path, _splinter)
      ..drawPath(path, _fiber)
      ..restore();
  }

  /// 금간·구멍 칸의 손상 표시. 이웃 중 부서진 칸이 있으면([brokenMask]) 그 방향에서
  /// 금이 들어오게 돌려 그려 칸 경계를 넘어 이어져 보이게 한다.
  static void damage(
    Canvas canvas,
    Rect r,
    int seed,
    DamageStage stage,
    int brokenMask,
  ) {
    if (stage != DamageStage.cracked && stage != DamageStage.holed) return;
    // 기본 금은 위·오른쪽에서 들어온다. 부서진 이웃 쪽이 위가 되게 돌린다.
    final quarter = switch (brokenMask) {
      _ when brokenMask & up != 0 => 0,
      _ when brokenMask & right != 0 => 1,
      _ when brokenMask & down != 0 => 2,
      _ when brokenMask & left != 0 => 3,
      _ => seed % 4,
    };
    final c = r.center;
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(-quarter * math.pi / 2)
      ..translate(-c.dx, -c.dy);
    if (stage == DamageStage.cracked) {
      DamagePainter.cracked(canvas, r, seed);
    } else {
      DamagePainter.holed(canvas, r, seed);
    }
    canvas.restore();
  }

  /// 0 ~ 1 사이의 고정 난수 (칸 번호 패턴과 톱니 번호로 정해진다).
  static double _jitter(int pattern, int i) =>
      ((pattern * 73 + i * 37) % 11) / 10;

  static Path _build(int pattern, int mask) {
    final path = Path();
    const teeth = 5;
    const depthMax = 7.0;
    const depthMin = 2.5;
    // 변마다 톱니 띠: 변 위의 점과 이웃 안쪽으로 파고든 점을 번갈아 잇는다.
    void strip(int bit, Offset Function(double t, double d) point) {
      if (mask & bit == 0) return;
      final first = point(0, 0);
      path.moveTo(first.dx, first.dy);
      for (var i = 0; i <= teeth; i++) {
        final t = i / teeth;
        final d = depthMin + (depthMax - depthMin) * _jitter(pattern, i + bit);
        final tip = point(
          (i == 0 || i == teeth)
              ? t
              : t + (_jitter(pattern, i * 3 + bit) - 0.5) / teeth,
          i == 0 || i == teeth ? 0 : d,
        );
        path.lineTo(tip.dx, tip.dy);
      }
      path.close();
    }

    strip(left, (t, d) => Offset(-d, _unit * t));
    strip(right, (t, d) => Offset(_unit + d, _unit * t));
    strip(up, (t, d) => Offset(_unit * t, -d));
    strip(down, (t, d) => Offset(_unit * t, _unit + d));
    return path;
  }
}
