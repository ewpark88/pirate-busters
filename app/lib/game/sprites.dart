import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';

/// 전장에서 쓰는 이미지 (에셋 v0.22, docs/ASSETS.md). 모두 @2x.
class BattleSprites {
  BattleSprites._(this._images);

  static final List<String> files = [
    for (final m in ['pine', 'oak', 'cork', 'bot', 'mesh'])
      for (var v = 0; v < 4; v++) 'ship/tiles_v2/${m}_$v.png',
    'ship/tiles_v2/iron.png',
    'ship/tiles_v2/room_0.png',
    'ship/tiles_v2/room_1.png',
    'ship/rig/mast.png',
    'ship/rig/sail_blue.png',
    'ship/rig/sail_red.png',
    'ship/rig/flag_blue.png',
    'ship/rig/flag_red.png',
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

  static Future<BattleSprites> load(Images images) async {
    await images.loadAll(files);
    return BattleSprites._(images);
  }

  final Images _images;

  Sprite get(String file) => Sprite(_images.fromCache(file));

  /// 칸 ([x], [y]) 의 무늬 번호 0~3 (에셋 `ship/tiles_v2/README.txt`). 칸 위치로
  /// 정해져 리플레이에서도 같다 (설계서 §10.2).
  static int variantOf(int x, int y) => (x * 7 + y * 13 + (x * y) % 5) % 4;

  /// 칸 ([x], [y]) 의 재질 타일(멀쩡한 모습). 손상 단계는 ShipView 가 코드로
  /// 덧그린다 (설계서 §10.2, ADR-030). 용골 줄([keel])은 바닥 타일, 철판은 한 가지다.
  Sprite tile(BlockMaterial m, int x, int y, {bool keel = false}) {
    if (m == BlockMaterial.iron && !keel) return get('ship/tiles_v2/iron.png');
    final name = keel
        ? 'bot'
        : m == BlockMaterial.net
        ? 'mesh'
        : m.name;
    return get('ship/tiles_v2/${name}_${variantOf(x, y)}.png');
  }

  /// 선실 칸 안쪽 벽 (설계서 §10.2, ADR-057). 등불 타일은 1칸짜리 에셋이 없다.
  Sprite roomWall(int x, int y) =>
      get('ship/tiles_v2/room_${variantOf(x, y) % 2}.png');
}
