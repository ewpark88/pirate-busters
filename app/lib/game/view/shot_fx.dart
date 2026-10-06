import 'package:flame/components.dart';
import 'package:pirate_busters/game/view/explosion_fx.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/water_fx.dart';

/// 발사와 물 착탄 연출 (설계서 §10.4, A32). 그리기만 한다.
extension ShotFx on FxLayer {
  /// 발사 (설계서 §10.4 발사): 쏜 자리(포구)에 불꽃과 연기가 터진다. [facing] 은 쏜
  /// 배가 보는 방향으로, 불꽃이 그쪽으로 조금 치우친다.
  void muzzle(Vector2 at, int facing) {
    final mouth = at + Vector2(facing * 10, -4);
    spawn(popSprite('fx/impact/flash.png', mouth, 46, 0.12));
    spawn(popSprite('fx/impact/spark.png', mouth, 30, 0.16));
    spawn(ExplosionFx.puffs(sprites, rnd, mouth, count: few(2)));
  }

  /// 물 착탄 (설계서 §10.4 물 착탄): 빗나간 탄이 물기둥과 물방울을 올리고 가볍게
  /// 흔든다. 물보라 그림은 [splash] 가 그린다.
  void waterHit(Vector2 sea) {
    spawn(
      popSprite('fx/collapse/water_spike.png', sea - Vector2(0, 30), 56, 0.45),
    );
    droplets(sea, count: few(8));
    nudge(0.3);
  }
}
