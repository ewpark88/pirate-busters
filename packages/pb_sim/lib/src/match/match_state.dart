import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/random/xorshift32.dart';
import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';
import 'package:pb_sim/src/world/world.dart';

/// 판의 진행 상태. 순서(index)는 해시에 들어가므로 새 값은 뒤에 붙인다.
enum MatchOutcome {
  /// 진행 중.
  ongoing,

  /// 한쪽이 항복했다.
  surrender,

  /// 최대 턴 수가 끝났다. 판정(침수량·내구도)은 M3 에서 붙인다.
  turnLimit,

  /// 전멸: 한쪽 해적이 모두 KO 됐다 (설계서 §2.4).
  annihilation,

  /// 격침: 한쪽 선체 내구도가 시작의 20% 미만이 됐다 (설계서 §2.4).
  sunk,
}

/// 한쪽 진영의 상태.
class SideState {
  SideState({
    required this.side,
    required Blueprint blueprint,
    required List<PirateSpec> lineup,
  }) : grid = ShipGrid.fromBlueprint(blueprint),
       cabins = blueprint.cabins,
       crew = Crew(lineup);

  final int side;
  final ShipGrid grid;

  /// 선실 슬롯 순서의 선실 칸. 출전 해적은 앞에서부터 탄다.
  final List<CabinCell> cabins;

  final Crew crew;

  /// 뱃머리 월드 x. 이동은 M3 에서 붙인다.
  int get bowX => startBowX(side);

  /// 이번 판에서 발사한 수.
  int shotsFired = 0;

  /// 현재 위치의 좌표 변환.
  ShipFrame get frame => ShipFrame(side: side, bowX: bowX, width: grid.width);

  /// 로컬 칸 ([cx], [cy]) 이 해적이 탄 선실인데 블록이 없어 해적이 드러나 있는가.
  bool isExposedPirateAt(int cx, int cy) {
    for (var slot = 0; slot < crew.size; slot++) {
      final c = cabins[slot];
      if (c.x != cx || c.y != cy) continue;
      return crew.pirates[slot].status == PirateStatus.aboard &&
          !grid.hasBlock(cx, cy);
    }
    return false;
  }

  /// 바다에 빠진 해적의 월드 위치: 뱃머리 1칸 앞 해수면.
  (int, int) get swimmerPosition => (bowX + facingOf(side) * cellUnit, 0);
}

/// 매치 전체 상태. 렌더와 AI 는 읽기만 한다.
class MatchState {
  MatchState({
    required this.seed,
    required this.rules,
    required this.sides,
  }) : rng = XorShift32(mixSeed(seed)) {
    if (sides.length != 2) {
      throw ArgumentError('진영은 2개여야 한다: ${sides.length}');
    }
    firstSide = rng.nextInt(2);
    wind = rules.windForTurn(seed, 1);
  }

  final int seed;
  final MatchRules rules;

  /// 매치 시드 난수. 시뮬레이션의 모든 난수는 여기서만 뽑는다.
  final XorShift32 rng;

  /// [0] = 왼쪽, [1] = 오른쪽.
  final List<SideState> sides;

  /// 선공 진영 (매치 시드로 정한다).
  late final int firstSide;

  /// 지금 턴 번호(1부터, 양쪽 합산).
  int turn = 1;

  /// 이번 턴 바람 세기(−maxWind ~ +maxWind, +x 쪽이 양수).
  late int wind;

  /// 이번 턴에 쏜 횟수.
  int firesThisTurn = 0;

  /// 이번 턴 탄 비행 연출로 멈춘 시간(밀리초). 턴 제한 시간에서 뺀다.
  int pausedMs = 0;

  /// 다음 투사체 id.
  int nextProjectileId = 0;

  MatchOutcome outcome = MatchOutcome.ongoing;

  /// 이긴 진영. 아직 없거나 무승부면 −1.
  int winner = -1;

  /// 이번 턴에 일어난 렌더용 이벤트. 해시에 넣지 않는다.
  final List<SimEvent> events = [];

  bool get isOver => outcome != MatchOutcome.ongoing;

  /// 지금 턴을 두는 진영.
  int get activeSide => turn.isOdd ? firstSide : 1 - firstSide;
}
