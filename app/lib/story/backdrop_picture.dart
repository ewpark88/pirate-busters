import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pirate_busters/game/view/backdrop.dart';

/// 컷신 배경 (설계서 §15.4 ‘해역 배경을 그대로 써서’, §10.2 모드 톤): 해역 겹 7장을
/// 한 장으로 겹친다. 일반 모드는 그림 그대로, 다른 모드는 하늘·바다를 모드 색
/// 그라데이션으로 칠하고 섬에 색 행렬을, 빛 겹에 진한 불투명도를 쓴다. 지옥 모드의
/// 비·번개는 R3 에서 넣는다(ADR-063).
class BackdropPicture extends StatelessWidget {
  const BackdropPicture({
    required this.region,
    this.mode = SeaMode.normal,
    super.key,
  });

  final String region;
  final SeaMode mode;

  static Future<Backdrop>? _data;
  static Backdrop? _loaded;

  /// 읽어 둔 배경 데이터. 아직 없으면 null.
  static Backdrop? get loaded => _loaded;

  /// 배경 데이터. 한 번 읽으면 다음 화면부터는 바로 그린다.
  static Future<Backdrop> data() => _data ??= () async {
    return _loaded = Backdrop.fromJson(
      await rootBundle.loadString(Backdrop.regionsPath),
      await rootBundle.loadString(Backdrop.modesPath),
    );
  }();

  @override
  Widget build(BuildContext context) => FutureBuilder<Backdrop>(
    future: data(),
    initialData: _loaded,
    builder: (context, snap) {
      final data = snap.data;
      if (data == null) return const ColoredBox(color: Color(0xFF15171D));
      final tone = data.tone(region, mode);
      final picture = Backdrop.skyPicture(mode);
      Widget fill(List<Color> colors) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
      );
      final horizon = data.horizon / data.height;
      return ColoredBox(
        color: tone.sky.first,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: data.width,
            height: data.height,
            child: Stack(
              children: [
                for (final layer in data.layersFor(lowEnd: false, sea: true))
                  if (!picture && layer.id == 'sky')
                    Positioned.fill(
                      bottom: data.height * (1 - horizon),
                      child: fill(tone.sky),
                    )
                  else if (!picture && layer.id == 'sea')
                    Positioned.fill(
                      top: data.horizon,
                      child: fill(tone.sea),
                    )
                  else
                    Positioned.fill(child: _layer(data, layer)),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _layer(Backdrop data, BackdropLayer layer) {
    Widget image = Image.asset(
      'assets/images/${Backdrop.file(region, layer.id)}',
      fit: BoxFit.fill,
    );
    final filter = data.filterFor(layer, mode, region: region);
    if (filter != null) {
      image = ColorFiltered(colorFilter: filter, child: image);
    }
    if (layer.id == 'glow') {
      image = Opacity(opacity: Backdrop.glowOpacity(mode), child: image);
    }
    return image;
  }
}
