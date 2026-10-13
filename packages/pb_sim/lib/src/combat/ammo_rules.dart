import 'package:pb_sim/src/combat/launch.dart';
import 'package:pb_sim/src/combat/legend_effects.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/math/trig.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/world/world.dart';

/// 연사탄 뒤 발 사이 간격(틱). 임시값 (ADR-035).
const int burstIntervalTicks = 3;

/// 산발 연사의 세기 흔들림 절반 폭(‰). 임시값 (BALANCE.md A4.8, ADR-102).
const int scatterPowerPermille = 80;

/// 지금 턴 진영의 [slot] 해적이 쏜 한 번의 발사 (설계서 §4.8 탄종 행동 모듈).
///
/// 연사탄은 [PirateSpec.ammoValue] 발을 [burstIntervalTicks] 간격으로 쏜다. 집중은
/// 모든 발이 같은 각도·세기, 산발은 발마다 매치 난수로 흔들린다 ([_scatter], ADR-102).
/// 망대 해적은 피해가 커진다(설계서 §3.3). 투사체 id 는 [MatchState.nextProjectileId] 에서 차례로 받는다.
List<Projectile> launchVolley(
  MatchState state, {
  required int slot,
  required int angle,
  required int power,
  required int ms,
}) {
  final side = state.sides[state.activeSide];
  final spec = side.crew.pirates[slot].spec;
  final aim = angle;
  final dmgPercent = 100 + side.damageBonusPercent(slot);
  final count = spec.ammo == AmmoType.burst ? spec.ammoValue : 1;
  final shotSpec = _scaled(spec, count, dmgPercent);
  final shots = <Projectile>[];
  final burst = spec.ammo == AmmoType.burst;
  for (var i = 0; i < count; i++) {
    final (a, pw) = burst
        ? _scatter(state, spec, aim, power)
        : (aim + _fanOffset(spec.spreadMdeg, i, count), power);
    final p = launchShot(
      state,
      slot: slot,
      angle: a,
      power: pw,
      ms: ms,
      id: state.nextProjectileId++,
      spec: shotSpec,
    )..startTick = i * burstIntervalTicks;
    armShot(p);
    shots.add(p);
  }
  return shots;
}

/// 여러 발이면 합계 피해를 나누고(§4.8), [percent]% 를 곱한 정의.
PirateSpec _scaled(PirateSpec spec, int count, int percent) {
  var block = spec.blockDamage;
  var pirate = spec.pirateDamage;
  if (count > 1) {
    block = perShotDamage(block, spec.rarity.step, count);
    pirate = perShotDamage(pirate, spec.rarity.step, count);
  }
  if (percent == 100 && count == 1) return spec;
  return spec.withDamage(
    blockDamage: block * percent ~/ 100,
    pirateDamage: pirate * percent ~/ 100,
  );
}

/// 연사 한 발의 각도·세기 (설계서 §4.8 연사 패턴). 집중은 그대로, 산발은 각도
/// ±spread/2·세기 ±[scatterPowerPermille]‰ 를 매치 난수로 흔든다(발 순서대로 뽑는다).
(int, int) _scatter(MatchState state, PirateSpec spec, int aim, int power) {
  if (spec.ammoParam != burstScatter || spec.spreadMdeg <= 0) {
    return (aim, power);
  }
  final half = spec.spreadMdeg ~/ 2;
  final angle = aim + state.rng.nextInt(2 * half + 1) - half;
  final permille =
      1000 +
      state.rng.nextInt(2 * scatterPowerPermille + 1) -
      scatterPowerPermille;
  return (angle, power * permille ~/ 1000);
}

/// 부채꼴 [spread](밀리도) 안에서 [count] 발 중 [i] 번째의 각도 차이.
int _fanOffset(int spread, int i, int count) =>
    count <= 1 ? 0 : -spread ~/ 2 + spread * i ~/ (count - 1);

/// 탄종별 비행 상태를 준비한다. 궤적 미리보기도 같은 준비를 거친다 (A33).
void armShot(Projectile p) {
  final spec = p.spec;
  switch (spec.ammo) {
    case AmmoType.pierce:
      p.pierceLeft = spec.ammoValue < 1 ? 1 : spec.ammoValue;
    case AmmoType.skip:
      p.bouncesLeft = spec.ammoValue < 1 ? 1 : spec.ammoValue;
    case AmmoType.homing:
      p.gravity = false;
    case _:
      break;
  }
  armLegend(p);
}

/// 속도 ([vx], [vy]) 를 [mdeg] 만큼 반시계로 돌린다.
(int, int) rotate(int vx, int vy, int mdeg) {
  final c = cosMicro(mdeg);
  final s = sinMicro(mdeg);
  return (
    roundDiv(vx * c - vy * s, trigScale),
    roundDiv(vx * s + vy * c, trigScale),
  );
}

/// 분열탄: 지금 자리에서 [PirateSpec.ammoValue] 조각으로 부채꼴로 갈라진다.
/// 조각 피해는 합계를 나눈 값 (설계서 §4.8).
List<Projectile> splitFragments(MatchState state, Projectile p, int tick) {
  final spec = p.spec;
  final n = spec.ammoValue;
  final fragSpec = _scaled(spec, n, 100);
  return [
    for (var i = 0; i < n; i++)
      _child(
        state,
        p,
        fragSpec,
        tick,
        rotate(p.vx, p.vy, _fanOffset(spec.spreadMdeg, i, n)),
      ),
  ];
}

/// 다중투하: 꼭대기에서 [PirateSpec.ammoValue] 개의 소형 폭탄으로 갈라진다.
/// 폭탄 피해는 여러 발 규칙으로 합계를 나눈 값 (§4.8, ADR-050). 가로 속도를 0.5~1.5
/// 배로 벌려 궤적 따라 흩는다.
List<Projectile> flockBombs(MatchState state, Projectile p, int tick) {
  final n = p.spec.ammoValue;
  final bomb = _scaled(p.spec, n, 100);
  return [
    for (var i = 0; i < n; i++)
      _child(
        state,
        p,
        bomb,
        tick,
        (p.vx * (50 + (n <= 1 ? 50 : 100 * i ~/ (n - 1))) ~/ 100, 0),
      ),
  ];
}

Projectile _child(
  MatchState state,
  Projectile p,
  PirateSpec spec,
  int tick,
  (int, int) v,
) =>
    Projectile(
        id: state.nextProjectileId++,
        side: p.side,
        slot: p.slot,
        spec: spec,
        x: p.x,
        y: p.y,
        vx: v.$1,
        vy: v.$2,
      )
      ..divided = true
      ..startTick = tick;

/// 유도탄: 가장 가까운 배 위 상대 해적 쪽으로 틱마다 [PirateSpec.ammoValue] °/초
/// 만큼 돈다 (설계서 §4.2 폴리). 없으면 곧게 난다.
void steerHoming(MatchState state, Projectile p, int atMs) {
  final target = state.sides[1 - p.side];
  var best = -1;
  var bx = 0;
  var by = 0;
  for (var slot = 0; slot < target.crew.size; slot++) {
    if (target.crew.pirates[slot].status != PirateStatus.aboard) continue;
    final c = target.cabins[slot];
    final (x, y) = fromShipLocal(
      state,
      target.side,
      atMs,
      c.x * cellUnit + cellUnit ~/ 2,
      c.y * cellUnit + cellUnit ~/ 2,
    );
    final d = (x - p.x).abs() + (y - p.y).abs();
    if (best < 0 || d < best) {
      best = d;
      bx = x;
      by = y;
    }
  }
  if (best < 0) return;
  final cross = p.vx * (by - p.y) - p.vy * (bx - p.x);
  if (cross == 0) return;
  final turn = p.spec.ammoValue * mdegPerDegree ~/ simTickHz;
  final (vx, vy) = rotate(p.vx, p.vy, cross > 0 ? turn : -turn);
  p
    ..vx = vx
    ..vy = vy;
}
