import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/cues_unique.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/view/boarder_view.dart';
import 'package:pirate_busters/game/view/fx_text.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';
import 'package:pirate_busters/game/view/ship_crew.dart';

/// 강습 해적 적 갑판 체류 연출 (설계서 §2.3, §4.8, §10.4, ADR-110): 쿵 하고 올라타고,
/// 상대 턴마다 물고, 근처 해적이 반격하고, 흔들려 떨어진다. 판정은 끝났고 여기서는
/// 효과·이름표·소리·카메라만 고른다(절대 규칙 3).
extension BoardingCues on BattleCues {
  /// 전장에 붙은 [BoarderView]. 없으면(테스트 등) null.
  BoarderView? get boarders =>
      fx.parent?.children.whereType<BoarderView>().firstOrNull;

  /// 진영 [side] 의 [slot] 해적이 적 배 위에 섰(던) 발 위치. 아니면 null.
  Vector2? boarderFeet(int side, int slot) {
    final view = boarders;
    if (view != null) return view.feetOf(side, slot);
    final p = session.state.sides[side].crew.pirates[slot];
    return p.status == PirateStatus.boarding
        ? BoarderView.liveFeet(ships[1 - side], p.boardCell)
        : null;
  }

  /// 해적 피해 숫자 자리: 적 배 위에 선 해적이면 그 머리 위, 아니면 선실 해적 머리 위.
  Vector2? pirateHead(SimEvent e) {
    final ship = ships[e.side];
    if (e.slot < 0 || e.slot >= ship.rigs.length) return null;
    final lift = Vector2(0, Coords.pirateHeight * 0.8);
    final feet = boarderFeet(e.side, e.slot);
    if (feet != null) return feet - Vector2(0, BoarderView.bodySize.y) + lift;
    return ship.rigs[e.slot].absolutePosition - lift;
  }

  /// 턴 효과 [e] 의 연출: 기뢰 폭발·설치탄 붙음(`mineCue`)과 강습 추가 물기. 피해 숫자를
  /// 붙일 자리를 돌려준다. 다른 턴 효과는 null(뒤따르는 착탄이 그린다).
  Vector2? effectCue(SimEvent e, HitWeight weight) {
    final mine = mineCue(e, weight);
    if (mine != null || e.kind != SimEventKind.effectFired) return mine;
    if (e.value != EffectKind.biteAgain.index) return null;
    // 강습 해적이 선 자리에서 문다. 데비 해골 선원은 물린 칸에서.
    final at = boarderFeet(1 - e.side, e.slot) ?? cellWorld(e.side, e.cell);
    final bite = at - Vector2(0, BoarderView.bodySize.y * 0.3);
    fx
      ..hit(bite, Family.assault, facing: facingOf(1 - e.side))
      ..jolt(weight, scale: 0.6)
      ..tag(bite, tagText(HitTag.bite));
    director.impact(bite, punch: weight.punch, ship: shipSpan(e.side));
    ships[e.side].rock(facingOf(1 - e.side));
    playSfx(Sfx.wood, volume: 0.6);
    return bite;
  }

  /// 체류 이벤트 연출: 올라탐(쿵·먼지·이름표), 근접 수비(반격 섬광), 돌아옴.
  void boardingCue(SimEvent e, Set<HitTag> shown) {
    void tagOnce(HitTag tag, Vector2 at) {
      if (shown.add(tag)) fx.tag(at, tagText(tag));
    }

    switch (e.kind) {
      case SimEventKind.boarded:
        final at = boarderFeet(e.side, e.slot);
        if (at == null) return;
        fx
          ..spawn(fx.popSprite('fx/impact/puff_0.png', at, 34, 0.5))
          ..spawn(fx.popSprite('fx/impact/shockwave.png', at, 46, 0.3))
          ..nudge(0.35);
        ships[1 - e.side].rock(facingOf(e.side));
        tagOnce(HitTag.boarded, at - Vector2(0, BoarderView.bodySize.y));
        playSfx(Sfx.wood);
      case SimEventKind.boardDefended:
        // 반격한 해적이 몸을 내밀고, 강습 해적 쪽에 섬광이 튄다.
        ships[e.side].playAttack(e.slot);
        final at = boarderFeet(1 - e.side, e.value);
        if (at == null) return;
        final body = at - Vector2(0, BoarderView.bodySize.y * 0.5);
        fx.spawn(fx.popSprite('fx/impact/flash.png', body, 30, 0.2));
        tagOnce(HitTag.repel, body - Vector2(0, 24));
      case _:
        break;
    }
  }

  /// 적 배 위에 섰던 해적이 바다로 떨어졌다: ‘털어냄’ 이름표와 첨벙.
  void boarderFell(SimEvent e) {
    final view = boarders;
    if (view == null) return;
    var at = view.feetOf(e.side, e.slot);
    final cell = session.state.sides[e.side].crew.pirates[e.slot].boardCell;
    if (at == null && cell >= 0) {
      // 올라탄 묶음 안에서 바로 떨어졌다: 남은 밟은 칸에서 떨어뜨린다.
      at = BoarderView.liveFeet(ships[1 - e.side], cell);
      view.dropFrom(e.side, e.slot, at);
    }
    if (at == null) return;
    fx
      ..tag(at - Vector2(0, BoarderView.bodySize.y), tagText(HitTag.shakenOff))
      ..splash(Vector2(at.x, 0));
    playSfx(Sfx.splash);
  }
}
