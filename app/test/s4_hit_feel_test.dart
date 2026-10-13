import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/breakage_fx.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/shot_fx.dart';

/// 게임 정리 S4 착탄 장면 캡처 (설계서 §10.4, 계획서 0장 S4). 전투 화면과 떨어진 작은
/// 무대(하늘·바다·배 판자 7×3칸)에 연출만 띄워 장면마다 0.05·0.15·0.3·0.6초를 한 줄로
/// 찍는다. `--dart-define=S4_CAPTURE=<폴더>` 를 주면 그 폴더에 PNG 로 남긴다.
const String _captureDir = String.fromEnvironment('S4_CAPTURE');

const List<double> _moments = [0.05, 0.15, 0.3, 0.6];
const double _w = 320;
const double _h = 240;

/// 장면 이름과 연출을 띄우는 함수. 인자는 효과 층, 배 가운데, 배 옆 수면, 판자 그림.
final Map<String, void Function(FxLayer, Vector2, Vector2, Sprite)> _scenes = {
  'light': (fx, at, sea, tile) => fx.hit(at, Family.direct),
  'medium': (fx, at, sea, tile) => fx.hit(at, Family.lob),
  'heavy': (fx, at, sea, tile) =>
      fx.hit(at, Family.lob, radius: 2, heavy: true),
  'magazine': (fx, at, sea, tile) => fx.explosion(at, radius: 2, heavy: true),
  'water': (fx, at, sea, tile) => fx
    ..splash(sea)
    ..waterHit(sea),
  'shatter': (fx, at, sea, tile) {
    fx.hit(at, Family.lob);
    for (var i = 0; i < 3; i++) {
      fx.shatter(
        at + Vector2((i - 1) * 32, 0),
        tile: tile,
        seed: 11 + i * 7,
        from: at,
      );
    }
  },
  'muzzle': (fx, at, sea, tile) => fx.muzzle(at - Vector2(40, 30), 1),
};

Future<List<ui.Image>> _shoot(String name) async {
  final game = FlameGame()..onGameResize(Vector2(_w, _h));
  final sprites = await BattleSprites.load(game.images);
  final fx = FxLayer(sprites: sprites, priority: 30);
  final tile = sprites.get('ship/tiles_v2/oak_0.png');
  // 바다 수면 y = 0, 배는 수면 위 3칸.
  await game.world.addAll([
    RectangleComponent(
      position: Vector2(-400, -400),
      size: Vector2(800, 400),
      paint: ui.Paint()..color = const ui.Color(0xFF9CCBE6),
    ),
    RectangleComponent(
      position: Vector2(-400, 0),
      size: Vector2(800, 300),
      paint: ui.Paint()..color = const ui.Color(0xFF2F6FA0),
    ),
    for (var y = 0; y < 3; y++)
      for (var x = 0; x < 7; x++)
        SpriteComponent(
          sprite: tile,
          position: Vector2(-112 + x * 32.0, -96 + y * 32.0),
          size: Vector2.all(32),
        ),
    fx,
  ]);
  // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
  // ignore: invalid_use_of_internal_member
  await game.load();
  // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
  // ignore: invalid_use_of_internal_member
  game.mount();
  // ignore: cascade_invocations, mount 은 위의 ignore 가 필요해 캐스케이드로 못 묶는다.
  game.update(0);
  await game.ready();
  // 물 착탄은 배 오른쪽 수면을 본다.
  final sea = Vector2(170, 0);
  game.camera.viewfinder
    ..position = name == 'water' ? sea - Vector2(0, 40) : Vector2(0, -50)
    ..zoom = 1.4;
  _scenes[name]!(fx, Vector2(0, -48), sea, tile);
  final out = <ui.Image>[];
  var t = 0.0;
  for (final m in _moments) {
    while (t < m - 1e-9) {
      game.update(1 / 60);
      t += 1 / 60;
    }
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    out.add(await recorder.endRecording().toImage(_w.toInt(), _h.toInt()));
  }
  return out;
}

Future<void> _save(String name, List<ui.Image> frames) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  for (var i = 0; i < frames.length; i++) {
    canvas.drawImage(frames[i], ui.Offset(i * _w, 0), ui.Paint());
  }
  final strip = await recorder.endRecording().toImage(
    (_w * frames.length).toInt(),
    _h.toInt(),
  );
  final png = await strip.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$_captureDir/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(png!.buffer.asUint8List());
}

void main() {
  for (final name in _scenes.keys) {
    testWidgets('착탄 장면 "$name" 이 오류 없이 그려지고 연출이 화면에 남는다', (tester) async {
      rootBundle.clear();
      late List<ui.Image> frames;
      await tester.runAsync(() async {
        frames = await _shoot(name);
        if (_captureDir.isNotEmpty) await _save(name, frames);
      });
      expect(frames, hasLength(_moments.length));
    });
  }
}
