import 'package:pb_sim/src/combat/hit_effects.dart';
import 'package:pb_sim/src/combat/launch.dart';
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

/// 직사 계열이 멀 때 흔들리는 각도의 절반 폭(밀리도). 임시값 (ADR-035).
const int directFarJitterMdeg = 2000;

/// 펠리 투하 폭탄이 떨어지기 시작하는 높이(1/1000칸).
const int flockDropHeight = 14 * cellUnit;

/// 지금 턴 진영의 [slot] 해적이 쏜 한 번의 발사 (설계서 §4.8 탄종 행동 모듈).
///
/// 연사탄은 [PirateSpec.ammoValue] 발을 [burstIntervalTicks] 간격으로 부채꼴로 쏜다.
/// 직사 계열은 가까우면 피해 +20%, 멀면 −20% 에 각도가 흔들린다 (설계서 §2.6).
/// 투사체 id 는 [MatchState.nextProjectileId] 에서 차례로 받는다.
List<Projectile> launchVolley(
  MatchState state, {
  required int slot,
  required int angle,
  required int power,
  required int ms,
}) {
  final spec = state.sides[state.activeSide].crew.pirates[slot].spec;
  final reach = reachOf(state);
  var aim = angle;
  var dmgPercent = 100;
  if (spec.family == Family.direct) {
    if (reach == Reach.near) dmgPercent = 120;
    if (reach == Reach.far) {
      dmgPercent = 80;
      aim +=
          state.rng.nextInt(2 * directFarJitterMdeg + 1) - directFarJitterMdeg;
    }
  }
  final count = spec.ammo == AmmoType.burst ? spec.ammoValue : 1;
  final shotSpec = _scaled(spec, count, dmgPercent);
  final shots = <Projectile>[];
  for (var i = 0; i < count; i++) {
    final p = launchShot(
      state,
      slot: slot,
      angle: aim + _fanOffset(spec.spreadMdeg, i, count),
      power: power,
      ms: ms,
      id: state.nextProjectileId++,
      spec: shotSpec,
    )..startTick = i * burstIntervalTicks;
    _arm(p, reach);
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

/// 부채꼴 [spread](밀리도) 안에서 [count] 발 중 [i] 번째의 각도 차이.
int _fanOffset(int spread, int i, int count) =>
    count <= 1 ? 0 : -spread ~/ 2 + spread * i ~/ (count - 1);

/// 탄종별 비행 상태를 준비한다.
void _arm(Projectile p, Reach reach) {
  final spec = p.spec;
  switch (spec.ammo) {
    case AmmoType.pierce:
      final bonus = switch (reach) {
        Reach.near => 1,
        Reach.far => -1,
        Reach.mid => 0,
      };
      final n = spec.ammoValue + bonus;
      p.pierceLeft = n < 1 ? 1 : n;
    case AmmoType.skip:
      p.bouncesLeft = spec.ammoValue;
    case AmmoType.homing:
      p.gravity = false;
    case _:
      break;
  }
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
/// 폭탄마다 데이터 피해를 그대로 쓴다. 가로 속도를 0.5~1.5 배로 벌려 궤적 따라 흩는다.
List<Projectile> flockBombs(MatchState state, Projectile p, int tick) {
  final n = p.spec.ammoValue;
  return [
    for (var i = 0; i < n; i++)
      _child(
        state,
        p,
        p.spec,
        tick,
        (p.vx * (50 + (n <= 1 ? 50 : 100 * i ~/ (n - 1))) ~/ 100, 0),
      ),
  ];
}

/// 펠리 투하: 표시한 [x] 위 높은 곳에서 1칸 간격으로 폭탄을 떨군다.
List<Projectile> dropBombs(
  MatchState state, {
  required int side,
  required int slot,
  required PirateSpec spec,
  required int x,
}) {
  final n = spec.ammoValue;
  return [
    for (var i = 0; i < n; i++)
      Projectile(
        id: state.nextProjectileId++,
        side: side,
        slot: slot,
        spec: spec,
        x: x + (2 * i - (n - 1)) * cellUnit ~/ 2,
        y: flockDropHeight,
        vx: 0,
        vy: 0,
      )..divided = true,
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
