import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/view/fx_text.dart';
import 'package:pirate_busters/game/view/water_fx.dart';

/// 고유 효과 이벤트의 연출 (설계서 §4.8, §10.4, ADR-075·078). 판정은 끝났고 여기서는
/// 이름표·불티·번개·물보라만 고른다(절대 규칙 3).
extension UniqueCues on BattleCues {
  /// 한 묶음 안에서 같은 이름표는 [shown] 에 모아 한 번만 띄운다.
  void dispatchUnique(SimEvent e, Set<HitTag> shown) {
    void tagOnce(HitTag tag, Vector2 at) {
      if (shown.add(tag)) fx.tag(at, tagText(tag));
    }

    switch (e.kind) {
      case SimEventKind.ignited:
        final at = cellWorld(e.side, e.cell);
        fx.spawn(fx.popSprite('fx/impact/spark.png', at, 26, 0.35));
        tagOnce(HitTag.burn, at);
      case SimEventKind.burned:
        // 턴 끝에 타는 블록: 불티와 위로 번지는 연기 (설계서 §10.4).
        final at = cellWorld(e.side, e.cell);
        fx
          ..spawn(fx.popSprite('fx/impact/spark.png', at, 16, 0.4))
          ..spawn(
            fx.popSprite('fx/impact/puff_0.png', at - Vector2(0, 18), 26, 0.9),
          );
      case SimEventKind.chained:
        final at = cabinWorld(e.side, e.slot);
        fx.spawn(fx.popSprite('fx/impact/flash.png', at, 40, 0.25));
        tagOnce(HitTag.chain, at);
      case SimEventKind.statusApplied:
        final tag = HitTag.ofAbility(Ability.values[e.value]);
        final at = e.slot >= 0 ? cabinWorld(e.side, e.slot) : shipTop(e.side);
        if (tag != null) tagOnce(tag, at);
      case SimEventKind.mineFloated:
        final at = Coords.point(e.x, 0);
        fx.splash(at);
        tagOnce(HitTag.mine, at);
      case SimEventKind.steered:
        fx.spawn(
          fx.popSprite('fx/impact/spark.png', Coords.point(e.x, e.y), 30, 0.3),
        );
      case SimEventKind.supported:
        final at = shipTop(e.side);
        final tag = HitTag.ofAbility(Ability.values[e.value]);
        if (tag != null) tagOnce(tag, at);
        if (tag == HitTag.bail) {
          fx.droplets(Vector2(ships[e.side].position.x, 0), count: 14);
        }
      case SimEventKind.intercepted:
        final at = Coords.point(e.x, flockDropHeight);
        fx.explosion(at);
        tagOnce(HitTag.intercept, at);
        playSfx(Sfx.boom, volume: 0.6);
      case SimEventKind.barrierPlaced:
        final at = Coords.point(e.x, 0);
        fx.splash(at);
        tagOnce(HitTag.wall, at - Vector2(0, 40));
      case SimEventKind.barrierHit:
        final at = Coords.point(e.x, cellUnit * 2);
        fx.blockBroken(at);
        director.impact(at, punch: true);
        playSfx(Sfx.wood);
      case SimEventKind.revived:
        final at = cabinWorld(e.side, e.slot);
        fx.repair(at);
        tagOnce(HitTag.revive, at);
      case SimEventKind.healed:
        final at = cabinWorld(e.side, e.slot);
        fx.repair(at);
        tagOnce(HitTag.heal, at);
      case _:
        break;
    }
  }

  /// 진영 [side] 의 [slot] 선실 칸 월드 위치.
  Vector2 cabinWorld(int side, int slot) {
    final s = session.state.sides[side];
    if (slot < 0 || slot >= s.cabins.length) return shipTop(side);
    final c = s.cabins[slot];
    return cellWorld(side, s.grid.indexOf(c.x, c.y));
  }

  /// 진영 [side] 배 가운데 위(이름표 자리).
  Vector2 shipTop(int side) => ships[side].position - Vector2(0, 120);
}
