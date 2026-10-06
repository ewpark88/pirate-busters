import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/fx_text.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';
import 'package:pirate_busters/game/view/water_fx.dart';

/// 해적 반응 연출 (설계서 §10.4, A32): 바다 추락과 쓰러짐. 판정은 끝났다.
extension CrewCues on BattleCues {
  /// 해적이 바다로 떨어졌다: 포물선으로 날아가 수면에 닿을 때 물보라와 첨벙.
  void pirateFell(SimEvent e) {
    final ship = ships[e.side];
    if (e.slot < 0 || e.slot >= ship.rigs.length) return;
    final rig = ship.rigs[e.slot];
    ship.reactions.fall(e.slot, rig.home, () {
      final sea = Vector2(rig.absolutePosition.x, 0);
      fx
        ..spawn(fx.popSprite('fx/splash.png', sea - Vector2(0, 26), 70, .5))
        ..droplets(sea, count: fx.few(8));
      playSfx(Sfx.plunge);
    });
  }

  /// 맞은 칸이 0.1초 하얗게 번쩍인다 (설계서 §10.4 명중, A32). 이번에 부서진 칸도
  /// 번쩍인다: `blockHit` 마다 부른다 (A33).
  void flashCell(SimEvent e) {
    if (e.cell < 0) return;
    fx.spawn(
      RectangleComponent(
        position: cellWorld(e.side, e.cell),
        size: Vector2.all(Coords.cell),
        anchor: Anchor.center,
        angle: ships[e.side].angle,
        paint: Paint()..color = const Color(0xCCFFFFFF),
        priority: 3,
        children: [
          OpacityEffect.fadeOut(EffectController(duration: .1)),
          RemoveEffect(delay: .1),
        ],
      ),
    );
  }

  /// 한 착탄의 선체 피해 합 [amount] 를 맞은 곳 [at] 위에 띄운다 (설계서 §10.4 피해
  /// 숫자, A33). 해적 숫자보다 조금 위에서 시작한다.
  void hullNumber(Vector2? at, int amount, HitWeight weight) {
    if (at == null || amount <= 0) return;
    fx.damageNumber(
      at - Vector2(0, Coords.cell),
      damageText(amount),
      style: DamageStyle.of(weight),
    );
  }

  /// 해적이 쓰러졌다: 머리 위에 별이 돌고 띵 소리 (소리는 [BattleCues.dispatch]).
  void pirateDown(SimEvent e) {
    final ship = ships[e.side];
    if (e.slot < 0 || e.slot >= ship.rigs.length) return;
    final head =
        ship.rigs[e.slot].absolutePosition -
        Vector2(0, Coords.pirateHeight * 1.05);
    for (var i = 0; i < 3; i++) {
      final a = i * 2 * math.pi / 3;
      fx.spawn(
        SpriteComponent(
          sprite: fx.sprites.get('fx/impact/dizzy_star.png'),
          position: head + Vector2(math.cos(a) * 12, math.sin(a) * 4),
          size: Vector2.all(14),
          anchor: Anchor.center,
          priority: 8,
          children: [
            MoveAlongPathEffect(
              Path()..addOval(
                Rect.fromCenter(
                  center: Offset(-math.cos(a) * 12, -math.sin(a) * 4),
                  width: 24,
                  height: 8,
                ),
              ),
              EffectController(duration: .5, infinite: true),
            ),
            OpacityEffect.fadeOut(
              EffectController(duration: .3, startDelay: 1.1),
            ),
            RemoveEffect(delay: 1.4),
          ],
        ),
      );
    }
  }
}
