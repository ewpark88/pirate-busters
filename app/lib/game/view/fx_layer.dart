// mozzi lib/game/effects/particle_effects.dart·run_fx.dart 의 구성을 가져와 고쳤다
// (ADR-004): 에셋 fx 이미지 파편·연기, 화면 흔들림·진동. 판정과 무관하다.
import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/explosion_fx.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';
import 'package:pirate_busters/game/view/impact_accent.dart';
import 'package:pirate_busters/game/view/shake.dart';

/// 착탄 효과를 월드에 띄운다 (설계서 §10.3 타격감).
class FxLayer extends Component {
  FxLayer({
    required this.sprites,
    this.lowEnd,
    this.vibration,
    this.calmShake,
    super.priority,
  });

  final BattleSprites sprites;

  /// 저사양 모드: 파티클 수를 절반으로 (설계서 §12, §13.8).
  final ValueListenable<bool>? lowEnd;

  /// 설정의 진동 (설계서 §13.8). 끄면 햅틱을 내지 않는다.
  final ValueListenable<bool>? vibration;

  /// 설정 '화면 흔들림 줄이기' (설계서 §13.8).
  final ValueListenable<bool>? calmShake;

  void _haptic(Future<void> Function() impact) {
    if (vibration?.value ?? true) unawaited(impact());
  }

  /// 저사양이면 [count] 의 절반(올림).
  int few(int count) => lowEnd?.value ?? false ? (count + 1) ~/ 2 : count;

  /// 연출 난수(판정과 무관, ADR-003 은 pb_sim 만).
  final math.Random rnd = math.Random(7);

  /// 쌓이는 흔들림 (설계서 §10.4, A32). 착탄 묶음마다 [jolt] 로 더한다.
  final ScreenTrauma trauma = ScreenTrauma();

  /// 방금 띄운(아직 붙지 않았을 수 있는) 피해 숫자 자리와 띄운 시각. 숫자끼리
  /// 겹치지 않게 한다.
  final List<(Vector2, double)> pendingNumbers = [];

  /// 흐른 시간(초). [pendingNumbers] 를 비우는 데 쓴다.
  double clock = 0;

  bool get _calm => calmShake?.value ?? false;

  /// 지금 화면 흔들림 세기(월드 px).
  double get shake => trauma.amp(calm: _calm);

  /// 지금 카메라 기울기(rad). [t] 는 흔들림 시계.
  double shakeAngle(double t) => trauma.angle(t, calm: _calm);

  /// 계열마다 흔들림 비율 (설계서 §10.4): 작은 불꽃·구멍인 직사가 가장 작다.
  static double familyJolt(Family? family) => switch (family) {
    Family.direct => 0.8,
    Family.pierce => 0.85,
    Family.assault || Family.underwater => 0.9,
    _ => 1,
  };

  /// 한 착탄 묶음의 흔들림과 진동 (설계서 §10.4, A32). 진동은 한 묶음에 한 번, 한 방
  /// 크기에 따라 가벼움·중간·묵직이다. [scale] 은 계열·등급 비율.
  void jolt(HitWeight weight, {double scale = 1}) {
    trauma.add(weight.trauma * scale);
    _haptic(switch (weight.level) {
      HitLevel.light => HapticFeedback.lightImpact,
      HitLevel.medium => HapticFeedback.mediumImpact,
      HitLevel.heavy => HapticFeedback.heavyImpact,
    });
  }

  /// 착탄 없이 흔들림만(물 착탄·착수 등). 진동은 없다.
  void nudge(double amount) => trauma.atLeast(amount);

  /// 효과 하나를 띄운다.
  void spawn(Component c) {
    final r = add(c);
    if (r is Future<void>) unawaited(r);
  }

  /// 폭발 (설계서 §10.4): 섬광, 차례로 바뀌는 불덩이(가운데 큰 것과 둘레 작은 것),
  /// 불티, 파편, 떠오르는 연기, 잠깐 남는 잔불. [radius] 는 폭발 반경(칸), [heavy] 는
  /// 유폭(화약고·연료통)처럼 큰 폭발이다.
  void explosion(Vector2 at, {int radius = 1, bool heavy = false}) {
    final size = 48.0 + radius * 28;
    final frames = [for (final f in ExplosionFx.fireballFrames) sprites.get(f)];
    spawn(popSprite('fx/impact/flash.png', at, size * 1.2, 0.18));
    spawn(Fireball(frames, at, size * 1.1));
    // 둘레의 작은 불덩이 (README v3: 0.16·0.26초에 작은 폭발).
    for (var i = 0; i < few(heavy ? 4 : 2); i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final off = Vector2(math.cos(a), math.sin(a) * .6) * size * .35;
      spawn(Fireball(frames, at + off, size * .55, delay: .1 + i * .08));
    }
    spawn(ExplosionFx.embers(sprites, rnd, at, count: few(heavy ? 18 : 10)));
    spawn(ExplosionFx.debris(sprites, rnd, at, count: few(6 + radius * 3)));
    spawn(ExplosionFx.puffs(sprites, rnd, at, count: few(2 + radius)));
    spawn(ExplosionFx.rising(sprites, at, size * .7, delay: .3));
    for (var i = 0; i < few(3); i++) {
      final dx = (rnd.nextDouble() - .5) * size * .5;
      spawn(
        ExplosionFx.flicker(sprites, at + Vector2(dx, 6), 14, .27 + i * .05),
      );
    }
  }

  /// 계열별 명중 모양 (설계서 §10.4)과 등급 연출(§10.5). 흔들림·진동은 [jolt] 가
  /// 맡는다. [facing] 은 쏜 배가 보는 방향(강습 베기 방향). [stuck] 은 관통탄이 박혀
  /// 남는 무기 그림. [radius] 는 탄의 폭발 반경(칸), [heavy] 는 묵직한 한 방이라
  /// 충격파 고리를 더한다 (A32).
  void hit(
    Vector2 at,
    Family family, {
    RarityTier tier = RarityFx.common,
    int facing = 1,
    Sprite? stuck,
    int radius = 1,
    bool heavy = false,
  }) {
    var kind = AccentKind.impact;
    switch (family) {
      case Family.lob || Family.air || Family.support:
        explosion(at, radius: radius);
      case Family.direct:
        // 작은 불꽃과 구멍.
        _pop('fx/impact/spark.png', at, 40, 0.22);
        spawn(popSprite('fx/impact/hole_burnt.png', at, 20, 0.9));
      case Family.pierce:
        // 꿰뚫린 칸: 금과 구멍, 나무 조각.
        _pop('fx/impact/cracks.png', at, 34, 0.7);
        spawn(popSprite('fx/impact/hole_burnt.png', at, 16, 0.9));
        spawn(ExplosionFx.debris(sprites, rnd, at, count: few(3), plank: true));
        if (stuck != null) {
          // 박힌 무기: 날아온 방향으로 꽂힌 채 잠깐 남았다가 사라진다.
          spawn(
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
        _pop('fx/impact/shockwave.png', at, 72, 0.3);
        spawn(ExplosionFx.puffs(sprites, rnd, at, count: few(2)));
      case Family.underwater:
        // 물기둥과 침수 구멍.
        final sea = Vector2(at.x, 0);
        _pop('fx/collapse/water_spike.png', sea - Vector2(0, 34), 70, 0.5);
        spawn(popSprite('fx/collapse/foam_ring.png', sea, 64, 0.6));
        spawn(popSprite('fx/impact/hole_burnt.png', at, 20, 0.9));
      case Family.assault:
        _pop('fx/impact/burst.png', at, 44, 0.25);
        kind = AccentKind.slash;
    }
    if (heavy && family != Family.skip) {
      spawn(popSprite('fx/impact/shockwave.png', at, 60.0 + radius * 30, 0.35));
    }
    spawn(
      ImpactAccent(at, tier, kind: kind, facing: facing, fewer: few(2) == 1),
    );
  }

  /// 흰 섬광과 함께 [file] 을 띄운다. 맞는 순간의 히트스톱 동안 섬광이 멈춰 보인다.
  void _pop(String file, Vector2 at, double size, double life) {
    spawn(popSprite('fx/impact/flash.png', at, size * 0.9, 0.14));
    spawn(popSprite(file, at, size, life));
  }

  /// 지원탄 착지점: 초록 수리 반짝임과 등급 고리 (설계서 §10.4, §10.5).
  void repair(Vector2 at, {RarityTier tier = RarityFx.common}) {
    spawn(popSprite('fx/impact/dizzy_star.png', at, 30, 0.5));
    spawn(ImpactAccent(at, tier, kind: AccentKind.repair, fewer: few(2) == 1));
  }

  /// 블록 하나가 부서짐: 나무 조각.
  void blockBroken(Vector2 at) =>
      spawn(ExplosionFx.debris(sprites, rnd, at, count: few(4), plank: true));

  /// 물보라.
  /// [limit] 이면 한계선에 닿아 멈출 때의 물살이다 (설계서 §2.6, 그림 80×70).
  void splash(Vector2 at, {bool limit = false}) {
    spawn(
      limit
          ? (popSprite(BattleSprites.limitSplash, at - Vector2(0, 27), 80, 0.6)
              ..size.y = 70)
          : popSprite('fx/splash.png', at - Vector2(0, 30), 90, 0.6),
    );
  }

  /// [file] 을 [size] 크기로 띄워 [life] 초 동안 커지며 사라지게 한다.
  SpriteComponent popSprite(
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

  @override
  void update(double dt) {
    super.update(dt);
    trauma.update(dt);
    clock += dt;
    pendingNumbers.removeWhere((e) => clock - e.$2 > 0.1);
  }
}
