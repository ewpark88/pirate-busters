import 'dart:math' as math;
import 'dart:ui';

import 'package:pb_sim/pb_sim.dart';

/// 피해 표현 v3 의 색·해시·도형 도우미 (설계서 §10.2, 에셋 v0.26
/// `fx/damage_v3/damage_v3.json`, 참고 구현 `tools/py/damage38.py`, ADR-070).
///
/// 좌표는 칸 하나가 [unit] 인 단위 공간이고 줄 번호 r 은 아래로 는다.
abstract final class DamageStyle {
  /// 단위 칸 크기 (참고 구현의 C).
  static const double unit = 32;

  /// 판자 3장의 세로 범위 (칸 위에서부터).
  static const List<(double, double)> planks = [
    (0, 10.5),
    (10.5, 21.5),
    (21.5, 32),
  ];

  static const Color outline = Color(0xFF14161C);
  static const Color interior = Color(0xFF160C07);
  static const Color interiorBeam = Color(0xFF2A170D);
  static const Color wet = Color(0xFF0C2A30);
  static const Color wetBeam = Color(0xFF13434A);
  static const Color crack = Color(0xFF120804);

  static const WoodPalette oak = WoodPalette(
    base: Color(0xFF6A4128),
    dark: Color(0xFF3E2414),
    fresh: Color(0xFFD9B07A),
    inner: Color(0xFFB8844E),
  );
  static const WoodPalette bot = WoodPalette(
    base: Color(0xFF3B1D1A),
    dark: Color(0xFF24100E),
    fresh: Color(0xFF9A7A54),
    inner: Color(0xFF6A4A32),
  );
  static const WoodPalette pine = WoodPalette(
    base: Color(0xFFA8784A),
    dark: Color(0xFF6A4628),
    fresh: Color(0xFFF0D29A),
    inner: Color(0xFFD0A46A),
  );

  static const Color ironBase = Color(0xFF5F6873);
  static const Color ironHi = Color(0xFFC9D3DC);
  static const Color ironDark = Color(0xFF353C45);
  static const Color ironHot = Color(0xFFFF8A3A);

  /// 재질 [m] 의 나무 색. 흘수선 아래([wet]) 참나무·소나무는 젖은 `bot` 이고,
  /// 패치에 없는 코르크는 소나무, 망사는 참나무 색을 쓴다 (ADR-070).
  static WoodPalette woodOf(BlockMaterial m, {bool wet = false}) => switch (m) {
    BlockMaterial.oak || BlockMaterial.pine when wet => bot,
    BlockMaterial.pine || BlockMaterial.cork => pine,
    _ => oak,
  };

  /// 칸 (c, r) 과 번호 k 로 정해지는 0 ~ 1 고정 난수 (참고 구현 `rnd` 와 같다).
  static double rnd(int c, int r, int k) {
    var h =
        ((c + 101) * 73856093 ^ (r + 211) * 19349663 ^ (k + 7) * 83492791) &
        0xffffffff;
    h ^= h >> 13;
    h = (h * 1274126177) & 0xffffffff;
    h ^= h >> 16;
    return h / 4294967296;
  }

  static Paint fill(Color c, [double opacity = 1]) =>
      Paint()..color = c.withValues(alpha: c.a * opacity);

  static Paint stroke(Color c, double width, [double opacity = 1]) => Paint()
    ..color = c.withValues(alpha: c.a * opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  /// 점들을 이은 닫힌 다각형([close]) 또는 꺾은선.
  static Path poly(List<Offset> pts, {bool close = true}) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    if (close) p.close();
    return p;
  }

  /// 꺾은선을 시작 굵기 [w0] 에서 끝 굵기 [w1] 로 가늘어지는 쐐기 다각형으로.
  static Path taper(List<Offset> pts, double w0, double w1) {
    final l = <Offset>[];
    final r = <Offset>[];
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final a = pts[math.max(0, i - 1)];
      final b = pts[math.min(n - 1, i + 1)];
      final d = b - a;
      final len = d.distance == 0 ? 1.0 : d.distance;
      final normal = Offset(-d.dy / len, d.dx / len);
      final w = (w0 + (w1 - w0) * i / (n - 1)) / 2;
      l.add(pts[i] + normal * w);
      r.add(pts[i] - normal * w);
    }
    return poly([...l, ...r.reversed]);
  }

  /// [pivot] 을 중심으로 [degrees] 만큼 돌려 [draw] 한다.
  static void rotated(
    Canvas canvas,
    Offset pivot,
    double degrees,
    void Function() draw,
  ) {
    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy)
      ..rotate(degrees * math.pi / 180)
      ..translate(-pivot.dx, -pivot.dy);
    draw();
    canvas.restore();
  }

  /// ([center], [rx]×[ry]) 타원에 방사 그라데이션([colors], [stops])을 채운다.
  static void radialEllipse(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
    List<Color> colors,
    List<double> stops,
  ) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(1, ry / rx)
      ..drawCircle(
        Offset.zero,
        rx,
        Paint()..shader = Gradient.radial(Offset.zero, rx, colors, stops),
      )
      ..restore();
  }
}

/// 나무 재질 한 가지의 색.
class WoodPalette {
  const WoodPalette({
    required this.base,
    required this.dark,
    required this.fresh,
    required this.inner,
  });

  /// 판자 바탕.
  final Color base;

  /// 어두운 결·이음매.
  final Color dark;

  /// 부러진 끝의 새 나무(밝은 속살).
  final Color fresh;

  /// 부러진 면의 속살 선.
  final Color inner;
}
