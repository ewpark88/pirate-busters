import 'dart:convert';
import 'dart:ui';

/// 캠페인 모드 화면 톤 (설계서 §10.2·§6.1). 같은 해역 그림에 색만 바꾼다.
enum SeaMode { normal, hard, hell }

/// 해역 배경 한 겹 (에셋 `bg/regions.json` `layers`).
class BackdropLayer {
  const BackdropLayer(this.id, this.parallax, {required this.colorMatrix});

  final String id;

  /// 0 이면 화면에 붙고 1 이면 전장과 같이 움직인다.
  final double parallax;

  /// 모드 색 행렬(`style/modes.json` `matrix`)을 씌우는 겹(far·mid).
  final bool colorMatrix;
}

/// 한 해역·모드의 하늘·바다 색 (에셋 `bg/regions.json` `regions.<id>.modes`).
class RegionTone {
  const RegionTone({
    required this.sky,
    required this.sea,
    required this.cloud,
    required this.sail,
  });

  /// 하늘 그라데이션(위 → 수평선).
  final List<Color> sky;

  /// 바다 그라데이션(수면 → 깊은 곳).
  final List<Color> sea;

  /// 구름 색. 일반 모드가 아니면 구름 겹에 곱한다.
  final Color cloud;

  /// 적 배 돛 색.
  final Color sail;
}

/// 해역 배경 데이터 (설계서 §10.2, 에셋 v0.23 `bg/`, ADR-063).
///
/// 레이어는 1400×640 그림을 가로로 이어 붙이고 수평선(y=420)을 수면(월드 y=0)에
/// 맞춘다. 1 그림 px = 1 월드 px(배 1칸 32px 와 같은 기준). 전장은 앱의 사인파
/// 바다·셰이더가 바다를 그리므로 `sea` 겹을 쓰지 않는다(ADR-063).
class Backdrop {
  Backdrop._(
    this.horizon,
    this.width,
    this.height,
    this.layers,
    this._tones,
    this._matrix,
  );

  factory Backdrop.fromJson(String regionsJson, String modesJson) {
    final r = jsonDecode(regionsJson) as Map<String, Object?>;
    final m =
        (jsonDecode(modesJson) as Map<String, Object?>)['modes']!
            as Map<String, Object?>;
    final canvas = (r['canvas']! as List).cast<num>();
    final regions = r['regions']! as Map<String, Object?>;
    return Backdrop._(
      (r['horizon']! as num).toDouble(),
      canvas[0].toDouble(),
      canvas[1].toDouble(),
      [
        for (final l in (r['layers']! as List).cast<Map<String, Object?>>())
          BackdropLayer(
            l['id']! as String,
            (l['parallax']! as num).toDouble(),
            colorMatrix: l['colorMatrix'] == true,
          ),
      ],
      {
        for (final e in regions.entries)
          for (final mode in SeaMode.values)
            (e.key, mode): _tone(
              ((e.value! as Map)['modes'] as Map)[mode.name]
                  as Map<String, Object?>,
            ),
      },
      {
        for (final mode in SeaMode.values)
          mode: flutterMatrix(
            ((m[mode.name]! as Map)['matrix']! as List).cast<num>(),
          ),
      },
    );
  }

  static const String regionsPath = 'assets/data/regions.json';
  static const String modesPath = 'assets/data/modes.json';

  /// 저사양 모드에서 빼는 겹 (설계서 §12).
  static const Set<String> lowEndSkipped = {'clouds', 'haze', 'glow'};

  final double horizon;
  final double width;
  final double height;

  /// 그리는 순서대로. 맨 끝이 `sea` 다.
  final List<BackdropLayer> layers;
  final Map<(String, SeaMode), RegionTone> _tones;
  final Map<SeaMode, List<double>> _matrix;

  static RegionTone _tone(Map<String, Object?> j) => RegionTone(
    sky: [for (final c in j['sky']! as List) hexColor(c)],
    sea: [for (final c in j['sea']! as List) hexColor(c)],
    cloud: hexColor(j['cloud']),
    sail: hexColor(j['sail']),
  );

  /// 그릴 겹. 저사양이면 구름·안개·빛 겹을 뺀다. 전장은 바다를 `SeaView` 가
  /// 그리므로 [sea] 겹을 빼고, 컷신은 넣는다.
  List<BackdropLayer> layersFor({required bool lowEnd, bool sea = false}) => [
    for (final l in layers)
      if ((!lowEnd || !lowEndSkipped.contains(l.id)) && (sea || l.id != 'sea'))
        l,
  ];

  RegionTone tone(String region, SeaMode mode) => _tones[(region, mode)]!;

  /// `assets/images/` 기준 레이어 그림 경로.
  static String file(String region, String layer) =>
      'bg/$region/${region}_$layer.png';

  /// 겹에 씌우는 색: far·mid 는 모드 색 행렬, 구름은 일반 모드가 아니면 해역의
  /// 모드 구름색을 곱한다. 다른 겹은 null.
  ColorFilter? filterFor(BackdropLayer layer, SeaMode mode, {String? region}) {
    if (layer.colorMatrix) return modeFilter(mode);
    if (layer.id == 'clouds' && mode != SeaMode.normal && region != null) {
      return ColorFilter.mode(tone(region, mode).cloud, BlendMode.modulate);
    }
    return null;
  }

  /// 모드 색 행렬 (`style/modes.json` `matrix`). 섬 겹과 컷신 해적에 씌운다.
  ColorFilter modeFilter(SeaMode mode) => ColorFilter.matrix(_matrix[mode]!);

  /// 빛 겹(등대·등불) 불투명도: 어두운 모드일수록 진하다 (에셋 README v0.23).
  /// 겹 [id] 에 얹는 하늘색 안개 세기(0~1). 가까운 섬 겹(등대)이 배와 같은 진하기면
  /// 배 위 소품처럼 읽혀서, 원경(설계서 §10.2)으로 보이게 흐린다 (A40).
  static double hazeOf(String id) => id == 'mid' ? 0.35 : 0;

  static double glowOpacity(SeaMode mode) => switch (mode) {
    SeaMode.normal => 0.35,
    SeaMode.hard => 0.75,
    SeaMode.hell => 1,
  };

  /// 일반 모드만 하늘·바다 그림을 쓰고, 다른 모드는 모드 색 그라데이션으로
  /// 다시 칠한다(에셋 README v0.23 ‘sky·sea 는 모드 색으로 다시 칠한다’).
  static bool skyPicture(SeaMode mode) => mode == SeaMode.normal;

  /// 카메라 x 가 [cameraX] 일 때 겹의 왼쪽 끝(월드 px). 겹은 카메라보다
  /// `parallax` 배로 움직이고 [width] 마다 이어 붙는다. 화면 왼쪽 끝은 [viewLeft].
  double tileStart(BackdropLayer layer, double cameraX, double viewLeft) {
    final offset = cameraX * (1 - layer.parallax);
    final k = ((viewLeft - offset) / width).floorToDouble();
    return offset + k * width;
  }

  /// `feColorMatrix` 순서(오프셋 0~1)를 Flutter `ColorFilter.matrix`(오프셋
  /// 0~255)로 바꾼다.
  static List<double> flutterMatrix(List<num> m) => [
    for (var i = 0; i < 20; i++) m[i].toDouble() * (i % 5 == 4 ? 255 : 1),
  ];

  static Color hexColor(Object? hex) {
    final rgb = int.parse((hex! as String).substring(1), radix: 16);
    return Color(0xFF000000 | rgb);
  }
}
