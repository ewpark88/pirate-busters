import 'package:pb_sim/src/random/xorshift32.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';

/// 시뮬레이션 고정 틱 속도(Hz). 렌더는 두 틱 사이를 보간한다 (설계서 §7.1).
const int simTickHz = 30;

/// 한 판 길이: 3분 (설계서 §2.4).
const int matchDurationTicks = 180 * simTickHz;

/// 판의 진행 상태.
enum MatchOutcome {
  /// 진행 중.
  ongoing,

  /// 한쪽이 항복했다.
  surrender,

  /// 3분이 끝났다. 판정 점수(선체 내구도 + 생존 해적)는 M3 이후에 붙인다.
  timeUp,
}

/// 발사 기록. M2 에서 탄도 투사체로 바뀐다.
class FiredShot {
  const FiredShot({
    required this.tick,
    required this.slot,
    required this.angle,
    required this.power,
  });

  final int tick;
  final int slot;
  final int angle;
  final int power;
}

/// 한쪽 진영의 상태.
class SideState {
  SideState(this.grid, List<String> deck)
    : deck = List.unmodifiable(deck),
      reloadTicks = List<int>.filled(grid.hull.cabinSlots, 0);

  final ShipGrid grid;

  /// 덱의 해적 id. 앞에서부터 선실 슬롯 수만큼 선실에 탄다 (설계서 §3.1).
  final List<String> deck;

  /// 선실 슬롯별 남은 재장전 틱. 0 이면 발사할 수 있다.
  final List<int> reloadTicks;

  /// 이번 판에서 발사한 기록(발사 순서).
  final List<FiredShot> shots = [];

  /// [slot] 에 해적이 타고 있는가.
  bool isSlotOccupied(int slot) =>
      slot >= 0 && slot < reloadTicks.length && slot < deck.length;
}

/// 매치 전체 상태. 렌더와 AI 는 읽기만 한다.
class MatchState {
  MatchState({required int seed, required this.sides})
    : rng = XorShift32(seed) {
    if (sides.length != 2) {
      throw ArgumentError('진영은 2개여야 한다: ${sides.length}');
    }
  }

  /// 매치 시드 난수. 시뮬레이션의 모든 난수는 여기서만 뽑는다.
  final XorShift32 rng;

  /// [0] = 왼쪽, [1] = 오른쪽.
  final List<SideState> sides;

  /// 다음에 처리할 틱 번호.
  int tick = 0;

  MatchOutcome outcome = MatchOutcome.ongoing;

  /// 이긴 진영. 아직 없거나 무승부면 -1.
  int winner = -1;

  bool get isOver => outcome != MatchOutcome.ongoing;
}
