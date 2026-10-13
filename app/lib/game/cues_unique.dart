import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/fx_text.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';
import 'package:pirate_busters/game/view/shot_fx.dart';
import 'package:pirate_busters/game/view/water_fx.dart';

/// 고유 효과 이벤트의 연출 (설계서 §4.8, §10.4, ADR-075·078). 판정은 끝났고 여기서는
/// 이름표·불티·번개·물보라만 고른다(절대 규칙 3).
extension UniqueCues on BattleCues {
  /// 수리 보급탄(톡·램프)이 상대 배를 맞히면 착탄 자리에 결과를 띄운다: 내 배를
  /// 고쳤으면 ‘수리’, 고칠 구멍이 없었으면 ‘고칠 곳 없음’. 카메라가 상대 배를 보고
  /// 있어 내 배의 수리 반짝임은 안 보이기 때문이다 (A39 점검, ADR-092).
  void supplyTag(PirateSpec? spec, Vector2? hitAt, List<SimEvent> cues) {
    final tag = spec == null || hitAt == null
        ? null
        : HitTag.ofSupply(spec, cues);
    if (tag != null) fx.tag(hitAt!, tagText(tag));
  }

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
        fx
          ..explosion(at)
          ..nudge(0.5);
        tagOnce(HitTag.intercept, at);
        playSfx(Sfx.boom, volume: 0.6);
      case SimEventKind.barrierPlaced:
        final at = Coords.point(e.x, 0);
        fx.splash(at);
        tagOnce(HitTag.wall, at - Vector2(0, 40));
      case SimEventKind.barrierHit:
        final at = Coords.point(e.x, cellUnit * 2);
        fx.blockBroken(at);
        director.impact(at, punch: 0.04);
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

  /// 턴 효과 [e] 가 설치탄·떠 있는 기뢰 폭발인가. 이 폭발은 비행 착탄이 아니라
  /// 착탄 이벤트가 없으므로 [mineBlast] 가 따로 그린다 (설계서 §4.8).
  bool isMineBlast(SimEvent e) =>
      e.kind == SimEventKind.effectFired &&
      (e.value == EffectKind.mineBlast.index ||
          e.value == EffectKind.floatMine.index);

  /// 설치탄이 붙으면 이름표만 단다(남은 턴 배지는 EffectBadges). 기뢰가 터졌으면
  /// [mineBlast] 로 그리고 피해 숫자 자리를 돌려준다. 다른 턴 효과는 null.
  Vector2? mineCue(SimEvent e, HitWeight weight) {
    if (isMineBlast(e)) return mineBlast(e, weight);
    if (e.kind == SimEventKind.mineAttached) {
      fx.tag(cellWorld(e.side, e.cell), tagText(HitTag.mine));
    }
    return null;
  }

  /// 기뢰 폭발 (설계서 §4.8, §10.4): 흘수선에서 물기둥과 폭발이 오르고, 카메라가
  /// 맞은 배를 담고, 배가 흔들리고 폭발음이 난다. 블록 피해 숫자를 붙일 자리를
  /// 돌려준다. 판정은 이미 끝났다(절대 규칙 3).
  Vector2 mineBlast(SimEvent e, HitWeight weight) {
    final at = e.cell >= 0 ? cellWorld(e.side, e.cell) : Coords.point(e.x, 0);
    final sea = Vector2(at.x, 0);
    fx
      ..splash(sea)
      ..waterHit(sea)
      ..explosion(at, heavy: weight.isHeavy)
      ..jolt(weight, scale: FxLayer.familyJolt(Family.underwater))
      ..tag(at, tagText(HitTag.mineBlast));
    stop.trigger(weight.hitStopSec, heavy: weight.isHeavy);
    director.impact(at, punch: weight.punch, ship: shipSpan(e.side));
    ships[e.side].rock(facingOf(1 - e.side));
    playSfx(Sfx.boom);
    playSfx(Sfx.splash, volume: 0.7);
    return at;
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
