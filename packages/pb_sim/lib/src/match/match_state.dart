import 'package:pb_sim/src/match/barrier.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/match/side_status.dart';
import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/match/turn_effects.dart';
import 'package:pb_sim/src/pirate/crew.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/projectile/shot_trace.dart';
import 'package:pb_sim/src/random/xorshift32.dart';
import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/module.dart';
import 'package:pb_sim/src/ship/module_state.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';
import 'package:pb_sim/src/ship/ship_stats.dart';
import 'package:pb_sim/src/world/world.dart';

/// 판의 진행 상태. 순서(index)는 해시에 들어가므로 새 값은 뒤에 붙인다.
enum MatchOutcome {
  /// 진행 중.
  ongoing,

  /// 한쪽이 항복했다.
  surrender,

  /// 시간 판정: 30턴이 끝나 침수량·선체 내구도로 가렸다 (설계서 §2.4). 무승부면
  /// [MatchState.winner] 가 −1.
  timeDecision,

  /// 전멸: 한쪽 해적이 모두 KO 됐다 (설계서 §2.4).
  annihilation,

  /// 격침: 한쪽 선체 내구도가 시작의 20% 미만이 됐다 (설계서 §2.4).
  sunk,

  /// 격침: 한쪽 침수량이 100% 가 됐다 (설계서 §2.4).
  floodSunk,
}

/// 침수량 100% (0.1%p 단위).
const int fullFlood = 1000;

/// 한쪽 진영의 상태.
class SideState {
  SideState({
    required this.side,
    required Blueprint blueprint,
    required List<PirateSpec> lineup,
    required this.rules,
  }) : grid = ShipGrid.fromBlueprint(blueprint),
       cabins = List.of(blueprint.cabins),
       crew = Crew(lineup),
       modules = ShipModules(blueprint),
       fuel = _startTank(blueprint),
       waterline = waterlineOf(blueprint, rules);

  static int _startTank(Blueprint blueprint) {
    var tanks = 0;
    for (final m in blueprint.modules) {
      if (m.kind == ModuleKind.fuelTank) tanks++;
    }
    return (blueprint.hull.fuelTank + tanks * ModuleNumbers.fuelTankBonus) *
        fuelUnit;
  }

  /// 연료 1 의 내부 단위. 1/10칸 이동의 연료도 정수로 셈한다.
  static const int fuelUnit = 1000;

  /// 설계도의 흘수선 높이(1/1000칸, 용골 바닥 기준): (총무게 − 부력재) ÷ (선형 폭 ×
  /// [MatchRules.waterlineDivisor]) (설계서 §3.4). 무게는 ×1000 이라 그대로 1/1000칸이다.
  static int waterlineOf(Blueprint blueprint, MatchRules rules) =>
      waterlineOfWeight(
        blueprint.hull,
        shipWeight(blueprint.cells, blueprint.modules),
        rules,
      );

  final int side;
  final ShipGrid grid;

  /// 판 규칙 (내려앉기 수치).
  final MatchRules rules;

  /// 판 시작 흘수선 높이(1/1000칸, 용골 바닥 기준) (설계서 §3.4).
  final int waterline;

  /// 시작 위치에서 전진한 거리(1/1000칸, 후퇴면 음수) (설계서 §2.6).
  int offset = 0;

  /// 남은 연료(×[fuelUnit]) (설계서 §2.7).
  int fuel;

  /// 누적 침수량(0.1%p 단위, 0~[fullFlood]) (설계서 §2.5).
  int flood = 0;

  /// 지금 물에 잠긴 깊이: 흘수선 + 내려앉기(1/1000칸).
  int get draft => waterline + flood * rules.sinkAtFullFlood ~/ fullFlood;

  /// [slot] 선실이 흘수선 아래에 잠겼는가: 선실 칸 중심이 잠긴 깊이보다 낮다.
  /// 잠긴 선실의 해적은 쏠 수 없다 (ADR-027).
  bool isCabinFlooded(int slot) =>
      cabins[slot].y * cellUnit + cellUnit ~/ 2 <= draft;

  /// [slot] 해적이 지금 쏠 수 있는가: 쿨다운·상태(배 위) + 선실이 물 위 + 봉쇄 안 됨.
  bool canFire(int slot) =>
      crew.canFire(slot) && !isCabinFlooded(slot) && !isSealed(slot);

  /// 지속 상태 (설계서 §4.8 고유 효과 공통 규칙, ADR-075).
  final SideStatus status = SideStatus();

  /// 지금 판의 턴 번호. 지속 상태가 이번 턴에 걸렸는지 보는 데만 쓴다
  /// ([MatchState.turn] 과 같게 맞춘다, 해시 밖).
  int turnNow = 1;

  /// [slot] 선실이 이번 턴에 봉쇄됐다(킹).
  bool isSealed(int slot) =>
      status.sealTurn == turnNow && status.sealedSlot == slot;

  /// 이번 턴에 이동할 수 없다(모비).
  bool get moveLocked => status.moveLockTurn == turnNow;

  /// 이번 턴 궤적 표시 비율(%)을 바꾸는 상태가 있으면 그 값, 없으면 −1 (만타·램프).
  /// 판정과 AI 에는 쓰지 않는다.
  int get trailOverride => status.trailPercentAt(turnNow);

  /// 칸마다 남은 불 지속 턴(0 = 불 없음, 설계서 §2.5). 칸 인덱스 순서.
  late final List<int> fireTurns = List.filled(grid.cellCount, 0);

  /// 칸마다 나무 추가 피해(%) (화염탄 사다리, BALANCE.md A2.5).
  late final List<int> fireExtra = List.filled(grid.cellCount, 0);

  /// 선실 슬롯 순서의 선실 칸. 출전 해적은 앞에서부터 탄다. 돛대가 부러진 돛 자리는
  /// 돛대 밑동 위 칸으로 옮긴다([moveFallenSeats]).
  final List<CabinCell> cabins;

  /// 돛대가 부러진 돛 자리 선실을 돛대 밑동 바로 위 칸(드러난 갑판)으로 옮긴다
  /// (설계서 §3.3 돛 자리). 바다에 빠진 해적이 돌아오기 전, 내 턴 시작에 부른다.
  void moveFallenSeats() {
    for (final m in modules.list) {
      if (!m.kind.isMast || m.intact) continue;
      final rig = m.cell.rigCells(grid.height);
      if (rig.isEmpty) continue;
      final (sx, sy) = rig.last;
      for (var slot = 0; slot < cabins.length; slot++) {
        if (cabins[slot].x == sx && cabins[slot].y == sy) {
          cabins[slot] = CabinCell(m.x, m.y + 1);
        }
      }
    }
  }

  final Crew crew;

  /// 기능 모듈 (설계서 §3.3).
  final ShipModules modules;

  /// 연료 탱크 상한(×[fuelUnit]): 선형 탱크 + 남은 연료통 × 40 (설계서 §2.7).
  int get tank =>
      (grid.hull.fuelTank +
          modules.intactCount(ModuleKind.fuelTank) *
              ModuleNumbers.fuelTankBonus) *
      fuelUnit;

  /// 돛대가 부러졌다: 1칸당 연료 증가, 속도 절반 (BALANCE.md A2.6·A3.3).
  bool get mastBroken => modules.anyMastLost;

  /// 1칸당 연료(×[fuelUnit]): 선형 소모 × 무게 배율 × 돛대 (설계서 §2.7).
  int get fuelPerCell {
    final base = grid.hull.fuelPerCell * fuelUnit * modules.weightPermille;
    return base ~/ 1000 * modules.brokenMastFuelPermille ~/ 1000;
  }

  /// [slot] 해적의 모듈 피해 보너스(%): 그 선실 포문 +10, 화약고가 남아 있으면 +10.
  int damageBonusPercent(int slot) {
    final c = cabins[slot];
    var bonus = 0;
    if (modules.hasAt(c.x, c.y, ModuleKind.gunPort)) {
      bonus += ModuleNumbers.gunPortPercent;
    }
    if (modules.intactCount(ModuleKind.magazine) > 0) {
      bonus += ModuleNumbers.magazinePercent;
    }
    // 돛 자리: 돛대가 서 있는 동안 종류별 보너스 (설계서 §3.3, BALANCE.md A3.2).
    final seat = modules.mastWithSeat(c.x, c.y, grid.height);
    if (seat != null) bonus += seat.kind.seatPercent;
    return bonus;
  }

  /// [slot] 선실에 망루가 있다: 궤적 표시 50% (설계서 §3.3).
  bool hasLookout(int slot) {
    final c = cabins[slot];
    return modules.hasAt(c.x, c.y, ModuleKind.lookout);
  }

  /// 뱃머리 월드 x.
  int get bowX => startBowX(side) + facingOf(side) * offset;

  /// 이번 판에서 발사한 수.
  int shotsFired = 0;

  /// 현재 위치의 좌표 변환(파도 없음).
  ShipFrame get frame => frameAt(0);

  /// 파도 위아래 흔들림 [heave] 를 더한 좌표 변환.
  ShipFrame frameAt(int heave) => ShipFrame(
    side: side,
    bowX: bowX,
    width: grid.width,
    baseY: heave - draft,
  );

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

  /// 이번 턴에 이동이 끝나는 턴 시각(밀리초, 비행 정지 제외). 이동 중에 들어온
  /// 커맨드는 이 시각에 처리한다 (ADR-025).
  int busyUntilMs = 0;

  /// 다음 투사체 id.
  int nextProjectileId = 0;

  MatchOutcome outcome = MatchOutcome.ongoing;

  /// 이긴 진영. 아직 없거나 무승부면 −1.
  int winner = -1;

  /// 이번 턴에 일어난 렌더용 이벤트. 해시에 넣지 않는다.
  final List<SimEvent> events = [];

  /// 턴 시작에 터지도록 예약한 효과 (설계서 §4.3 턴 효과). 예약 순서대로 처리한다.
  final List<TurnEffect> effects = [];

  /// 서 있는 산호 방벽(코리, ADR-078). 세운 순서대로 둔다.
  final List<Barrier> barriers = [];

  /// 마지막 발사(또는 턴 효과)에서 난 탄들의 틱별 위치. 렌더용이라 해시에 넣지 않는다.
  List<ShotTrace> lastTraces = const [];

  bool get isOver => outcome != MatchOutcome.ongoing;

  /// 지금 턴을 두는 진영.
  int get activeSide => turn.isOdd ? firstSide : 1 - firstSide;

  /// 진영들의 [SideState.turnNow] 를 지금 턴에 맞춘다.
  void syncTurn() {
    for (final s in sides) {
      s.turnNow = turn;
    }
  }
}
