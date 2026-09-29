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
    required MatchRules rules,
  }) : grid = ShipGrid.fromBlueprint(blueprint),
       cabins = blueprint.cabins,
       crew = Crew(lineup),
       fuel = blueprint.hull.fuelTank * fuelUnit {
    final w = grid.builtWeight * cellUnit ~/ 1000;
    final h = w ~/ (grid.width * rules.waterlineDivisor);
    waterline = h < 0 ? 0 : h;
    sinkAtFullFlood = rules.sinkAtFullFlood;
  }

  /// 연료 1 의 내부 단위. 1/10칸 이동의 연료도 정수로 셈한다.
  static const int fuelUnit = 1000;

  final int side;
  final ShipGrid grid;

  /// 판 시작 흘수선 높이(1/1000칸, 용골 바닥 기준) (설계서 §3.4).
  late final int waterline;

  /// 침수량 100% 일 때 내려앉는 깊이(1/1000칸).
  late final int sinkAtFullFlood;

  /// 시작 위치에서 전진한 거리(1/1000칸, 후퇴면 음수) (설계서 §2.6).
  int offset = 0;

  /// 남은 연료(×[fuelUnit]) (설계서 §2.7).
  int fuel;

  /// 누적 침수량(0.1%p 단위, 0~[fullFlood]) (설계서 §2.5).
  int flood = 0;

  /// 지금 물에 잠긴 깊이: 흘수선 + 내려앉기(1/1000칸).
  int get draft => waterline + flood * sinkAtFullFlood ~/ fullFlood;

  /// 선실 슬롯 순서의 선실 칸. 출전 해적은 앞에서부터 탄다.
  final List<CabinCell> cabins;

  final Crew crew;

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

  bool get isOver => outcome != MatchOutcome.ongoing;

  /// 지금 턴을 두는 진영.
  int get activeSide => turn.isOdd ? firstSide : 1 - firstSide;
}
