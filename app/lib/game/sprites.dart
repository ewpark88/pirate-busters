import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/view/explosion_fx.dart';
import 'package:pirate_busters/game/view/fire_view.dart';
import 'package:pirate_busters/game/view/water_fx.dart';

/// 전장에서 쓰는 이미지 (에셋 v0.22·v0.24, docs/ASSETS.md). 모두 @2x.
class BattleSprites {
  BattleSprites._(this._images);

  static final List<String> files = [
    for (final m in ['pine', 'oak', 'cork', 'bot', 'mesh'])
      for (var v = 0; v < 4; v++) 'ship/tiles_v2/${m}_$v.png',
    'ship/tiles_v2/iron.png',
    ...FireView.files,
    for (var v = 0; v < 4; v++) roomFile(v),
    for (final k in ModuleKind.values) moduleFile(k),
    'ship/rig/mast.png',
    'ship/rig/sail_blue.png',
    'ship/rig/sail_red.png',
    'ship/rig/flag_blue.png',
    'ship/rig/flag_red.png',
    limitForward,
    limitBack,
    limitSplash,
    ...ExplosionFx.files,
    ...WaterFx.files,
    'fx/cannonball.png',
    'fx/explosion.png',
    'fx/splash.png',
    'fx/smoke.png',
    'fx/impact/flash.png',
    'fx/impact/spark.png',
    'fx/impact/hole_burnt.png',
    'fx/impact/cracks.png',
    'fx/impact/shockwave.png',
    'fx/impact/burst.png',
    'fx/impact/dizzy_star.png',
    'fx/collapse/water_spike.png',
    'fx/collapse/foam_ring.png',
    'fx/collapse/splash_big.png',
    'fx/impact/debris_plank.png',
    for (var i = 0; i < 6; i++) 'fx/impact/debris_$i.png',
    for (var i = 0; i < 6; i++) 'fx/impact/puff_$i.png',
  ];

  /// 기능 모듈 그림 (설계서 §3.3, 에셋 v0.23 `ship/modules/`).
  static String moduleFile(ModuleKind kind) =>
      'ship/modules/${switch (kind) {
        ModuleKind.gunPort => 'gunport',
        ModuleKind.lookout => 'crowsnest',
        ModuleKind.magazine => 'powder',
        ModuleKind.workshop => 'carpenter',
        ModuleKind.fuelTank => 'fuel',
        ModuleKind.pump || ModuleKind.mast || ModuleKind.captain => kind.name,
      }}.png';

  /// 이동 한계 표식 (설계서 §2.6, 에셋 v0.23 `bg/props/`). 1 그림 px = 1 월드 px.
  static const String limitForward = 'bg/props/limit_forward.png';
  static const String limitBack = 'bg/props/limit_back.png';
  static const String limitSplash = 'bg/props/limit_splash.png';

  static Future<BattleSprites> load(Images images) async {
    await images.loadAll(files);
    return BattleSprites._(images);
  }

  final Images _images;

  Sprite get(String file) => Sprite(_images.fromCache(file));

  /// 칸 ([x], [y]) 의 무늬 번호 0~3 (에셋 `ship/tiles_v2/README.txt`). 칸 위치로
  /// 정해져 리플레이에서도 같다 (설계서 §10.2).
  static int variantOf(int x, int y) => (x * 7 + y * 13 + (x * y) % 5) % 4;

  /// 로컬 줄 [y] 가 잠긴 깊이 [draft](1/1000칸)에 젖었나. 칸 가운데가 수면
  /// 아래면 젖은 것으로 본다(선실 잠김 판정 `isCabinFlooded` 와 같은 식).
  static bool isWet(int y, int draft) => y * cellUnit + cellUnit ~/ 2 <= draft;

  /// 칸 ([x], [y]) 의 재질 타일(멀쩡한 모습). 손상 단계는 ShipView 가 코드로
  /// 덧그린다 (설계서 §10.2, ADR-030). 흘수선 아래([wet]) 참나무·소나무 칸은
  /// 젖은 타일(`bot`, 에셋 v0.23 README, ADR-061)이고 철판은 한 가지다.
  Sprite tile(BlockMaterial m, int x, int y, {bool wet = false}) {
    final name = switch (m) {
      BlockMaterial.iron => null,
      BlockMaterial.oak || BlockMaterial.pine when wet => 'bot',
      BlockMaterial.net => 'mesh',
      _ => m.name,
    };
    if (name == null) return get('ship/tiles_v2/iron.png');
    return get('ship/tiles_v2/${name}_${variantOf(x, y)}.png');
  }

  /// 등불 선실 타일 [v](0~3): 짝수·홀수가 벽 무늬, 2 이상이면 등불이 왼쪽
  /// (에셋 v0.24 `ship/rooms/room1_lantern_*`, ADR-062).
  static String roomFile(int v) =>
      'ship/rooms/room1_lantern_${v % 2}${v >= 2 ? '_left' : ''}.png';

  /// 선실 칸 안쪽 벽과 등불 (설계서 §10.2, ADR-057). 칸 위치로 정해진다.
  Sprite roomWall(int x, int y) => get(roomFile(variantOf(x, y)));
}
