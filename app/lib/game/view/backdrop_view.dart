import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle;
import 'package:pirate_busters/game/view/backdrop.dart';

/// 해역 원경 (설계서 §10.2 ‘원경을 여러 겹 시차 배경으로’, 에셋 v0.23 `bg/`).
///
/// 하늘·구름·먼 섬·안개·가까운 섬·빛 겹을 가로로 이어 그린다. 각 겹은 카메라보다
/// `parallax` 배로 움직인다. 수평선은 수면(월드 y=0)이다. 바다는 `SeaView` 가 그린다.
class BackdropView extends Component with HasGameReference<FlameGame> {
  BackdropView({
    required this.data,
    required this.region,
    this.mode = SeaMode.normal,
    this.lowEnd,
    super.priority,
  });

  final Backdrop data;
  final String region;
  final SeaMode mode;
  final ValueListenable<bool>? lowEnd;

  /// 데이터와 그림을 읽어 만든다. 모든 겹(저사양에서 빼는 겹 포함)을 읽어 둔다.
  /// MVP 는 해역 1 ‘열대 만’ 만 쓴다. 해역·모드 톤 전환은 R3.
  static Future<BackdropView> load(
    Images images,
    AssetBundle bundle, {
    String region = 'tropic',
    SeaMode mode = SeaMode.normal,
    ValueListenable<bool>? lowEnd,
    int? priority,
  }) async {
    final data = Backdrop.fromJson(
      await bundle.loadString(Backdrop.regionsPath),
      await bundle.loadString(Backdrop.modesPath),
    );
    await images.loadAll([
      for (final l in data.layersFor(lowEnd: false))
        Backdrop.file(region, l.id),
    ]);
    return BackdropView(
      data: data,
      region: region,
      mode: mode,
      lowEnd: lowEnd,
      priority: priority,
    );
  }

  /// 지금 그리는 겹 (테스트용).
  List<BackdropLayer> get drawn =>
      data.layersFor(lowEnd: lowEnd?.value ?? false);

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final cameraX = game.camera.viewfinder.position.x;
    final top = -data.horizon;
    final tone = data.tone(region, mode);
    // 그림 위쪽 하늘은 하늘 맨 위 색으로 채운다(줌아웃·높이 나는 탄).
    if (view.top < top) {
      canvas.drawRect(
        Rect.fromLTRB(view.left, view.top, view.right, top + 1),
        Paint()..color = tone.sky.first,
      );
    }
    for (final layer in drawn) {
      if (layer.id == 'sky' && !Backdrop.skyPicture(mode)) {
        _gradientSky(canvas, view, tone);
        continue;
      }
      final image = game.images.fromCache(Backdrop.file(region, layer.id));
      final src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = data.filterFor(layer, mode, region: region);
      if (layer.id == 'glow') {
        paint.color = Color.fromRGBO(0, 0, 0, Backdrop.glowOpacity(mode));
      }
      final haze = Backdrop.hazeOf(layer.id);
      if (haze > 0) canvas.saveLayer(null, Paint());
      for (
        var x = data.tileStart(layer, cameraX, view.left);
        x < view.right;
        x += data.width
      ) {
        canvas.drawImageRect(
          image,
          src,
          Rect.fromLTWH(x, top, data.width, data.height),
          paint,
        );
      }
      if (haze > 0) {
        // 그린 겹 위에만 하늘 아래쪽 색을 얹는다(srcATop).
        canvas
          ..drawRect(
            Rect.fromLTRB(view.left, top, view.right, top + data.height),
            Paint()
              ..color = tone.sky.last.withValues(alpha: haze)
              ..blendMode = BlendMode.srcATop,
          )
          ..restore();
      }
    }
  }

  void _gradientSky(Canvas canvas, Rect view, RegionTone tone) {
    final rect = Rect.fromLTRB(view.left, -data.horizon, view.right, 0);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          tone.sky,
          [
            for (var i = 0; i < tone.sky.length; i++) i / (tone.sky.length - 1),
          ],
        ),
    );
  }
}
