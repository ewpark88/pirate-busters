import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/math/trig.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/world/world.dart';

/// FIRE 힘의 상한(×1000).
const int maxFirePower = 10000;

/// 날아가는 포물선 탄 (설계서 §2.1). 위치는 월드 좌표(1/1000칸), 속도는 1/1000칸/틱.
class Projectile {
  Projectile({
    required this.id,
    required this.side,
    required this.slot,
    required this.spec,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });

  /// [side] 진영 [slot] 해적이 ([x], [y]) 에서 쏜다. [angle] 은 상대 쪽 수평이 0 인
  /// 밀리도(위가 양수)라 두 진영이 같은 값으로 같은 궤적을 낸다.
  factory Projectile.launch({
    required int id,
    required int side,
    required int slot,
    required PirateSpec spec,
    required int x,
    required int y,
    required int angle,
    required int power,
  }) {
    const den = maxFirePower * simTickHz * trigScale;
    final speed = power * spec.launchSpeed;
    return Projectile(
      id: id,
      side: side,
      slot: slot,
      spec: spec,
      x: x,
      y: y,
      vx: facingOf(side) * roundDiv(speed * cosMicro(angle), den),
      vy: roundDiv(speed * sinMicro(angle), den),
    );
  }

  /// 발사 순서대로 매기는 번호. 갱신 순서가 된다.
  final int id;

  /// 쏜 진영.
  final int side;

  /// 쏜 선실 슬롯.
  final int slot;

  /// 쏜 해적의 정의 (피해·폭발 반경).
  final PirateSpec spec;

  int x;
  int y;
  int vx;
  int vy;

  /// 날아간 틱 수.
  int age = 0;

  /// 한 틱 진행한다: 속도에 바람(가로)과 중력을 더한 뒤 위치를 옮긴다.
  void advance(int wind) {
    vx += wind;
    vy -= gravityPerTick;
    x += vx;
    y += vy;
    age++;
  }

  /// 전장 밖으로 나갔거나 수명이 다했다.
  bool get isExpired =>
      age >= projectileMaxTicks || x > worldHalfWidth || x < -worldHalfWidth;
}
