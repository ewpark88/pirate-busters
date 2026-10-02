import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/impact_accent.dart';
import 'package:pirate_busters/game/view/ship_view.dart';
import 'package:pirate_busters/game/view/shot_view.dart';
import 'package:pirate_busters/game/weapon_styles.dart';

/// 히트스톱 (설계서 §10.4): 맞는 순간 연출만 0.07초 멈춘다. 렌더만 멈추고 시뮬레이션
/// 진행·턴 타이머는 그대로 흐른다.
class HitStop {
  /// 히트스톱 사이 최소 간격(초): 연사탄이 화면을 계속 멈추지 않게 한다.
  static const double gap = 0.3;

  double _left = 0;
  double _since = gap;

  /// 명중했다. 직전 히트스톱에서 [gap] 이 지나지 않았으면 다시 멈추지 않는다.
  void trigger() {
    if (_since < gap) return;
    _left = ImpactAccent.hitStop;
    _since = 0;
  }

  /// 히트스톱을 뺀 연출용 dt. 멈춘 동안에는 0 이다.
  double visualDt(double dt) {
    _since += dt;
    if (_left <= 0) return dt;
    _left -= dt;
    return 0;
  }
}

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

  /// 지금 탄을 쏜 해적의 정의. 턴 효과로 터진 것이면 null.
  PirateSpec? get _shooter {
    final p = session.playback;
    if (p is! ShotPlayback) return null;
    return session.state.sides[p.side].crew.pirates[p.slot].spec;
  }

  Vector2 _cellWorld(int side, int cell) {
    final s = session.state.sides[side];
    final (x, y) = s.frame.cellCenter(
      cell % s.grid.width,
      cell ~/ s.grid.width,
    );
    return Coords.point(x, y);
  }

  /// 조용히 내려앉는 탄인가: 지원탄은 우리 배에 닿아 고치고, 설치탄은 붙어서 턴을
  /// 기다린다. 선체에 닿아도 명중 연출(폭발·흔들림·히트스톱)을 내지 않는다
  /// (설계서 §10.4 탄종별 전달).
  static bool landsQuietly(PirateSpec? spec) =>
      spec != null &&
      (spec.ammo == AmmoType.support || spec.ammo == AmmoType.mine);

  void dispatch(List<SimEvent> cues) {
    var woodPlayed = false;
    var repairTagged = false;
    final spec = _shooter;
    final tier = spec == null ? RarityFx.common : rarity.of(spec.rarity);
    final tag = spec == null ? null : HitTag.ofAmmo(spec.ammo);
    for (final e in cues) {
      switch (e.kind) {
        case SimEventKind.fire:
          ships[e.side].playAttack(e.slot);
          playSfx(Sfx.cannon);
        case SimEventKind.impact when landsQuietly(spec):
          // 수리·설치 연출은 뒤따르는 repaired·mineAttached 이벤트가 그린다.
          director.impact(Coords.point(e.x, e.y));
        case SimEventKind.impact:
          final at = Coords.point(e.x, e.y);
          // 맞은 배는 쏜 쪽 반대로 밀린다.
          final push = facingOf(1 - e.side);
          if (spec == null) {
            fx.explosion(at);
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
            );
          }
          director.impact(at, punch: true);
          ships[e.side].rock(push);
          stop.trigger();
          playSfx(
            ships[e.side].isIron(e.cell) ? Sfx.clang : Sfx.cannon,
            volume: 0.8,
          );
        case SimEventKind.splash:
          final at = Coords.point(e.x, 0);
          fx.splash(at);
          director.impact(at);
          playSfx(Sfx.splash);
        case SimEventKind.blockDestroyed:
          fx.blockBroken(_cellWorld(e.side, e.cell));
          if (!woodPlayed) playSfx(Sfx.wood);
          woodPlayed = true;
        case SimEventKind.blockCollapsed:
          // 끊긴 덩어리는 배 가운데에서 먼 쪽으로 기울며 떨어진다.
          final at = _cellWorld(e.side, e.cell);
          final outward = (at.x - ships[e.side].position.x).sign;
          fx.collapsed(
            at,
            tile: ships[e.side].builtTile(e.cell),
            lean: outward * 2.2,
          );
        case SimEventKind.move:
          // 한계선에 닿으면 물살이 튄다 (설계서 §2.6).
          final side = session.state.sides[e.side];
          final (lo, hi) = moveLimits(session.state.rules, session.state.turn);
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
          ships[e.side].playHit(e.slot);
          final rig = e.slot >= 0 && e.slot < ships[e.side].rigs.length
              ? ships[e.side].rigs[e.slot]
              : null;
          if (rig != null) {
            fx.damageNumber(
              rig.absolutePosition - Vector2(0, Coords.pirateHeight * 0.8),
              damageText(e.value),
              tag: tag == null ? null : tagText(tag),
            );
          }
        case SimEventKind.mineAttached:
          // 설치탄이 붙었다: 남은 턴 배지는 EffectBadges 가 그린다.
          fx.tag(_cellWorld(e.side, e.cell), tagText(HitTag.mine));
        case SimEventKind.repaired:
          final at = _cellWorld(e.side, e.cell);
          fx.repair(at, tier: tier);
          if (!repairTagged) fx.tag(at, tagText(HitTag.repair));
          repairTagged = true;
        case SimEventKind.turnStart ||
            SimEventKind.turnEnd ||
            SimEventKind.pirateFell ||
            SimEventKind.pirateReturned ||
            SimEventKind.pirateDown ||
            SimEventKind.flood ||
            SimEventKind.stormStart ||
            // 터진 턴 효과는 뒤따르는 착탄 이벤트가 그린다.
            SimEventKind.divide ||
            SimEventKind.effectFired ||
            SimEventKind.moduleDestroyed:
          break;
      }
    }
  }
}
