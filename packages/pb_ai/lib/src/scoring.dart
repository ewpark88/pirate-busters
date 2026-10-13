import 'package:pb_ai/src/dials.dart';
import 'package:pb_sim/pb_sim.dart';

/// 착탄 가치 점수 (BALANCE.md A5.1).
abstract final class Scores {
  static const int kill = 100;
  static const int destroyBlock = 30;
  static const int damageBlock = 10;

  /// 선장실 블록 피해 1당.
  static const int captainPerDamage = 2;

  /// 선장실 파괴.
  static const int captainDestroy = 1000;
  static const int ownShip = -100;

  /// 전설 고유 효과 한 번의 가치 (임시값).
  static const int ability = 30;
}

/// 점수 항목별 합(성격 배율을 곱하기 전).
class ShotValue {
  int block = 0;
  int pirate = 0;
  int captain = 0;
  int flat = 0;

  /// 상대 배를 미는 칸 수(끌어당기면 음수, 충격탄·오르카·모비). 위치 점수가 쓴다.
  int push = 0;

  int total(Personality p) =>
      (block * p.block + pirate * p.pirate + captain * p.captain) ~/ 100 + flat;
}

/// [shooter] 진영이 쏜 탄들의 착탄 [landings] 를 점수로 매긴다. 효과는 내지 않는다.
ShotValue scoreLandings(
  MatchState state,
  int shooter,
  List<ShotLanding> landings,
) {
  final v = ShotValue();
  for (final l in landings) {
    if (!l.hitShip) continue;
    if (l.side == shooter) {
      v.flat += Scores.ownShip;
      continue;
    }
    _impactValue(state.sides[l.side], l, v);
    v
      ..flat += _abilityValue(l.spec)
      ..push = _pushOf(l.spec);
  }
  return v;
}

/// 상대 배 명중 때 거는 전설 고유 효과의 가치.
int _abilityValue(PirateSpec spec) => switch (spec.ability) {
  Ability.none || Ability.torpedo || Ability.drill => 0,
  _ => Scores.ability,
};

/// 명중 한 번에 상대 배를 미는 칸 수 (설계서 §4.8, BALANCE.md A4.2).
int _pushOf(PirateSpec spec) => switch (spec.ability) {
  Ability.shove || Ability.wave => spec.abilityValue,
  Ability.pull => -spec.abilityValue,
  _ => spec.ammo == AmmoType.shock ? spec.ammoValue : 0,
};

/// 착탄 칸 하나의 값: 반경 안 블록·선장실·해적 (설계서 §4.8 폭발 범위, 판정과 같다).
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
      v.block += dmg >= hp ? Scores.destroyBlock : Scores.damageBlock;
      if (_captainAt(target, x, y)) {
        v.captain += (dmg < hp ? dmg : hp) * Scores.captainPerDamage;
        if (dmg >= hp) v.captain += Scores.captainDestroy;
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

bool _captainAt(SideState s, int x, int y) {
  for (final m in s.modules.list) {
    if (m.intact && m.kind == ModuleKind.captain && m.x == x && m.y == y) {
      return true;
    }
  }
  return false;
}
