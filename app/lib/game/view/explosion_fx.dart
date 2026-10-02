import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:pirate_busters/game/sprites.dart';

/// 폭발 조각들 (설계서 §10.4 ‘여러 장의 불덩이 그림이 차례로 바뀌며 퍼지고, 불티가
/// 튀며, 맞은 칸에 그을음’, 에셋 README 폭발 v3·명중 임팩트 v2). 그리기만 한다.
abstract final class ExplosionFx {
  /// 불덩이 그림 (뜨거움 → 불 → 식음 → 속불 남은 연기 → 연기).
  static const List<String> fireballFrames = [
    'fx/impact/fireball_0_hot.png',
    'fx/impact/fireball_1_fire.png',
    'fx/impact/fireball_2_cool.png',
    'fx/impact/fireball_3_smoke_hot.png',
    'fx/impact/fireball_4_smoke.png',
  ];

  static const String ember = 'fx/impact/ember.png';
  static const String flame = 'fx/impact/flame.png';
  static const String smoke = 'fx/impact/smoke.png';
  static const String scorch = 'fx/impact/scorch.png';

  /// 전장이 미리 읽는 그림.
  static const List<String> files = [
    ...fireballFrames,
    ember,
    flame,
    smoke,
    scorch,
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

  /// 연기 덩이: 천천히 떠오른다.
  static ParticleSystemComponent puffs(
    BattleSprites sprites,
    math.Random rnd,
    Vector2 at, {
    required int count,
  }) => ParticleSystemComponent(
    position: at.clone(),
    particle: Particle.generate(
      count: count,
      lifespan: 1.2,
      generator: (i) => MovingParticle(
        to: Vector2((rnd.nextDouble() - 0.5) * 60, -40 - i * 10),
        child: SpriteParticle(
          sprite: sprites.get('fx/impact/puff_${i % 6}.png'),
          size: Vector2.all(36 + rnd.nextDouble() * 20),
        ),
      ),
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

  /// 연기 기둥: 떠오르며 커지고 흐려진다.
  static SpriteComponent rising(
    BattleSprites sprites,
    Vector2 at,
    double size, {
    double delay = 0,
  }) => SpriteComponent(
    sprite: sprites.get(smoke),
    position: at.clone(),
    size: Vector2.all(size),
    anchor: Anchor.center,
    children: [
      OpacityEffect.to(0, EffectController(duration: 0)),
      OpacityEffect.to(
        .75,
        EffectController(duration: 0.15, startDelay: delay),
      ),
      MoveByEffect(
        Vector2(0, -46),
        EffectController(duration: 1.3, startDelay: delay),
      ),
      ScaleEffect.to(
        Vector2.all(1.6),
        EffectController(duration: 1.3, startDelay: delay),
      ),
      OpacityEffect.to(
        0,
        EffectController(duration: 0.9, startDelay: delay + 0.4),
      ),
      RemoveEffect(delay: delay + 1.35),
    ],
  );

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

/// 불덩이 하나: 나이에 따라 그림이 뜨거움 → 연기로 바뀌며 빠르게 커졌다가 흐려진다
/// (에셋 README 폭발 v3: 커지는 시간상수 0.035초, 0.35초부터 식어 떠오름).
class Fireball extends PositionComponent {
  Fireball(this.frames, Vector2 at, this.size0, {this.delay = 0})
    : super(position: at.clone(), anchor: Anchor.center);

  final List<Sprite> frames;

  /// 다 커졌을 때의 지름(월드 px).
  final double size0;
  final double delay;
  double _age = 0;

  /// 전체 수명(초).
  static const double life = 0.62;

  /// 그림이 바뀌는 나이(초): 이 값을 넘을 때마다 다음 그림.
  static const List<double> stages = [0.06, 0.14, 0.26, 0.4];

  /// [age] 초에 그릴 그림 번호(0 ~ 4).
  static int frameAt(double age) {
    var i = 0;
    while (i < stages.length && age >= stages[i]) {
      i++;
    }
    return i;
  }

  /// [age] 초의 크기 배율: 빠르게 커지고, 식으면서 조금 더 퍼진다.
  static double scaleAt(double age) =>
      0.35 + 0.65 * (1 - math.exp(-age / 0.035)) + 0.3 * math.max(0, age - .35);

  /// [age] 초의 불투명도: 0.4초부터 끝까지 사라진다.
  static double alphaAt(double age) =>
      age < .4 ? 1 : (1 - (age - .4) / (life - .4)).clamp(0, 1);

  final Paint _paint = Paint();

  @override
  void update(double dt) {
    _age += dt;
    // 식은 연기는 위로 떠오른다.
    if (_age - delay > .35) position.y -= dt * 40;
    if (_age - delay >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final age = _age - delay;
    if (age < 0) return;
    _paint.color = Color.fromRGBO(255, 255, 255, alphaAt(age));
    frames[frameAt(age)].render(
      canvas,
      size: Vector2.all(size0 * scaleAt(age)),
      anchor: Anchor.center,
      overridePaint: _paint,
    );
  }
}
