import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/math/trig.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/world/world.dart';

/// FIRE 힘의 상한(×1000).
const int maxFirePower = 10000;

/// 날아가는 포물선 탄 (설계서 §2.1). 위치는 월드 좌표(1/1000칸), 속도는
/// 1/[velocityScale] 월드 단위/틱(ADR-043).
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
    final speed = power * spec.launchSpeed * velocityScale;
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

  /// 중력을 받는가. 유도탄(날아가는 새)은 받지 않는다 (설계서 §4.1 공중: 유도·선회).
  bool gravity = true;

  /// 남은 수면 튕김 수 (물수제비탄).
  int bouncesLeft = 0;

  /// 수면에서 한 번이라도 튕겼는가 (흘수선 명중 ×1.5, §4.3).
  bool bounced = false;

  /// 남은 관통 칸 수 (관통탄).
  int pierceLeft = 0;

  /// 한 번 쪼개졌는가 (분열탄·다중투하는 한 번만 갈라진다).
  bool divided = false;

  /// 이 틱이 되기 전에는 날지 않는다(연사탄의 뒤 발).
  int startTick = 0;

  /// 한 틱 진행한다: 속도에 바람(가로)과 중력을 더하고 위치를 옮긴다.
  ///
  /// 세로는 틱 앞뒤 속도의 평균으로 옮겨(반 스텝 보정) 사거리가 설계서 §2.8 의
  /// 등급 거리에 맞는다. 중력은 짝수라 정수로 떨어진다.
  void advance(int wind) {
    final g = gravity ? gravityPerTick : 0;
    vx += wind;
    vy -= g;
    final dx = _rx + vx;
    final dy = _ry + vy + g ~/ 2;
    final mx = floorDiv(dx, velocityScale);
    final my = floorDiv(dy, velocityScale);
    x += mx;
    y += my;
    _rx = dx - mx * velocityScale;
    _ry = dy - my * velocityScale;
    age++;
  }

  /// 위치 나머지(속도 단위). 해시에는 넣지 않는다(탄은 판 상태가 아니다).
  int _rx = 0;
  int _ry = 0;

  /// 위치를 ([nx], [ny]) 로 옮기고 나머지를 버린다(수면 튕김).
  void placeAt(int nx, int ny) {
    x = nx;
    y = ny;
    _rx = 0;
    _ry = 0;
  }

  /// 전장 밖으로 나갔거나 수명이 다했다.
  bool get isExpired =>
      age >= projectileMaxTicks || x > worldHalfWidth || x < -worldHalfWidth;
}
