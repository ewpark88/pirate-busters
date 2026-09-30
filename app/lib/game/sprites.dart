import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';

/// 전장에서 쓰는 이미지 (에셋 v0.15, docs/ASSETS.md). 모두 @2x.
class BattleSprites {
  BattleSprites._(this._images);

  static final List<String> files = [
    for (final m in ['pine', 'oak', 'iron', 'cork', 'bottom'])
      for (final s in ['0', '1', '2', 'v0', 'v1', 'v2'])
        if (!(m == 'iron' && s.startsWith('v'))) 'ship/tiles/block_${m}_$s.png',
    'ship/tiles/hole.png',
    'ship/rig/mast.png',
    'ship/rig/sail_blue.png',
    'ship/rig/sail_red.png',
    'ship/rig/flag_blue.png',
    'ship/rig/flag_red.png',
    'fx/cannonball.png',
    'fx/explosion.png',
    'fx/splash.png',
    'fx/smoke.png',
    'fx/trajectory_dot.png',
    'fx/impact/flash.png',
    'fx/impact/spark.png',
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

  /// 재질·손상 단계 타일. 멀쩡한 칸은 [variant](0~2)로 무늬를 바꾼다. 망사는 null(코드로 그림).
  Sprite? tile(
    BlockMaterial m,
    DamageStage stage, {
    int variant = 0,
    bool keel = false,
  }) {
    if (m == BlockMaterial.net || stage == DamageStage.destroyed) return null;
    final name = keel ? 'bottom' : m.name;
    final s = switch (stage) {
      DamageStage.intact when m != BlockMaterial.iron => 'v${variant % 3}',
      DamageStage.intact => '0',
      DamageStage.cracked => '1',
      _ => '2',
    };
    return get('ship/tiles/block_${name}_$s.png');
  }
}
