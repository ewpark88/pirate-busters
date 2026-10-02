// mozzi lib/game/effects/particle_effects.dart·run_fx.dart 의 구성을 가져와 고쳤다
// (ADR-004): 에셋 fx 이미지 파편·연기, 화면 흔들림·진동. 판정과 무관하다.
import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/collapse_fx.dart';
import 'package:pirate_busters/game/view/impact_accent.dart';

/// 착탄 효과를 월드에 띄운다 (설계서 §10.3 타격감).
class FxLayer extends Component {
  FxLayer({
    required this.sprites,
    this.lowEnd,
    this.vibration,
    super.priority,
  });

  final BattleSprites sprites;

  /// 저사양 모드: 파티클 수를 절반으로 (설계서 §12, §13.8).
  final ValueListenable<bool>? lowEnd;

  /// 설정의 진동 (설계서 §13.8). 끄면 햅틱을 내지 않는다.
  final ValueListenable<bool>? vibration;

  void _haptic(Future<void> Function() impact) {
    if (vibration?.value ?? true) unawaited(impact());
  }

  int _n(int count) => lowEnd?.value ?? false ? (count + 1) ~/ 2 : count;
  final math.Random _rnd = math.Random(7);

  /// 화면 흔들림 세기(월드 px). 카메라가 읽고 줄여 간다.
  double shake = 0;

  void _spawn(Component c) {
    final r = add(c);
    if (r is Future<void>) unawaited(r);
  }

  /// 폭발: 섬광 + 불덩이 + 파편 + 연기. [radius] 는 폭발 반경(칸).
  void explosion(Vector2 at, {int radius = 1, bool heavy = false}) {
    final size = 48.0 + radius * 28;
    _spawn(_popSprite('fx/impact/flash.png', at, size * 1.2, 0.18));
    _spawn(_popSprite('fx/explosion.png', at, size, 0.45));
    _spawn(_debris(at, count: _n(6 + radius * 3)));
    _spawn(_puffs(at, count: _n(3 + radius)));
    shake = math.max(shake, heavy ? 9 : 6);
    _haptic(heavy ? HapticFeedback.heavyImpact : HapticFeedback.mediumImpact);
  }

  /// 계열별 명중 모양 (설계서 §10.4)과 등급 연출(§10.5). 흔들림은 등급 배율을 곱한다.
  /// [facing] 은 쏜 배가 보는 방향(강습 베기 방향). [stuck] 은 관통탄이 박혀 남는
  /// 무기 그림.
  void hit(
    Vector2 at,
    Family family, {
    RarityTier tier = RarityFx.common,
    int facing = 1,
    Sprite? stuck,
  }) {
    var kind = AccentKind.impact;
    // 이번 명중의 흔들림에만 등급 배율을 곱한다(남아 있던 흔들림에는 곱하지 않는다).
    final before = shake;
    shake = 0;
    switch (family) {
      case Family.lob || Family.air || Family.support:
        explosion(at);
      case Family.direct:
        // 작은 불꽃과 구멍.
        _pop('fx/impact/spark.png', at, 40, 0.22, shakeTo: 3);
        _spawn(_popSprite('fx/impact/hole_burnt.png', at, 20, 0.9));
      case Family.pierce:
        // 꿰뚫린 칸: 금과 구멍, 나무 조각.
        _pop('fx/impact/cracks.png', at, 34, 0.7, shakeTo: 4);
        _spawn(_popSprite('fx/impact/hole_burnt.png', at, 16, 0.9));
        _spawn(_debris(at, count: _n(3), plank: true));
        if (stuck != null) {
          // 박힌 무기: 날아온 방향으로 꽂힌 채 잠깐 남았다가 사라진다.
          _spawn(
            SpriteComponent(
              children: [
                OpacityEffect.fadeOut(
                  EffectController(duration: 0.4, startDelay: 0.9),
                ),
                RemoveEffect(delay: 1.3),
              ],
              sprite: stuck,
              position: at.clone(),
              size: Vector2(32, 24),
              anchor: Anchor.center,
              angle: facing > 0 ? 0.35 : math.pi - 0.35,
            ),
          );
        }
      case Family.skip:
        // 쿵 하는 둥근 충격.
        _pop('fx/impact/shockwave.png', at, 72, 0.3, shakeTo: 7);
        _spawn(_puffs(at, count: _n(2)));
      case Family.underwater:
        // 물기둥과 침수 구멍.
        final sea = Vector2(at.x, 0);
        _pop('fx/collapse/water_spike.png', sea - Vector2(0, 34), 70, 0.5);
        _spawn(_popSprite('fx/collapse/foam_ring.png', sea, 64, 0.6));
        _spawn(_popSprite('fx/impact/hole_burnt.png', at, 20, 0.9));
        shake = math.max(shake, 5);
      case Family.assault:
        _pop('fx/impact/burst.png', at, 44, 0.25, shakeTo: 5);
        kind = AccentKind.slash;
    }
    shake = math.max(before, shake * tier.shake);
    _haptic(HapticFeedback.mediumImpact);
    _spawn(
      ImpactAccent(at, tier, kind: kind, facing: facing, fewer: _n(2) == 1),
    );
  }

  /// 흰 섬광과 함께 [file] 을 띄운다. 맞는 순간의 히트스톱 동안 섬광이 멈춰 보인다.
  void _pop(
    String file,
    Vector2 at,
    double size,
    double life, {
    double shakeTo = 0,
  }) {
    _spawn(_popSprite('fx/impact/flash.png', at, size * 0.9, 0.14));
    _spawn(_popSprite(file, at, size, life));
    shake = math.max(shake, shakeTo);
  }

  /// 지원탄 착지점: 초록 수리 반짝임과 등급 고리 (설계서 §10.4, §10.5).
  void repair(Vector2 at, {RarityTier tier = RarityFx.common}) {
    _spawn(_popSprite('fx/impact/dizzy_star.png', at, 30, 0.5));
    _spawn(ImpactAccent(at, tier, kind: AccentKind.repair, fewer: _n(2) == 1));
  }

  /// 블록 하나가 부서짐: 나무 조각.
  void blockBroken(Vector2 at) =>
      _spawn(_debris(at, count: _n(4), plank: true));

  /// 무너진 블록 (설계서 §10.4): [tile] 그림이 [lean] 쪽으로 기울며 떨어지고 수면에
  /// 물보라를 낸다. 그림이 없으면 나무 조각만 떨어진다.
  void collapsed(Vector2 at, {Sprite? tile, double lean = 0}) {
    _spawn(_debris(at, count: _n(2), plank: true));
    if (tile == null) return;
    _spawn(
      FallingChunk(
        sprite: tile,
        at: at,
        lean: lean,
        onSplash: (sea) {
          _spawn(
            _popSprite(
              'fx/collapse/splash_big.png',
              sea - Vector2(0, 22),
              64,
              .5,
            ),
          );
          if (_n(2) == 2) {
            _spawn(_popSprite('fx/collapse/foam_ring.png', sea, 56, 0.6));
          }
        },
      ),
    );
  }

  /// 물보라.
  void splash(Vector2 at) {
    _spawn(_popSprite('fx/splash.png', at - Vector2(0, 30), 90, 0.6));
    _haptic(HapticFeedback.lightImpact);
  }

  /// 피해 숫자 (설계서 §10.4): 튀어 올랐다가 사라지고, 특별한 결과는 아래에 이름표
  /// [tag] 를 붙인다. 글자는 화면이 l10n 으로 만들어 넘긴다 (§14.2).
  void damageNumber(Vector2 at, String label, {String? tag}) {
    TextPaint paint(double size, int color) => TextPaint(
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: size,
        color: Color(color),
        shadows: const [Shadow(blurRadius: 3)],
      ),
    );
    _spawn(
      TextComponent(
        children: [
          ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.18)),
          MoveByEffect(Vector2(0, -34), EffectController(duration: 0.9)),
          RemoveEffect(delay: 0.9),
          if (tag != null)
            TextComponent(
              text: tag,
              position: Vector2(0, 20),
              textRenderer: paint(11, 0xFFFFFFFF),
            ),
        ],
        text: label,
        position: at.clone(),
        scale: Vector2.all(1.7),
        anchor: Anchor.center,
        priority: 10,
        textRenderer: paint(18, 0xFFFFE082),
      ),
    );
  }

  /// 이름표만 띄운다(피해 숫자가 없는 특별한 결과: 설치·수리).
  void tag(Vector2 at, String label) => damageNumber(at, label);

  SpriteComponent _popSprite(
    String file,
    Vector2 at,
    double size,
    double life,
  ) {
    return SpriteComponent(
      children: [
        ScaleEffect.to(Vector2.all(1.25), EffectController(duration: life)),
        OpacityEffect.fadeOut(EffectController(duration: life)),
        RemoveEffect(delay: life),
      ],
      sprite: sprites.get(file),
      position: at.clone(),
      size: Vector2.all(size),
      anchor: Anchor.center,
    );
  }

  ParticleSystemComponent _debris(
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
            : 'fx/impact/debris_${_rnd.nextInt(6)}.png';
        return AcceleratedParticle(
          speed: Vector2(
            (_rnd.nextDouble() - 0.5) * 260,
            -80 - _rnd.nextDouble() * 200,
          ),
          acceleration: Vector2(0, 600),
          child: RotatingParticle(
            to: (_rnd.nextDouble() - 0.5) * 12,
            child: SpriteParticle(
              sprite: sprites.get(file),
              size: Vector2.all(10 + _rnd.nextDouble() * 8),
            ),
          ),
        );
      },
    ),
  );

  ParticleSystemComponent _puffs(Vector2 at, {required int count}) =>
      ParticleSystemComponent(
        position: at.clone(),
        particle: Particle.generate(
          count: count,
          lifespan: 1.2,
          generator: (i) => MovingParticle(
            to: Vector2((_rnd.nextDouble() - 0.5) * 60, -40 - i * 10),
            child: SpriteParticle(
              sprite: sprites.get('fx/impact/puff_${i % 6}.png'),
              size: Vector2.all(36 + _rnd.nextDouble() * 20),
            ),
          ),
        ),
      );

  @override
  void update(double dt) {
    super.update(dt);
    shake = math.max(0, shake - dt * 30);
  }
}
