import 'package:pb_sim/src/combat/boarding.dart';
import 'package:pb_sim/src/combat/chain.dart';
import 'package:pb_sim/src/combat/hit_helpers.dart';
import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/combat/legend_effects.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/world/world.dart';

/// 관통탄 두 번째 칸부터의 피해 비율(%) (BALANCE.md A4.8).
const int pierceFalloffPercent = 40;

/// 탄 [p] 가 [target] 배 로컬 칸 ([cx], [cy]), 월드 ([x], [y]) 에 닿았다 (설계서 §4.8).
/// 탄이 계속 날아가면(관통) false, 끝나면 true. 상대 배면 고유 능력 효과를 더한다.
bool onHullHit(
  MatchState state,
  Projectile p,
  SideState target, {
  required int cx,
  required int cy,
  required int x,
  required int y,
}) {
  final done =
      legendHullHit(state, p, target, cx: cx, cy: cy, x: x, y: y) ??
      _ammoHit(state, p, target, cx: cx, cy: cy, x: x, y: y);
  if (target.side != p.side) {
    applyHitAbility(state, p, target);
    // 강습 해적은 착지한 적 배 위에 선다 (설계서 §2.3, ADR-110).
    settleBoarder(state, p, target, cx);
  }
  return done;
}

bool _ammoHit(
  MatchState state,
  Projectile p,
  SideState target, {
  required int cx,
  required int cy,
  required int x,
  required int y,
}) {
  final spec = p.spec;
  final events = state.events;
  void impact({int blockPercent = 100, int piratePercent = 100}) =>
      resolveImpact(
        target,
        spec: spec,
        cx: cx,
        cy: cy,
        x: x,
        y: y,
        events: events,
        blockPercent: blockPercent,
        centerPiratePercent: piratePercent,
      );
  switch (spec.ammo) {
    case AmmoType.pierce:
      // 칸마다 피해를 주며 뚫는다. 두 번째 칸부터는 피해 40%. 블록이 버티면 멈춘다.
      final percent = p.piercedCells == 0 ? 100 : pierceFalloffPercent;
      impact(blockPercent: percent, piratePercent: percent);
      p.piercedCells++;
      if (!target.grid.hasBlock(cx, cy) && p.pierceLeft > 1) {
        p.pierceLeft--;
        return false;
      }
      return true;
    case AmmoType.mine:
      _attachMine(state, p, target, target.grid.indexOf(cx, cy));
      return true;
    case AmmoType.assault:
      // 착지 반경의 해적을 물고, 살아남으면 다음 상대 턴 시작에 한 번 더 문다.
      impact();
      state.effects.add(
        TurnEffect(
          kind: EffectKind.biteAgain,
          owner: p.side,
          ownerSlot: p.slot,
          target: target.side,
          trigger: target.side,
          turnsLeft: 1,
          spec: spec,
          cell: target.grid.indexOf(cx, cy),
        ),
      );
      return true;
    case AmmoType.shock:
      // 넓고 약하게 터지고 상대 배를 민다. 램프는 더 멀리 민다 (BALANCE.md A4.2).
      impact();
      if (target.side != p.side) {
        final cells = spec.ability == Ability.shove
            ? spec.abilityValue
            : spec.ammoValue;
        pushShip(state, target, cells);
      }
      return true;
    case AmmoType.chain:
      final struck = chainStruckCandidates(target, spec, cx: cx, cy: cy);
      final before = events.length;
      impact();
      spreadChain(
        state,
        target,
        spec,
        cx: cx,
        cy: cy,
        from: before,
        candidates: struck,
      );
      return true;
    case AmmoType.skip:
      // 수면에서 튕긴 뒤 물에 잠긴 줄 칸에 맞으면 ×1.5 (BALANCE.md A4.3).
      final waterline = p.bounced && cy <= target.draft ~/ cellUnit;
      impact(blockPercent: waterline ? 150 : 100);
      return true;
    case AmmoType.sniper:
      impact(piratePercent: spec.ammoValue);
      return true;
    case AmmoType.explosive ||
        AmmoType.fire ||
        AmmoType.split ||
        AmmoType.burst ||
        AmmoType.flock ||
        AmmoType.homing:
      impact();
      return true;
  }
}

/// 탄 [p] 가 [target] 쪽 바다 ([x], 0) 에 닿았다. 물수제비는 튕기고, 설치탄은 배 밑에
/// 붙는다. 탄이 계속 날면 false.
bool onSeaHit(
  MatchState state,
  Projectile p,
  SideState target,
  int x,
  int tick,
) {
  if (bounceOffSea(p, x)) {
    state.events.add(
      SimEvent(SimEventKind.bounce, side: target.side, x: x, value: tick),
    );
    return false;
  }
  if (p.spec.ammo == AmmoType.mine) {
    final cell = _hullCellBelow(target, x);
    if (cell >= 0) {
      _attachMine(state, p, target, cell);
      return true;
    }
  }
  state.events.add(
    SimEvent(SimEventKind.splash, side: target.side, x: x, value: tick),
  );
  return true;
}

/// 물수제비 튕김 입사각 상한: 세로 속도 ≤ 가로 속도 × 이 값 / 1000 (25°의 tan,
/// BALANCE.md A4.8).
const int skipMaxSlopePermille = 466;

/// 물수제비 튕김 감쇠(%): 세로·가로 (BALANCE.md A4.8).
const int skipBounceVyPercent = 45;
const int skipBounceVxPercent = 70;

/// 물수제비탄이 튕길 수 있으면 수면 ([x], 0) 에서 튕긴다 (설계서 §4.8): 튕김이
/// 남고 얕은 각도([skipMaxSlopePermille])로 닿을 때만, 세로 속도를 뒤집어 줄이고
/// 가로도 줄인다. 가파르면 첨벙이다. 튕겼으면 true.
bool bounceOffSea(Projectile p, int x) {
  if (p.spec.ammo != AmmoType.skip || p.bouncesLeft <= 0) return false;
  if (p.vy.abs() * 1000 > p.vx.abs() * skipMaxSlopePermille) return false;
  p
    ..bouncesLeft -= 1
    ..bounced = true
    ..placeAt(x, 0)
    ..vy = -p.vy * skipBounceVyPercent ~/ 100
    ..vx = p.vx * skipBounceVxPercent ~/ 100;
  return true;
}

/// 설치탄: 붙은 칸에서 다음 내 턴 시작에 터진다 (설계서 §4.8).
void _attachMine(MatchState state, Projectile p, SideState target, int cell) {
  if (attachTentacle(state, p, target, cell)) return;
  state.effects.add(
    TurnEffect(
      kind: EffectKind.mineBlast,
      owner: p.side,
      ownerSlot: p.slot,
      target: target.side,
      trigger: p.side,
      turnsLeft: 1,
      spec: p.spec,
      cell: cell,
    ),
  );
  state.events.add(
    SimEvent(SimEventKind.mineAttached, side: target.side, cell: cell),
  );
}

/// 바다 [x] 아래 선체 칸: 그 세로줄에서 흘수선에 가장 가까운 블록. 선체 밖이면 −1.
int _hullCellBelow(SideState target, int x) {
  final lx = target.frame.toLocalX(x);
  if (lx < 0 || lx >= target.grid.width * cellUnit) return -1;
  return waterlineCellIn(target, lx ~/ cellUnit);
}
