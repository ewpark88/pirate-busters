import 'package:pb_ai/src/dials.dart';
import 'package:pb_sim/pb_sim.dart';

/// 착탄 가치 점수 (BALANCE.md A5.1, 임시값 ADR-040).
abstract final class Scores {
  static const int kill = 100;
  static const int destroyBlock = 30;
  static const int damageBlock = 10;
  static const int flood = 40;
  static const int swimmer = 100;
  static const int ownShip = -100;
  static const int repair = 25;
  static const int repairUnderwater = 40;

  /// 상태 효과·고유 지원 효과 한 번의 가치 (ADR-078, 임시값).
  static const int ability = 30;

  static int module(ModuleKind k) => switch (k) {
    ModuleKind.magazine => 80,
    ModuleKind.captain => 70,
    ModuleKind.mast => 60,
    ModuleKind.pump || ModuleKind.fuelTank => 50,
    _ => 20,
  };
}

/// 점수 항목별 합(성격 배율을 곱하기 전).
class ShotValue {
  int block = 0;
  int pirate = 0;
  int flood = 0;
  int module = 0;
  int flat = 0;

  /// 부서질 칸(콤보 계획용, 상대 배 로컬 인덱스).
  final List<int> destroyed = [];

  int total(Personality p) =>
      (block * p.block +
              pirate * p.pirate +
              flood * p.flood +
              module * p.module) ~/
          100 +
      flat;
}

/// [shooter] 진영이 쏜 탄들의 착탄 [landings] 를 점수로 매긴다. 효과는 내지 않는다.
ShotValue scoreLandings(
  MatchState state,
  int shooter,
  List<ShotLanding> landings,
) {
  final v = ShotValue();
  for (final l in landings) {
    if (l.spec.ammo == AmmoType.support) {
      if (l.side == shooter && l.hitShip) {
        _repairValue(state.sides[shooter], l, v);
        v.flat += _supportValue(state.sides[shooter], l.spec);
      } else if (l.spec.ability == Ability.coral) {
        v.flat += Scores.ability;
      }
      continue;
    }
    if (!l.hitShip) {
      final swim = state.sides[1 - shooter].swimmerPosition.$1;
      if ((swim - l.x).abs() <= cellUnit &&
          _hasSwimmer(state.sides[1 - shooter])) {
        v.flat += Scores.swimmer;
      }
      continue;
    }
    if (l.side == shooter) {
      v.flat += Scores.ownShip;
      continue;
    }
    _impactValue(state.sides[l.side], l, v);
    v.flat += _abilityValue(l.spec);
  }
  return v;
}

/// 고유 지원 효과의 가치: 배수는 침수가 있을 때, 쿨다운 감소는 쉬는 아군 수만큼,
/// 램프·방벽은 한 번 (ADR-078).
int _supportValue(SideState own, PirateSpec spec) => switch (spec.ability) {
  Ability.bail => own.flood > 0 ? Scores.flood * 2 : 0,
  Ability.cooldownCut =>
    own.crew.pirates.where((p) => p.cooldown > 0).length * Scores.ability,
  Ability.lantern || Ability.coral => Scores.ability,
  _ => 0,
};

/// 상대 배 명중 때 거는 상태·고유 효과의 가치 (ADR-075·078).
int _abilityValue(PirateSpec spec) => switch (spec.ability) {
  Ability.steer ||
  Ability.pull ||
  Ability.sealCabin ||
  Ability.blindTrail ||
  Ability.grab ||
  Ability.saw => Scores.ability,
  Ability.wave => Scores.flood * 2,
  _ => 0,
};

bool _hasSwimmer(SideState s) =>
    s.crew.pirates.any((p) => p.status == PirateStatus.swimming);

/// 착탄 칸 하나의 값. 블록 피해는 반경 안 균일 원형으로 어림한다: 실제 판정은 바깥
/// 몫을 균열 조각으로 흩뿌리지만(설계서 §4.8 균열 피해, ADR-052) 기대값은 같고,
/// AI 도 사람처럼 조각이 어디로 갈지 모른다(절대 규칙 4).
void _impactValue(SideState target, ShotLanding l, ShotValue v) {
  final spec = l.spec;
  final grid = target.grid;
  final r = cappedBlastRadius(spec.blastRadius);
  final edge = edgePercentOf(spec);
  final blockAt = spec.blockDamage * (l.bounced ? 150 : 100) ~/ 100;
  for (var y = l.cy - r; y <= l.cy + r; y++) {
    for (var x = l.cx - r; x <= l.cx + r; x++) {
      final dx = x - l.cx;
      final dy = y - l.cy;
      if (dx * dx + dy * dy > r * r || !grid.hasBlock(x, y)) continue;
      final center = dx == 0 && dy == 0;
      final dmg = center ? blockAt : blockAt * edge ~/ 100;
      if (dmg <= 0) continue;
      final hp = grid.hpAt(x, y);
      final max = grid.materialAt(x, y)!.durability;
      final submerged = y * cellUnit < target.draft;
      if (dmg >= hp) {
        v
          ..block += Scores.destroyBlock
          ..destroyed.add(grid.indexOf(x, y));
        for (final m in target.modules.list) {
          if (m.intact && m.x == x && m.y == y) {
            v.module += Scores.module(m.kind);
          }
        }
        if (submerged) v.flood += Scores.flood;
      } else {
        v.block += Scores.damageBlock;
        if (submerged && (hp - dmg) * 3 <= max && hp * 3 > max) {
          v.flood += Scores.flood;
        }
      }
    }
  }
  final crew = target.crew;
  for (var slot = 0; slot < crew.size; slot++) {
    final p = crew.pirates[slot];
    if (p.status != PirateStatus.aboard) continue;
    final c = target.cabins[slot];
    final dx = c.x - l.cx;
    final dy = c.y - l.cy;
    if (dx * dx + dy * dy > r * r) continue;
    final center = dx == 0 && dy == 0;
    var dmg = center ? spec.pirateDamage : spec.pirateDamage * edge ~/ 100;
    if (center && spec.ammo == AmmoType.sniper) {
      dmg = dmg * spec.ammoValue ~/ 100;
    }
    v.pirate += dmg < p.hp ? dmg : p.hp;
    if (dmg >= p.hp) v.pirate += Scores.kill;
  }
}

void _repairValue(SideState own, ShotLanding l, ShotValue v) {
  final grid = own.grid;
  var left = l.spec.ammoParam;
  for (var i = 0; i < grid.cellCount && left > 0; i++) {
    final x = i % grid.width;
    final y = i ~/ grid.width;
    if (!grid.hasBlock(x, y) || grid.stageAt(x, y) != DamageStage.holed) {
      continue;
    }
    v.flat += y * cellUnit < own.draft
        ? Scores.repairUnderwater
        : Scores.repair;
    left--;
  }
}
