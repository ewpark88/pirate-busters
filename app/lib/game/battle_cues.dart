import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/cues_boarding.dart';
import 'package:pirate_busters/game/cues_crew.dart';
import 'package:pirate_busters/game/cues_unique.dart';
import 'package:pirate_busters/game/emotion_cues.dart';
import 'package:pirate_busters/game/hit_stop.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/impact_sound.dart';
import 'package:pirate_busters/game/shooter_tracker.dart';
import 'package:pirate_busters/game/view/breakage_fx.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/fx_text.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';
import 'package:pirate_busters/game/view/ship_crew.dart';
import 'package:pirate_busters/game/view/ship_view.dart';
import 'package:pirate_busters/game/view/shot_fx.dart';
import 'package:pirate_busters/game/view/shot_view.dart';
import 'package:pirate_busters/game/weapon_styles.dart';

/// 시뮬레이션 이벤트를 화면 연출로 바꾼다 (설계서 §10.4, §10.5). 판정은 이미 끝났고
/// 여기서는 효과·소리·카메라만 고른다 (CLAUDE.md 절대 규칙 3).
class BattleCues {
  BattleCues({
    required this.session,
    required this.ships,
    required this.fx,
    required this.director,
    required this.rarity,
    required this.playSfx,
    required this.damageText,
    required this.tagText,
    this.weapons,
  });

  final BattleSession session;
  final List<ShipView> ships;
  final FxLayer fx;
  final CameraDirector director;
  final RarityFx rarity;
  final void Function(Sfx sfx, {double volume}) playSfx;

  /// 해적별 무기 그림(관통탄이 박혀 남는 그림). 없으면 그리지 않는다.
  final WeaponStyles? weapons;

  /// 피해 숫자·이름표 글자. 화면이 l10n 으로 만든다 (설계서 §14.2).
  final String Function(int amount) damageText;
  final String Function(HitTag tag) tagText;

  final HitStop stop = HitStop();

  /// 감정 연출 (설계서 §10.4): 한 턴 강조 문구 하나. 글자는 화면이 l10n 으로 넣는다.
  final EmotionTracker emotion = EmotionTracker();
  String Function(Emphasis e) emphasisText = (e) => e.name;

  /// 이번 묶음을 낸 해적 (A41 점검).
  final ShooterTracker _shooters = ShooterTracker();

  /// 칸 (진영 [side], 칸 번호 [cell]) 의 월드 위치.
  Vector2 cellWorld(int side, int cell) {
    final s = session.state.sides[side];
    final (x, y) = s.frame.cellCenter(
      cell % s.grid.width,
      cell ~/ s.grid.width,
    );
    return Coords.point(x, y);
  }

  /// [side] 배의 가운데 x 와 폭(월드 px). 착탄 카메라가 배 전체를 담는다 (A33).
  (double, double) shipSpan(int side) => (
    ships[side].position.x,
    session.state.sides[side].grid.width * Coords.cell,
  );

  /// 조용히 내려앉는 탄인가: 설치탄은 붙어서 턴을 기다린다. 선체에 닿아도 명중
  /// 연출(폭발·흔들림·히트스톱)을 내지 않는다 (설계서 §10.4 탄종별 전달). 크라키는
  /// 붙는 순간 터져서 명중 연출을 낸다.
  static bool landsQuietly(PirateSpec? spec) =>
      spec?.ammo == AmmoType.mine && spec!.ability != Ability.tentacle;

  void dispatch(List<SimEvent> cues) {
    var woodPlayed = false;
    final spec = _shooters.take(session);
    final tier = spec == null ? RarityFx.common : rarity.of(spec.rarity);
    final tag = spec == null ? null : HitTag.ofAmmo(spec.ammo);
    final shown = <HitTag>{};
    // 한 방 크기: 이 묶음 전체로 매겨 멈춤·흔들림·줌·숫자·진동을 맞춘다 (§10.4, A32).
    final weight = HitWeight.of(cues, critHit: tag == HitTag.crit);
    emote(cues, weight, quiet: landsQuietly(spec));
    var jolted = false;
    Vector2? hitAt;
    // 착탄마다 블록 피해를 모아 숫자 하나로 띄운다 (§10.4, A33).
    var hull = 0;
    final collapsed = <int, List<int>>{};
    void joltOnce(double scale) {
      if (jolted) return;
      jolted = true;
      fx.jolt(weight, scale: scale);
      stop.trigger(weight.hitStopSec, heavy: weight.isHeavy);
    }

    for (final e in cues) {
      switch (e.kind) {
        case SimEventKind.fire:
          ships[e.side].playAttack(e.slot);
          // 쏜 배는 쏜 쪽 반대로 살짝 밀린다 (A20).
          ships[e.side].recoil(-facingOf(e.side));
          fx.muzzle(Coords.point(e.x, e.y), facingOf(e.side));
          playSfx(Sfx.cannon);
        case SimEventKind.impact when landsQuietly(spec):
          // 설치 연출은 뒤따르는 mineAttached 이벤트가 그린다.
          director.impact(Coords.point(e.x, e.y));
        case SimEventKind.impact:
          final at = Coords.point(e.x, e.y);
          // 첫 착탄 전 피해(그물·돛 통과)는 이 착탄 숫자에 합친다.
          if (hitAt != null) {
            hullNumber(hitAt, hull, weight);
            hull = 0;
          }
          hitAt = at;
          // 맞은 배는 쏜 쪽 반대로 밀린다.
          final push = facingOf(1 - e.side);
          if (spec == null) {
            fx.explosion(at, radius: weight.isHeavy ? 2 : 1);
          } else {
            final style = spec.family == Family.pierce
                ? weapons?.of(session.speciesOf(spec.id))
                : null;
            fx.hit(
              at,
              spec.family,
              tier: tier,
              facing: push,
              stuck: style == null ? null : weapons?.sprite(style),
              radius: math.max(1, cappedBlastRadius(spec.blastRadius)),
              heavy: weight.isHeavy,
            );
          }
          director.impact(at, punch: weight.punch, ship: shipSpan(e.side));
          ships[e.side].rock(push);
          joltOnce(FxLayer.familyJolt(spec?.family) * tier.shake);
          for (final (sfx, volume) in impactLayers(
            weight,
            iron: ships[e.side].isIron(e.cell),
          )) {
            playSfx(sfx, volume: volume);
          }
        case SimEventKind.splash:
          final at = Coords.point(e.x, 0);
          fx
            ..splash(at)
            ..waterHit(at);
          director.impact(at);
          playSfx(Sfx.splash);
        case SimEventKind.blockDestroyed:
          fx.shatter(
            cellWorld(e.side, e.cell),
            tile: ships[e.side].builtTile(e.cell),
            iron: ships[e.side].isIron(e.cell),
            seed: e.side * 100000 + e.cell,
            from: hitAt,
          );
          if (!woodPlayed) playSfx(Sfx.wood);
          woodPlayed = true;
        case SimEventKind.blockHit:
          // 촉수처럼 착탄 없이 깎인 칸은 번쩍이지 않는다.
          if (hitAt != null || spec != null) flashCell(e);
          hull += e.value;
        case SimEventKind.blockCollapsed:
          // 끊긴 칸은 묶음이 끝난 뒤 덩어리로 묶어 떨어뜨린다 (§10.4, A32).
          (collapsed[e.side] ??= []).add(e.cell);
          ships[e.side].gone.add(e.cell);
        case SimEventKind.move || SimEventKind.pushed:
          // 한계(최소 간격·바다 끝)에 닿으면 물살이 튄다 (설계서 §2.5).
          final side = session.state.sides[e.side];
          final (lo, hi) = moveLimits(
            side,
            session.state.otherOf(e.side),
            session.state.rules,
          );
          if (side.offset == hi) fx.splash(Coords.point(e.x, 0), limit: true);
          if (side.offset == lo) {
            // 후퇴 한계에는 고물이 닿는다.
            final stern = ShotView.sternAt(
              e.x,
              facingOf(e.side),
              side.grid.width,
            );
            fx.splash(Coords.point(stern, 0), limit: true);
          }
        case SimEventKind.bounce:
          fx.splash(Coords.point(e.x, 0));
          playSfx(Sfx.splash, volume: 0.6);
        case SimEventKind.pirateHit:
          ships[e.side].playHit(e.slot, facingOf(1 - e.side));
          playSfx(Sfx.pirateHit);
          // 적 배 위에 선 강습 해적은 그 자리에 숫자를 띄운다 (ADR-110).
          final head = pirateHead(e);
          if (head != null) {
            fx.damageNumber(
              head,
              damageText(e.value),
              tag: tag == null ? null : tagText(tag),
              style: DamageStyle.of(weight, crit: tag == HitTag.crit),
            );
          }
        // 설치탄이 붙거나 기뢰가 터졌다(cues_unique.dart). 다른 턴 효과는 뒤따르는
        // 착탄 이벤트가 그린다.
        case SimEventKind.mineAttached || SimEventKind.effectFired:
          hitAt = effectCue(e, weight) ?? hitAt;
        case SimEventKind.turnStart ||
            SimEventKind.turnEnd ||
            SimEventKind.divide ||
            SimEventKind.moduleDestroyed:
          break;
        // 해적이 바다로 떨어지면 첨벙, 쓰러지면 띵 (§10.3, A32).
        case SimEventKind.pirateFell:
          boarderFell(e);
          pirateFell(e);
        case SimEventKind.pirateDown:
          pirateDown(e);
          playSfx(Sfx.ko);
        // 고유 효과·강습 체류 연출 (설계서 §4.8, ADR-075·078·110).
        case _:
          dispatchUnique(e, shown);
      }
    }
    hullNumber(hitAt, hull, weight);
    for (final MapEntry(key: side, value: cells) in collapsed.entries) {
      fx.collapseCells(
        cells,
        session.state.sides[side].grid.width,
        cellAt: (cell) => cellWorld(side, cell),
        tileOf: ships[side].builtTile,
        shipX: ships[side].position.x,
      );
      playSfx(Sfx.creak);
    }
  }
}
