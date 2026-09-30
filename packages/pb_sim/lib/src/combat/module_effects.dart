import 'package:pb_sim/src/combat/impact.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/ship/flooding.dart';
import 'package:pb_sim/src/ship/module.dart';
import 'package:pb_sim/src/ship/module_state.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';
import 'package:pb_sim/src/ship/support.dart';

/// 화약고 유폭 (BALANCE.md A3.3): 반경 2칸 안 모든 칸에 블록 80, 해적 120.
const PirateSpec _magazineBlast = PirateSpec(
  id: 'module_magazine',
  rarity: Rarity.common,
  hp: 1,
  cooldownTurns: 0,
  blockDamage: ModuleNumbers.magazineBlockDamage,
  pirateDamage: ModuleNumbers.magazinePirateDamage,
  blastRadius: ModuleNumbers.magazineRadius,
  ammoValue: 100,
);

/// 연료통 폭발: 주변 1칸 블록 40 (해적 피해 없음, ADR-038).
const PirateSpec _fuelTankBlast = PirateSpec(
  id: 'module_fuelTank',
  rarity: Rarity.common,
  hp: 1,
  cooldownTurns: 0,
  blockDamage: ModuleNumbers.fuelTankBlockDamage,
  pirateDamage: 0,
  blastRadius: ModuleNumbers.fuelTankRadius,
  ammoValue: 100,
);

/// 블록이 없어진 모듈을 부서진 것으로 바꾸고 효과를 낸다 (설계서 §3.3).
///
/// 설계도 순서로 본다. 화약고·연료통은 그 자리에서 터지고(다른 모듈을 연쇄로 부술
/// 수 있다), 돛대는 위쪽 블록을 무너뜨린다. 연료통을 잃으면 남은 연료를 줄어든
/// 탱크에 맞춘다. 선장실·포문·망루·펌프·공방은 효과가 사라지기만 한다.
void settleModules(SideState ship, List<SimEvent> events) {
  final grid = ship.grid;
  for (final m in ship.modules.list) {
    if (!m.intact || grid.hasBlock(m.x, m.y)) continue;
    m.intact = false;
    events.add(
      SimEvent(
        SimEventKind.moduleDestroyed,
        side: ship.side,
        cell: grid.indexOf(m.x, m.y),
        value: m.kind.index,
      ),
    );
    switch (m.kind) {
      case ModuleKind.magazine:
        _explode(ship, m, _magazineBlast, events);
      case ModuleKind.fuelTank:
        if (ship.fuel > ship.tank) ship.fuel = ship.tank;
        _explode(ship, m, _fuelTankBlast, events);
      case ModuleKind.mast:
        _breakMast(ship, m, events);
      case ModuleKind.gunPort ||
          ModuleKind.pump ||
          ModuleKind.workshop ||
          ModuleKind.lookout ||
          ModuleKind.captain:
        break;
    }
  }
}

void _explode(
  SideState ship,
  ModuleState m,
  PirateSpec blast,
  List<SimEvent> events,
) {
  final (x, y) = ship.frame.cellCenter(m.x, m.y);
  resolveImpact(
    ship,
    spec: blast,
    cx: m.x,
    cy: m.y,
    x: x,
    y: y,
    events: events,
  );
}

/// 돛대가 부러지면 같은 세로줄 위쪽 블록이 모두 무너진다 (설계서 §3.3).
void _breakMast(SideState ship, ModuleState m, List<SimEvent> events) {
  final grid = ship.grid;
  for (var y = m.y + 1; y < grid.height; y++) {
    if (!grid.hasBlock(m.x, y)) continue;
    final i = grid.indexOf(m.x, y);
    grid.removeAt(i);
    events.add(SimEvent(SimEventKind.blockCollapsed, side: ship.side, cell: i));
  }
  for (final i in collapseUnsupported(grid)) {
    events.add(SimEvent(SimEventKind.blockCollapsed, side: ship.side, cell: i));
  }
}

/// 쐈다: 쿨다운을 건다. 선장실을 잃은 배는 1턴 더 길다 (설계서 §3.3, ADR-038).
void markFiredWithModules(SideState ship, int slot) {
  ship.crew.markFired(slot);
  if (ship.modules.anyLost(ModuleKind.captain)) {
    ship.crew.pirates[slot].cooldown++;
  }
}

/// 턴 끝 침수 증가 → 수리·펌프 (설계서 §2.3 턴 끝 처리 2·3번째).
void endTurnWater(
  SideState ship,
  MatchRules rules,
  int turn,
  List<SimEvent> events,
) {
  final gain = applyFlood(ship, rules, turn);
  if (gain > 0) {
    events.add(SimEvent(SimEventKind.flood, side: ship.side, value: gain));
  }
  runRepairAndPumps(ship, events);
}

/// 턴 끝 수리·펌프 (설계서 §2.3 턴 끝 처리 3번째): 펌프마다 침수량 −4%p, 목수
/// 공방마다 ‘구멍’ 단계 블록 1칸을 최대 내구도로 고친다(아래 줄부터, 같은 줄은
/// 왼쪽부터). 부서진 칸은 고치지 못한다(§2.5).
void runRepairAndPumps(SideState ship, List<SimEvent> events) {
  final pumps = ship.modules.intactCount(ModuleKind.pump);
  if (pumps > 0 && ship.flood > 0) {
    final before = ship.flood;
    final next = before - pumps * ModuleNumbers.pumpFlood;
    ship.flood = next < 0 ? 0 : next;
    events.add(
      SimEvent(SimEventKind.flood, side: ship.side, value: ship.flood - before),
    );
  }
  final grid = ship.grid;
  var left = ship.modules.intactCount(ModuleKind.workshop);
  for (var i = 0; i < grid.cellCount && left > 0; i++) {
    final x = i % grid.width;
    final y = i ~/ grid.width;
    if (!grid.hasBlock(x, y) || grid.stageAt(x, y) != DamageStage.holed) {
      continue;
    }
    grid.repair(x, y, grid.materialAt(x, y)!.durability);
    events.add(SimEvent(SimEventKind.repaired, side: ship.side, cell: i));
    left--;
  }
}
