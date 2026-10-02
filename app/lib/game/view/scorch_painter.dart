import 'dart:math' as math;
import 'dart:ui';

import 'package:pirate_busters/game/view/damage_style.dart';

/// 그을음 (설계서 §10.4 ‘맞은 자리에 그을음 자국이 남는다’, 에셋 v0.26, ADR-070).
/// 구멍·파괴 칸의 이어진 덩어리마다 가운데에서 번지고 불씨가 남는다. 배 밖으로
/// 번지지 않게 부르는 쪽이 설계도 칸으로 잘라낸다. 모양은 칸 번호로 정해진다.
abstract final class ScorchPainter {
  static const List<Color> _colors = [
    Color(0xCC0A0605),
    Color(0x8C1A0E08),
    Color(0x383A1E0C),
    Color(0x003A1E0C),
  ];
  static const List<double> _stops = [0, .45, .75, 1];

  /// 칸 (c, r) 이 [hot] 인 칸들의 상하좌우로 이어진 덩어리. 칸 번호 순(r, c)으로
  /// 훑어 처음 만난 칸이 덩어리의 첫 칸이다.
  static List<List<(int, int)>> clusters(
    int width,
    int height,
    bool Function(int c, int r) hot,
  ) {
    final seen = <int>{};
    final out = <List<(int, int)>>[];
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        if (!hot(c, r) || seen.contains(r * width + c)) continue;
        final comp = <(int, int)>[];
        final stack = [(c, r)];
        while (stack.isNotEmpty) {
          final q = stack.removeLast();
          if (!seen.add(q.$2 * width + q.$1)) continue;
          comp.add(q);
          for (final (dc, dr) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            final n = (q.$1 + dc, q.$2 + dr);
            if (n.$1 >= 0 &&
                n.$1 < width &&
                n.$2 >= 0 &&
                n.$2 < height &&
                hot(n.$1, n.$2)) {
              stack.add(n);
            }
          }
        }
        out.add(comp);
      }
    }
    return out;
  }

  /// 덩어리 [comp] 의 그을음: 칸 중심 평균에서 반경 C·(1.3 + 0.25√n), 타원 5개
  /// 방사 그라데이션과 불씨 7개.
  static void cluster(Canvas canvas, List<(int, int)> comp) {
    const u = DamageStyle.unit;
    var sx = 0.0;
    var sy = 0.0;
    for (final (c, r) in comp) {
      sx += c * u + u / 2;
      sy += r * u + u / 2;
    }
    final cx = sx / comp.length;
    final cy = sy / comp.length;
    final big = u * (1.3 + .25 * math.sqrt(comp.length));
    final k = DamageStyle.rnd(comp.first.$1, comp.first.$2, 200);
    for (var i = 0; i < 5; i++) {
      final an = i * 1.256 + k * 6;
      final rr = big * (.55 + .25 * ((i * 37 + (k * 100).floor()) % 7) / 7);
      DamageStyle.radialEllipse(
        canvas,
        Offset(cx + math.cos(an) * big * .3, cy + math.sin(an) * big * .22),
        rr,
        rr * .8,
        _colors,
        _stops,
      );
    }
    for (var i = 0; i < 7; i++) {
      final an = i * 2.4 + k * 3;
      final d = big * (.2 + .5 * ((i * 53) % 9) / 9);
      canvas.drawCircle(
        Offset(cx + math.cos(an) * d, cy + math.sin(an) * d),
        .7 + (i % 3) * .4,
        DamageStyle.fill(const Color(0xFFFFB24A), .5 + (i % 2) * .4),
      );
    }
  }
}
