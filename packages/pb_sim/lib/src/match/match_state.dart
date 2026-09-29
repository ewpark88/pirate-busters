import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/projectile.dart';
import 'package:pb_sim/src/random/xorshift32.dart';
import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';
import 'package:pb_sim/src/ship/ship_motion.dart';
import 'package:pb_sim/src/world/world.dart';

/// 시뮬레이션 고정 틱 속도(Hz). 렌더는 두 틱 사이를 보간한다 (설계서 §7.1).
const int simTickHz = 30;

/// 한 판 길이: 3분 (설계서 §2.4).
const int matchDurationTicks = 180 * simTickHz;

/// 판의 진행 상태. 순서(index)는 해시에 들어가므로 새 값은 뒤에 붙인다.
enum MatchOutcome {
  /// 진행 중.
  ongoing,

  /// 한쪽이 항복했다.
  surrender,

  /// 3분이 끝났다. 판정 점수(선체 내구도 + 생존 해적)는 M3 에서 붙인다.
  timeUp,

  /// 전멸: 한쪽 해적이 모두 쓰러졌다 (설계서 §2.4).
  annihilation,

  /// 파괴: 한쪽 선체 내구도 합계가 0 이 됐다 (설계서 §2.4).
  destruction,
}

/// 한쪽 진영의 상태.
class SideState {
  SideState({
    required this.side,
    required Blueprint blueprint,
    required List<PirateSpec> deck,
  }) : grid = ShipGrid.fromBlueprint(blueprint),
       cabins = blueprint.cabins,
       crew = Crew(deck, blueprint.hull.cabinSlots),
       motion = ShipMotion(side: side, maxSpeed: blueprint.hull.moveSpeed);

  final int side;
  final ShipGrid grid;

  /// 선실 슬롯 순서의 선실 칸.
  final List<CabinCell> cabins;

  final Crew crew;
  final ShipMotion motion;

  /// 이번 판에서 발사한 수.
  int shotsFired = 0;

  /// 현재 위치의 좌표 변환.
  ShipFrame get frame =>
      ShipFrame(side: side, bowX: motion.bowX, width: grid.width);

  /// 로컬 칸 ([cx], [cy]) 이 해적이 탄 선실인데 블록이 없어 해적이 드러나 있는가.
  bool isExposedPirateAt(int cx, int cy) {
    for (var slot = 0; slot < cabins.length; slot++) {
      final c = cabins[slot];
      if (c.x != cx || c.y != cy) continue;
      final p = crew.pirateAt(slot);
      return p != null &&
          p.status == PirateStatus.aboard &&
          !grid.hasBlock(cx, cy);
    }
    return false;
  }

  /// 헤엄치는 해적의 월드 위치: 뱃머리 1칸 앞 해수면.
  (int, int) get swimmerPosition =>
      (motion.bowX + facingOf(side) * cellUnit, 0);
}

/// 매치 전체 상태. 렌더와 AI 는 읽기만 한다.
class MatchState {
  MatchState({required int seed, required this.sides, this.wind = 0})
    : rng = XorShift32(seed) {
    if (sides.length != 2) {
      throw ArgumentError('진영은 2개여야 한다: ${sides.length}');
    }
  }

  /// 매치 시드 난수. 시뮬레이션의 모든 난수는 여기서만 뽑는다.
  final XorShift32 rng;

  /// [0] = 왼쪽, [1] = 오른쪽.
  final List<SideState> sides;

  /// 스테이지 바람: 투사체 가로 가속(1/1000칸/틱², +x 쪽이 양수) (설계서 §2.1).
  final int wind;

  /// 날아가는 투사체. id(발사) 순이다.
  final List<Projectile> projectiles = [];

  /// 다음 투사체 id.
  int nextProjectileId = 0;

  /// 다음에 처리할 틱 번호.
  int tick = 0;

  MatchOutcome outcome = MatchOutcome.ongoing;

  /// 이긴 진영. 아직 없거나 무승부면 -1.
  int winner = -1;

  /// 마지막 틱에 일어난 렌더용 이벤트. 해시에 넣지 않는다.
  final List<SimEvent> events = [];

  bool get isOver => outcome != MatchOutcome.ongoing;
}
