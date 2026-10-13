import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/sea_view.dart';
import 'package:pirate_busters/game/view/sea_zones.dart';

/// 파도 구간 물빛 (설계서 §2.6·§10.2 “구간 경계는 물빛 차이로 보인다”).
///
/// 뒤 바다 위, 배보다 뒤에 구간마다 물빛을 얹는다: 잔잔한 구간은 맑은 청록, 거친
/// 구간은 짙은 남색, 보통은 바다색 그대로. 경계는 [SeaZones.blend] 의 두 배 폭으로
/// 섞는다. 깊어질수록 옅어지게 다섯 띠로 나눠 그린다. 구간은 판마다 고정이라 색 띠
/// 셰이더는 한 번만 만든다. 저사양에서도 같은 띠를 쓴다(셰이더 없음).
class SeaZoneTint extends Component {
  SeaZoneTint({
    required this.zones,
    required this.theme,
    required this.surface,
    super.priority,
  });

  final SeaZones zones;
  final SeaTheme theme;

  /// 수면 높이(월드 px, 아래가 +).
  final double Function(double x) surface;

  /// 띠(깊이 끝 월드 px, 진하기).
  static const List<(double, double)> bands = [
    (50, 1),
    (100, .75),
    (160, .5),
    (230, .3),
    (320, .15),
  ];

  late final Shader _shader = _gradient();
  final Path _path = Path();
  final Paint _paint = Paint();

  /// 가로 색 띠의 (위치 0~1, 세기) 목록. 경계마다 앞뒤 두 점을 두고 그 사이를 섞는다.
  List<(double, double)> stops() {
    const span = seaHalfWidth * 2;
    double at(double x) => (x + seaHalfWidth) / span;
    final out = <(double, double)>[
      (0, zones.levelAt(-seaHalfWidth).toDouble()),
    ];
    final edges = zones.edges;
    for (final e in [for (final e in edges.reversed) -e, ...edges]) {
      out
        ..add((at(e - SeaZones.blend), zones.smoothLevelAt(e - SeaZones.blend)))
        ..add((
          at(e + SeaZones.blend),
          zones.smoothLevelAt(e + SeaZones.blend),
        ));
    }
    out.add((1, zones.levelAt(seaHalfWidth).toDouble()));
    return out;
  }

  Shader _gradient() {
    final s = stops();
    return Gradient.linear(
      const Offset(-seaHalfWidth, 0),
      const Offset(seaHalfWidth, 0),
      [for (final (_, level) in s) theme.tintFor(level)],
      [for (final (at, _) in s) at],
    );
  }

  @override
  void render(Canvas canvas) {
    var top = 0.0;
    for (final (depth, alpha) in bands) {
      final path = _path..reset();
      if (top == 0) {
        path.moveTo(-seaHalfWidth, depth);
        for (var x = -seaHalfWidth; x <= seaHalfWidth; x += 48) {
          path.lineTo(x, surface(x) + 2);
        }
        path
          ..lineTo(seaHalfWidth, depth)
          ..close();
      } else {
        path.addRect(Rect.fromLTRB(-seaHalfWidth, top, seaHalfWidth, depth));
      }
      _paint
        ..shader = _shader
        ..color = Color.fromRGBO(0, 0, 0, alpha);
      canvas.drawPath(path, _paint);
      top = depth;
    }
  }
}
