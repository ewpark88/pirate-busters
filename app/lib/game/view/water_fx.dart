import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';

/// 물 연출 (설계서 §10.4): 거품, 물방울. 그리기만 한다.
abstract final class WaterFx {
  static const String bubble = 'fx/collapse/bubble.png';
  static const String drop = 'fx/collapse/water_drop.png';
  static const String mist = 'fx/collapse/mist.png';
  static const String splashBig = 'fx/collapse/splash_big.png';

  /// 전장이 미리 읽는 그림.
  static const List<String> files = [bubble, drop, mist];
}

/// 물 연출 띄우기.
extension WaterEffects on FxLayer {
  /// 거품 하나가 [at] 에서 수면([surfaceY])까지 흔들리며 떠오른다.
  void bubbleUp(Vector2 at, double surfaceY) {
    final rise = math.max(8, at.y - surfaceY);
    final size = 5 + rnd.nextDouble() * 5;
    spawn(
      SpriteComponent(
        sprite: sprites.get(WaterFx.bubble),
        position: at + Vector2((rnd.nextDouble() - .5) * 14, 0),
        size: Vector2.all(size),
        anchor: Anchor.center,
        children: [
          MoveByEffect(
            Vector2(0, -rise.toDouble()),
            EffectController(duration: .5 + rise / 120),
          ),
          MoveByEffect(
            Vector2(4, 0),
            EffectController(duration: .25, alternate: true, infinite: true),
          ),
          OpacityEffect.fadeOut(
            EffectController(duration: .25, startDelay: .3 + rise / 120),
          ),
          RemoveEffect(delay: .55 + rise / 120),
        ],
      ),
    );
  }

  /// 물방울: 수면 [at] 에서 튀어 올랐다가 떨어진다.
  void droplets(Vector2 at, {int count = 8}) => spawn(
    ParticleSystemComponent(
      position: at.clone(),
      particle: Particle.generate(
        count: few(count),
        lifespan: .7,
        generator: (i) => AcceleratedParticle(
          speed: Vector2(
            (rnd.nextDouble() - .5) * 120,
            -120 - rnd.nextDouble() * 120,
          ),
          acceleration: Vector2(0, 520),
          child: SpriteParticle(
            sprite: sprites.get(WaterFx.drop),
            size: Vector2.all(6 + rnd.nextDouble() * 4),
          ),
        ),
      ),
    ),
  );
}
