import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/blast_sheet.dart';

/// 폭발 조각들 (설계서 §10.4 ‘여러 장의 불덩이 그림이 차례로 바뀌며 퍼지고, 불티가
/// 튀며, 맞은 칸에 그을음’, 에셋 README 폭발 v3·명중 임팩트 v2). 그리기만 한다.
abstract final class ExplosionFx {
  static const String ember = 'fx/impact/ember.png';
  static const String flame = 'fx/impact/flame.png';

  /// 연기 기둥 그림 6장 (Kenney Smoke Particles ‘Black smoke’, 색을 화풍에 맞춤).
  static List<String> get smokes => [
    for (var i = 0; i < 6; i++) 'fx/smoke/smoke_$i.png',
  ];

  /// 흰 연기 덩이 6장 (Kenney Smoke Particles ‘White puff’).
  static List<String> get whitePuffs => [
    for (var i = 0; i < 6; i++) 'fx/smoke/puff_$i.png',
  ];

  /// 전장이 미리 읽는 그림.
  static List<String> get files => [
    for (final s in BlastSheet.all) s.file,
    ember,
    flame,
    ...smokes,
    ...whitePuffs,
  ];

  /// 파편: 사방으로 튀어 올랐다가 떨어진다.
  static ParticleSystemComponent debris(
    BattleSprites sprites,
    math.Random rnd,
    Vector2 at, {
    required int count,
    bool plank = false,
  }) => ParticleSystemComponent(
    position: at.clone(),
    particle: Particle.generate(
      count: count,
      lifespan: 0.9,
      generator: (i) {
        final file = plank
            ? 'fx/impact/debris_plank.png'
            : 'fx/impact/debris_${rnd.nextInt(6)}.png';
        return AcceleratedParticle(
          speed: Vector2(
            (rnd.nextDouble() - 0.5) * 260,
            -80 - rnd.nextDouble() * 200,
          ),
          acceleration: Vector2(0, 600),
          child: RotatingParticle(
            to: (rnd.nextDouble() - 0.5) * 12,
            child: SpriteParticle(
              sprite: sprites.get(file),
              size: Vector2.all(10 + rnd.nextDouble() * 8),
            ),
          ),
        );
      },
    ),
  );

  /// 연기 덩이: 퍼지며 떠오르다 흐려진다. [dark] 면 검은 연기, 아니면 흰 연기.
  static ParticleSystemComponent puffs(
    BattleSprites sprites,
    math.Random rnd,
    Vector2 at, {
    required int count,
    bool dark = false,
    double size = 40,
  }) => ParticleSystemComponent(
    position: at.clone(),
    particle: Particle.generate(
      count: count,
      lifespan: 1.2,
      generator: (i) {
        final sprite = sprites.get((dark ? smokes : whitePuffs)[i % 6]);
        final s = size * (.8 + rnd.nextDouble() * .5);
        final paint = Paint();
        final drawSize = Vector2.zero();
        return MovingParticle(
          to: Vector2((rnd.nextDouble() - 0.5) * 50, -36 - i * 8),
          curve: Curves.easeOutCubic,
          child: ComputedParticle(
            renderer: (canvas, p) {
              final t = p.progress;
              // 불덩이에 가리지 않게 천천히 짙어졌다가 흐려진다.
              final fade = t < .3 ? t / .3 : 1.0;
              paint.color = Color.fromRGBO(255, 255, 255, .7 * fade * (1 - t));
              sprite.render(
                canvas,
                size: drawSize..setAll(s * (.6 + .9 * t)),
                anchor: Anchor.center,
                overridePaint: paint,
              );
            },
          ),
        );
      },
    ),
  );

  /// 불티: 위로 흩어졌다가 천천히 떨어지며 꺼진다.
  static ParticleSystemComponent embers(
    BattleSprites sprites,
    math.Random rnd,
    Vector2 at, {
    required int count,
    double reach = 1,
  }) => ParticleSystemComponent(
    position: at.clone(),
    particle: Particle.generate(
      count: count,
      lifespan: 0.8,
      generator: (i) {
        final a = -math.pi * rnd.nextDouble();
        final v = (90 + rnd.nextDouble() * 160) * reach;
        return AcceleratedParticle(
          speed: Vector2(math.cos(a) * v, math.sin(a) * v),
          acceleration: Vector2(0, 160),
          child: SpriteParticle(
            sprite: sprites.get(ember),
            size: Vector2.all(4 + rnd.nextDouble() * 4),
          ),
        );
      },
    ),
  );

  /// 연기 기둥 (설계서 §10.4 ‘연기는 떠오르며 흩어진다’): 검은 연기 [count] 덩이가
  /// 조금씩 늦게 올라가며 커지고 흐려진다.
  static List<SpriteComponent> rising(
    BattleSprites sprites,
    Vector2 at,
    double size, {
    double delay = 0,
    int count = 3,
  }) => [
    for (var i = 0; i < count; i++)
      SpriteComponent(
        sprite: sprites.get(smokes[(i * 2 + 1) % 6]),
        position: at + Vector2((i.isEven ? -1 : 1) * size * .12 * i, 0),
        size: Vector2.all(size * (1 - i * .12)),
        anchor: Anchor.center,
        angle: i * .9,
        children: [
          OpacityEffect.to(0, EffectController(duration: 0)),
          OpacityEffect.to(
            .6,
            EffectController(duration: 0.2, startDelay: delay + i * .14),
          ),
          MoveByEffect(
            Vector2(size * .1 * (i - 1), -size * (.9 + i * .25)),
            EffectController(
              duration: 1.6,
              startDelay: delay + i * .14,
              curve: Curves.easeOut,
            ),
          ),
          ScaleEffect.to(
            Vector2.all(1.9),
            EffectController(duration: 1.6, startDelay: delay + i * .14),
          ),
          OpacityEffect.to(
            0,
            EffectController(duration: 1, startDelay: delay + i * .14 + .6),
          ),
          RemoveEffect(delay: delay + i * .14 + 1.65),
        ],
      ),
  ];

  /// 잔불: 맞은 자리에서 잠깐 일렁이다 꺼진다(블록 화재 규칙은 R1, ADR-068).
  static SpriteComponent flicker(
    BattleSprites sprites,
    Vector2 at,
    double size,
    double delay,
  ) => SpriteComponent(
    sprite: sprites.get(flame),
    position: at.clone(),
    size: Vector2(size, size * 56 / 48),
    anchor: Anchor.bottomCenter,
    children: [
      OpacityEffect.to(0, EffectController(duration: 0)),
      OpacityEffect.to(1, EffectController(duration: 0.08, startDelay: delay)),
      ScaleEffect.to(
        Vector2(1.1, 0.85),
        EffectController(
          duration: 0.12,
          alternate: true,
          repeatCount: 3,
          startDelay: delay,
        ),
      ),
      OpacityEffect.to(
        0,
        EffectController(duration: 0.3, startDelay: delay + 0.45),
      ),
      RemoveEffect(delay: delay + 0.8),
    ],
  );
}
