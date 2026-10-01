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
import 'package:pirate_busters/game/sprites.dart';

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

  /// 블록 하나가 부서짐: 나무 조각.
  void blockBroken(Vector2 at) =>
      _spawn(_debris(at, count: _n(4), plank: true));

  /// 무너진 블록: 아래로 떨어지는 조각.
  void collapsed(Vector2 at) => _spawn(_debris(at, count: _n(2), plank: true));

  /// 물보라.
  void splash(Vector2 at) {
    _spawn(_popSprite('fx/splash.png', at - Vector2(0, 30), 90, 0.6));
    _haptic(HapticFeedback.lightImpact);
  }

  /// 피해 숫자. 글자는 화면이 l10n 으로 만들어 넘긴다 (설계서 §14.2).
  void damageNumber(Vector2 at, String label) {
    final text = TextComponent(
      children: [
        MoveByEffect(Vector2(0, -34), EffectController(duration: 0.9)),
        RemoveEffect(delay: 0.9),
      ],
      text: label,
      position: at.clone(),
      anchor: Anchor.center,
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Jua',
          fontSize: 18,
          color: Color(0xFFFFE082),
          shadows: [Shadow(blurRadius: 3)],
        ),
      ),
    );
    _spawn(text);
  }

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
