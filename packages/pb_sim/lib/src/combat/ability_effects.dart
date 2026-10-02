import 'package:pb_sim/src/combat/ammo_rules.dart';
import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/combat/unique_moves.dart';
import 'package:pb_sim/src/combat/unique_turns.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/pirate/ability.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/motion.dart';
import 'package:pb_sim/src/world/world.dart';

/// 연쇄탄 번짐 피해 비율(%) (BALANCE.md A4.8, ADR-075).
const int chainSpreadPercent = 50;

/// 연쇄탄이 직접 맞힐 수 있는 해적: 착탄 칸 ([cx], [cy]) 폭발 범위 안 선실에 타
/// 있는 슬롯. 착탄 전에 구한다(낙하·헤엄꾼·유폭 피해는 ‘맞힘’이 아니다, ADR-075).
List<int> chainStruckCandidates(
  SideState target,
  PirateSpec spec, {
  required int cx,
  required int cy,
}) {
  final r = cappedBlastRadius(spec.blastRadius);
  return [
    for (var slot = 0; slot < target.crew.size; slot++)
      if (target.crew.pirates[slot].status == PirateStatus.aboard &&
          _within(target.cabins[slot].x - cx, target.cabins[slot].y - cy, r))
        slot,
  ];
}

bool _within(int dx, int dy, int r) => dx * dx + dy * dy <= r * r;

/// 연쇄탄 (설계서 §4.8): 이번 착탄(이벤트 [from] 번째부터)에서 [candidates] 해적을
/// 맞혔으면, 같은 배의 아직 맞지 않은 배 위 해적에게 착탄 칸 ([cx], [cy]) 에서 가까운
/// 순(같으면 낮은 슬롯)으로 [PirateSpec.ammoValue] 명까지 해적 피해의 50% 를 준다.
void spreadChain(
  MatchState state,
  SideState target,
  PirateSpec spec, {
  required int cx,
  required int cy,
  required int from,
  required List<int> candidates,
}) {
  final events = state.events;
  final hit = <int>[];
  for (var i = from; i < events.length; i++) {
    final e = events[i];
    if (e.kind == SimEventKind.pirateHit &&
        e.side == target.side &&
        candidates.contains(e.slot) &&
        !hit.contains(e.slot)) {
      hit.add(e.slot);
    }
  }
  if (hit.isEmpty) return;
  final crew = target.crew;
  final next = <(int, int)>[];
  for (var slot = 0; slot < crew.size; slot++) {
    if (hit.contains(slot)) continue;
    if (crew.pirates[slot].status != PirateStatus.aboard) continue;
    final c = target.cabins[slot];
    next.add(((c.x - cx) * (c.x - cx) + (c.y - cy) * (c.y - cy), slot));
  }
  next.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  final dmg = roundDiv(spec.pirateDamage * chainSpreadPercent, 100);
  for (final (_, slot) in next.take(spec.ammoValue)) {
    events.add(SimEvent(SimEventKind.chained, side: target.side, slot: slot));
    crew.damage(slot, dmg, target.side, events);
  }
}

/// 탄 [p] 가 상대 배 [target] 의 칸 ([cx], [cy]) 에 맞았을 때의 고유 능력 효과
/// (설계서 §4.8 고유 효과 공통 규칙, ADR-075). 탄마다 한 번만 낸다.
void applyHitAbility(
  MatchState state,
  Projectile p,
  SideState target, {
  required int cx,
  required int cy,
}) {
  final spec = p.spec;
  if (spec.ability == Ability.none || p.abilityDone) return;
  final next = state.turn + 1;
  final status = target.status;
  var slot = -1;
  var moved = 0;
  switch (spec.ability) {
    case Ability.steer:
      status.windReverseTurn = next;
    case Ability.pull:
      final (_, hi) = moveLimits(state.rules, next);
      final want = target.offset + spec.abilityValue * cellUnit;
      final to = want > hi ? hi : want;
      moved = to > target.offset ? to - target.offset : 0;
      target.offset += moved;
      status.moveLockTurn = next;
    case Ability.sealCabin:
      slot = _nearestCabin(target, cx, cy);
      if (slot < 0) return;
      status
        ..sealTurn = next
        ..sealedSlot = slot;
    case Ability.blindTrail:
      status.trailBlockTurn = next;
      // 만타 무작위 피해 (ADR-078).
      randomStrikes(state, target, spec, spec.abilityValue);
    case Ability.grab:
      // 크래비: 가장 가까운 배 위 해적을 물고 바다로 (ADR-078).
      slot = nearestAboard(target, cx, cy);
      if (slot < 0) return;
      target.crew.fall(slot, target.side, state.events);
    case _:
      return;
  }
  p.abilityDone = true;
  state.events.add(
    SimEvent(
      SimEventKind.statusApplied,
      side: target.side,
      slot: slot,
      x: moved,
      value: spec.ability.index,
    ),
  );
}

/// [cx], [cy] 에서 가장 가까운, 쓰러지지 않은 해적의 선실 슬롯(같으면 낮은 슬롯).
int _nearestCabin(SideState target, int cx, int cy) {
  var best = -1;
  var bestD = 0;
  for (var slot = 0; slot < target.crew.size; slot++) {
    if (target.crew.pirates[slot].status == PirateStatus.down) continue;
    final c = target.cabins[slot];
    final d = (c.x - cx) * (c.x - cx) + (c.y - cy) * (c.y - cy);
    if (best < 0 || d < bestD) {
      best = slot;
      bestD = d;
    }
  }
  return best;
}

/// 방향 전환 탭(알바, 설계서 §4.8): [dir] 이 음수면 아래, 아니면 위로 45° 꺾는다.
/// 고유 능력이 [Ability.steer] 이고 아직 쓰지 않은 탄만. 꺾었으면 true.
bool steerOnTap(MatchState state, Projectile p, int dir, int tick) {
  if (p.spec.ability != Ability.steer || p.steered) return false;
  final up = dir < 0 ? -1 : 1;
  final forward = p.vx >= 0 ? 1 : -1;
  final (vx, vy) = rotate(p.vx, p.vy, steerTurnMdeg * up * forward);
  p
    ..vx = vx
    ..vy = vy
    ..steered = true;
  state.events.add(
    SimEvent(SimEventKind.steered, side: p.side, x: p.x, y: p.y, value: tick),
  );
  return true;
}

/// 떠 있는 기뢰(젤리)를 [target] 쪽 바다 [x] 에 놓는다 (설계서 §4.8). 사다리 지속
/// 턴 동안 놓은 쪽 턴 시작마다 1 줄고, 0 이 되면 터지지 않고 사라진다.
void placeFloatMine(MatchState state, Projectile p, SideState target, int x) {
  state.effects.add(
    TurnEffect(
      kind: EffectKind.floatMine,
      owner: p.side,
      ownerSlot: p.slot,
      target: target.side,
      trigger: p.side,
      turnsLeft: p.spec.ammoValue,
      spec: p.spec,
      x: x,
    ),
  );
  state.events.add(
    SimEvent(SimEventKind.mineFloated, side: target.side, x: x),
  );
}

/// [side] 배가 뱃머리 [fromBowX] 에서 지금 자리로 움직였다. 선체 가로 범위가 지나간
/// 떠 있는 기뢰는 놓인 순서대로 터진다: 그 세로줄 흘수선 칸 폭발 + 사다리 침수.
void triggerFloatMines(MatchState state, int side, int fromBowX) {
  final ship = state.sides[side];
  final span = ship.grid.width * cellUnit;
  final f = facingOf(side);
  final a = fromBowX;
  final b = ship.bowX;
  final lo = _min4(a, a - f * span, b, b - f * span);
  final hi = _max4(a, a - f * span, b, b - f * span);
  final hits = [
    for (final e in state.effects)
      if (e.kind == EffectKind.floatMine &&
          e.target == side &&
          e.x >= lo &&
          e.x <= hi)
        e,
  ];
  if (hits.isEmpty) return;
  state.effects.removeWhere(hits.contains);
  for (final e in hits) {
    _blowFloatMine(state, ship, e);
  }
}

void _blowFloatMine(MatchState state, SideState ship, TurnEffect e) {
  final grid = ship.grid;
  final lx = ship.frame.toLocalX(e.x).clamp(0, grid.width * cellUnit - 1);
  final cell = waterlineCellIn(ship, lx ~/ cellUnit);
  state.events.add(
    SimEvent(
      SimEventKind.effectFired,
      side: ship.side,
      slot: e.ownerSlot,
      cell: cell,
      x: e.x,
      value: e.kind.index,
    ),
  );
  if (cell >= 0) {
    final cx = cell % grid.width;
    final cy = cell ~/ grid.width;
    final (x, y) = ship.frame.cellCenter(cx, cy);
    resolveImpact(
      ship,
      spec: e.spec,
      cx: cx,
      cy: cy,
      x: x,
      y: y,
      events: state.events,
      rng: state.rng,
    );
  }
  addFlood(state, ship, e.spec.ammoValue2);
}

/// [cx] 세로줄에서 흘수선에 가장 가까운 블록 칸 인덱스. 없으면 −1.
int waterlineCellIn(SideState ship, int cx) {
  final grid = ship.grid;
  if (cx < 0 || cx >= grid.width) return -1;
  final water = (ship.draft ~/ cellUnit).clamp(0, grid.height - 1);
  for (var d = 0; d < grid.height; d++) {
    for (final cy in [water - d, water + d]) {
      if (cy >= 0 && cy < grid.height && grid.hasBlock(cx, cy)) {
        return grid.indexOf(cx, cy);
      }
    }
  }
  return -1;
}

/// 침수량에 [amount](0.1%p, 음수면 뺀다)를 더한다. 0~100% 로 자른다.
void addFlood(MatchState state, SideState ship, int amount) {
  if (amount == 0) return;
  final before = ship.flood;
  final next = (before + amount).clamp(0, fullFlood);
  if (next == before) return;
  ship.flood = next;
  state.events.add(
    SimEvent(SimEventKind.flood, side: ship.side, value: next - before),
  );
}

int _min4(int a, int b, int c, int d) {
  var m = a;
  for (final v in [b, c, d]) {
    if (v < m) m = v;
  }
  return m;
}

int _max4(int a, int b, int c, int d) {
  var m = a;
  for (final v in [b, c, d]) {
    if (v > m) m = v;
  }
  return m;
}
