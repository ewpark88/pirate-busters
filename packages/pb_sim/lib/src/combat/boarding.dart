import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';
import 'package:pb_sim/src/world/world.dart';

/// 강습 해적이 적 배 위에 선다 (설계서 §2.3 적 배에 오른 해적, §4.8 적 배 위 강습,
/// ADR-110). 상대는 배를 흔들어 떨어뜨리거나(이동), 근처 해적이 근접 수비로
/// 반격하거나, 그 배에 떨어진 폭발로 맞힌다. 내 탄은 내 배에 닿지 않는다(§2.7).

/// 근접 수비 반경(칸): 선 자리에서 이 안의 배 위 해적이 반격한다 (BALANCE.md A4.8,
/// ADR-113).
const int boardDefenseRadius = 2;

/// 근접 수비 해적 1명당 강습 해적이 받는 피해 (BALANCE.md A4.8, ADR-113).
const int boardDefenseDamage = 30;

/// 흔들기: 배의 이번 턴 이동 합(밀림·끌림 포함)이 이 거리(1/1000칸) 이상이면 선
/// 강습 해적이 바다에 빠진다 (BALANCE.md A4.8, ADR-113).
const int shakeOffDistance = cellUnit;

/// [grid] 세로줄 [cx] 의 맨 위 블록 칸(강습 해적이 그 위에 선다). 없으면 −1.
int deckCellAt(ShipGrid grid, int cx) {
  if (cx < 0 || cx >= grid.width) return -1;
  for (var cy = grid.height - 1; cy >= 0; cy--) {
    if (grid.hasBlock(cx, cy)) return grid.indexOf(cx, cy);
  }
  return -1;
}

/// 밟은 칸 [cell] 의 칸 좌표. 물기·근접 수비·폭발 판정은 이 칸을 기준으로 한다(서
/// 있는 그림은 그 위에 그린다).
(int, int) boardPosOf(ShipGrid grid, int cell) =>
    (cell % grid.width, cell ~/ grid.width);

/// [ship] 배 위에 상대 강습 해적이 서 있는가.
bool hasBoarders(SideState ship) =>
    ship.crew.foe?.pirates.any((p) => p.status == PirateStatus.boarding) ??
    false;

/// 강습 추가 물기인가. 쏜 해적이 적 배 위에 있을 때만 문다.
bool isBoarderBite(TurnEffect e) => e.kind == EffectKind.biteAgain;

/// 강습탄 [p] 가 [target] 배 세로줄 [cx] 에 착지했다: 쏜 해적이 적 배 위에 선다.
void settleBoarder(MatchState state, Projectile p, SideState target, int cx) {
  if (p.spec.ammo != AmmoType.assault || target.side == p.side) return;
  boardShooter(state, p, target, cx);
}

/// [p] 를 쏜 해적을 [target] 배 세로줄 [cx] 맨 위 블록 위에 세운다. 그 줄에 블록이
/// 없으면 바다에 빠진다. 이미 서 있거나 쓰러졌으면 그대로 둔다.
void boardShooter(MatchState state, Projectile p, SideState target, int cx) {
  final crew = state.sides[p.side].crew;
  final pirate = crew.pirates[p.slot];
  if (pirate.status != PirateStatus.aboard) return;
  target.crew.foe = crew;
  final cell = deckCellAt(target.grid, cx);
  if (cell < 0) {
    crew.fall(p.slot, p.side, state.events);
    return;
  }
  pirate
    ..status = PirateStatus.boarding
    ..boardCell = cell;
  state.events.add(
    SimEvent(SimEventKind.boarded, side: p.side, slot: p.slot, cell: cell),
  );
}

/// 턴 시작 (설계서 §2.3·§4.8): 이번 진영의 강습 해적 중 남은 물기가 없는 해적은
/// 원래 선실로 돌아오고, 이번 진영 배에 선 상대 강습 해적은 받침이 없으면 떨어지고
/// 근처 해적의 근접 수비를 받는다. 추가 물기(`runTurnEffects`)보다 먼저 부른다.
void boardingTurnStart(MatchState state) {
  final side = state.activeSide;
  _returnBoarders(state, side);
  // 흔들기 이동 합은 한 턴 단위다: 턴마다 두 배 모두 0 부터 센다.
  for (final s in state.sides) {
    s.status.shakeMoved = 0;
  }
  final ship = state.sides[side];
  dropUnsupportedBoarders(ship, state.events);
  _defend(state, ship);
}

void _returnBoarders(MatchState state, int side) {
  final crew = state.sides[side].crew;
  // 떨어지거나 쓰러져 배 위에 없는 해적의 남은 물기는 지운다.
  state.effects.removeWhere(
    (e) =>
        isBoarderBite(e) &&
        e.owner == side &&
        crew.pirates[e.ownerSlot].status != PirateStatus.boarding,
  );
  for (var slot = 0; slot < crew.size; slot++) {
    final p = crew.pirates[slot];
    if (p.status != PirateStatus.boarding) continue;
    final pending = state.effects.any(
      (e) => isBoarderBite(e) && e.owner == side && e.ownerSlot == slot,
    );
    if (pending) continue;
    p
      ..status = PirateStatus.aboard
      ..boardCell = -1;
    state.events.add(
      SimEvent(SimEventKind.boardReturned, side: side, slot: slot),
    );
  }
}

void _defend(MatchState state, SideState ship) {
  final foe = ship.crew.foe;
  if (foe == null) return;
  final grid = ship.grid;
  for (var slot = 0; slot < foe.size; slot++) {
    final boarder = foe.pirates[slot];
    if (boarder.status != PirateStatus.boarding) continue;
    final (sx, sy) = boardPosOf(grid, boarder.boardCell);
    for (var d = 0; d < ship.crew.size; d++) {
      if (boarder.status != PirateStatus.boarding) break;
      if (ship.crew.pirates[d].status != PirateStatus.aboard) continue;
      final c = ship.cabins[d];
      final dx = c.x - sx;
      final dy = c.y - sy;
      if (dx * dx + dy * dy > boardDefenseRadius * boardDefenseRadius) {
        continue;
      }
      state.events.add(
        SimEvent(
          SimEventKind.boardDefended,
          side: ship.side,
          slot: d,
          value: slot,
        ),
      );
      foe.damage(slot, boardDefenseDamage, 1 - ship.side, state.events);
    }
  }
}

/// [ship] 배에 선 상대 강습 해적 중 밟은 칸 블록이 없어진 해적은 바다에 빠진다.
void dropUnsupportedBoarders(SideState ship, List<SimEvent> events) {
  final foe = ship.crew.foe;
  if (foe == null) return;
  for (var slot = 0; slot < foe.size; slot++) {
    final p = foe.pirates[slot];
    if (p.status != PirateStatus.boarding) continue;
    if (ship.grid.hasBlockAt(p.boardCell)) continue;
    foe.fallFromBoard(slot, 1 - ship.side, events);
  }
}

/// [ship] 배가 뱃머리 [fromBowX] 에서 지금 자리로 움직였다(내 이동, 충격탄·오르카
/// 밀림, 모비 끌림 모두, 설계서 §2.3). 이번 턴 이동 합이 흔들기 거리 이상이면 선 상대
/// 강습 해적이 모두 바다에 빠진다(이동 버튼은 0.1칸씩 낸다).
void shakeOffBoarders(MatchState state, SideState ship, int fromBowX) {
  final status = ship.status..shakeMoved += (ship.bowX - fromBowX).abs();
  final foe = ship.crew.foe;
  if (foe == null || status.shakeMoved < shakeOffDistance) return;
  for (var slot = 0; slot < foe.size; slot++) {
    foe.fallFromBoard(slot, 1 - ship.side, state.events);
  }
}

/// 이 배([target])에 선 상대 강습 해적이 착탄 칸 ([cx], [cy]) 반경 [r] 안이면 맞는다.
/// 착탄한 탄의 주인이 누구든(내 편 탄 포함) 맞는다. 선 자리가 착탄 칸이면 [center],
/// 아니면 [edge] 피해.
void strikeBoarders(
  SideState target,
  int cx,
  int cy,
  int r,
  List<SimEvent> events, {
  required int center,
  required int edge,
}) {
  final foe = target.crew.foe;
  if (foe == null) return;
  for (var slot = 0; slot < foe.size; slot++) {
    final p = foe.pirates[slot];
    if (p.status != PirateStatus.boarding) continue;
    final (sx, sy) = boardPosOf(target.grid, p.boardCell);
    final dx = sx - cx;
    final dy = sy - cy;
    if (dx * dx + dy * dy > r * r) continue;
    final dmg = sx == cx && sy == cy ? center : edge;
    foe.damage(slot, dmg, 1 - target.side, events);
  }
}
