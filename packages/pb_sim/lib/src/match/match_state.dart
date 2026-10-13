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
import 'package:pb_sim/src/world/world.dart';

/// 판의 진행 상태. 순서(index)는 해시에 들어가므로 새 값은 뒤에 붙인다.
enum MatchOutcome {
  /// 진행 중.
  ongoing,

  /// 한쪽이 항복했다.
  surrender,

  /// 턴 제한: 24턴이 끝나 남은 해적 체력 비율·선장실 내구도로 가렸다 (설계서 §2.7).
  /// 무승부면 [MatchState.winner] 가 −1.
  timeDecision,

  /// 전멸: 한쪽 해적이 모두 KO 됐다 (설계서 §2.7).
  annihilation,

  /// 선장실 파괴: 한쪽 선장실 블록이 부서졌다 (설계서 §2.7).
  captainLost,
}

/// 배가 물에 잠긴 깊이(1/1000칸, 용골 바닥 기준). 흘수선 규칙은 없고 모든 배가 같다
/// (ADR-111). 물수제비·수중 탄이 닿는 선체 아래쪽이 이만큼 물에 잠긴다.
const int shipDraft = 600;

/// 한쪽 진영의 상태.
class SideState {
  SideState({
    required this.side,
    required Blueprint blueprint,
    required List<PirateSpec> lineup,
    required this.rules,
  }) : grid = ShipGrid.fromBlueprint(blueprint),
       // 선실 다음 자리가 망대다 (설계서 §3.3).
       cabins = [
         ...blueprint.cabins,
         for (final (x, y) in mastSeats(blueprint.hull, blueprint.modules))
           CabinCell(x, y),
       ],
       crew = Crew(lineup),
       modules = ShipModules(blueprint),
       fuel = blueprint.hull.fuelTank * fuelUnit;

  /// 연료 1 의 내부 단위. 1/10칸 이동의 연료도 정수로 셈한다.
  static const int fuelUnit = 1000;

  final int side;
  final ShipGrid grid;

  /// 판 규칙.
  final MatchRules rules;

  /// 시작 위치에서 전진한 거리(1/1000칸, 후퇴면 음수) (설계서 §2.5).
  int offset = 0;

  /// 남은 연료(×[fuelUnit]) (설계서 §2.5). 내 턴이 시작될 때 가득 찬다.
  int fuel;

  /// 물에 잠긴 깊이(1/1000칸).
  int get draft => shipDraft;

  /// [slot] 해적이 지금 쏠 수 있는가: 배 위에 있고 이번 턴에 아직 안 쐈다.
  bool canFire(int slot) => crew.canFire(slot);

  /// 지속 상태 (설계서 §4.8).
  final SideStatus status = SideStatus();

  /// 지금 판의 턴 번호. 지속 상태가 이번 턴에 걸렸는지 보는 데만 쓴다
  /// ([MatchState.turn] 과 같게 맞춘다, 해시 밖).
  int turnNow = 1;

  /// 이번 턴 궤적 표시 비율(%)을 바꾸는 상태가 있으면 그 값, 없으면 −1 (만타).
  /// 판정과 AI 에는 쓰지 않는다.
  int get trailOverride => status.trailPercentAt(turnNow);

  /// 선실 순서의 칸, 끝에 망대(돛대 꼭대기). 출전 해적은 앞에서부터 탄다.
  final List<CabinCell> cabins;

  final Crew crew;

  /// 모듈: 선장실·돛대 (설계서 §3.3).
  final ShipModules modules;

  /// 연료 탱크(×[fuelUnit]).
  int get tank => grid.hull.fuelTank * fuelUnit;

  /// 1칸당 연료(×[fuelUnit]).
  int get fuelPerCell => grid.hull.fuelPerCell * fuelUnit;

  /// [slot] 해적이 망대(돛대 꼭대기)에 타 있고 돛대가 서 있다 (설계서 §3.3).
  bool isOnCrowsNest(int slot) {
    final c = cabins[slot];
    return modules.mastWithSeat(c.x, c.y, grid.height) != null;
  }

  /// [slot] 해적의 피해 보너스(%): 망대면 +30 (BALANCE.md A3.3).
  int damageBonusPercent(int slot) =>
      isOnCrowsNest(slot) ? ModuleKind.mast.seatPercent : 0;

  /// 선장실이 아직 서 있다 (설계서 §2.7).
  bool get captainStanding => modules.intactCount(ModuleKind.captain) > 0;

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
  /// 망대는 늘 드러나 있다.
  bool isExposedPirateAt(int cx, int cy) {
    for (var slot = 0; slot < crew.size; slot++) {
      final c = cabins[slot];
      if (c.x != cx || c.y != cy) continue;
      return crew.pirates[slot].status == PirateStatus.aboard &&
          !grid.hasBlock(cx, cy);
    }
    return false;
  }
}

/// 매치 전체 상태. 렌더와 AI 는 읽기만 한다.
class MatchState {
  MatchState({
    required this.seed,
    required this.rules,
    required this.sides,
  }) : rng = XorShift32(mixSeed(seed)),
       waveZones = rules.waveZonesFor(seed) {
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

  /// 파도 구간 세기: 가운데에서 바깥쪽으로 (설계서 §2.6, `MatchRules.waveZonesFor`).
  final List<int> waveZones;

  /// [0] = 왼쪽, [1] = 오른쪽.
  final List<SideState> sides;

  /// 선공 진영 (매치 시드로 정한다).
  late final int firstSide;

  /// 지금 턴 번호(1부터, 양쪽 합산).
  int turn = 1;

  /// 이번 턴 바람 세기(−maxWind ~ +maxWind, +x 쪽이 양수).
  late int wind;

  /// 이번 턴에 쏜 횟수(0 또는 1, 설계서 §2.3).
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

  /// 턴 시작에 터지도록 예약한 효과 (설계서 §4.8 설치탄 등). 예약 순서대로 처리한다.
  final List<TurnEffect> effects = [];

  /// 마지막 발사(또는 턴 효과)에서 난 탄들의 틱별 위치. 렌더용이라 해시에 넣지 않는다.
  List<ShotTrace> lastTraces = const [];

  bool get isOver => outcome != MatchOutcome.ongoing;

  /// 지금 턴을 두는 진영.
  int get activeSide => turn.isOdd ? firstSide : 1 - firstSide;

  /// 상대 진영 상태.
  SideState otherOf(int side) => sides[1 - side];

  /// 진영들의 [SideState.turnNow] 를 지금 턴에 맞춘다.
  void syncTurn() {
    for (final s in sides) {
      s.turnNow = turn;
    }
  }
}
