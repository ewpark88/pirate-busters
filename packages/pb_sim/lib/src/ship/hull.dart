/// 선형(건조 틀) 정의 (설계서 §3.1).
class HullSpec {
  const HullSpec({
    required this.id,
    required this.width,
    required this.height,
    required this.cabinSlots,
    required this.buildPoints,
    required this.moveSpeed,
    required this.fuelTank,
    required this.fuelPerCell,
    required this.moduleLimit,
    this.framed = true,
  });

  /// 슬루프: 12×8, 선실 4, 건조 포인트 60, 2.8칸/초, 탱크 80, 1칸당 연료 8,
  /// 기능 모듈 한도 4 (BALANCE.md A3.1·A2.7·A3.3).
  /// MVP 의 유일한 선형 (§11.1).
  static const HullSpec sloop = HullSpec(
    id: 'sloop',
    width: 12,
    height: 8,
    cabinSlots: 4,
    buildPoints: 60,
    moveSpeed: 2800,
    fuelTank: 80,
    fuelPerCell: 8,
    moduleLimit: 4,
  );

  /// 사용할 수 있는 선형. 나머지 선형은 정식 출시 단계에서 추가한다.
  static const List<HullSpec> all = [sloop];

  final String id;

  /// 격자 가로 칸 수.
  final int width;

  /// 격자 세로 칸 수. y = 0 이 용골(바닥 줄)이다.
  final int height;

  /// 해적이 타는 선실 슬롯 수.
  final int cabinSlots;

  /// 건조 비용 상한.
  final int buildPoints;

  /// 최고 이동 속도, 1/1000칸/초 (설계서 §2.6 이동 속도 표).
  final int moveSpeed;

  /// 연료 탱크 상한 (설계서 §2.7). 판 시작 때 가득 차 있다.
  final int fuelTank;

  /// 1칸 움직일 때 쓰는 연료 (설계서 §2.7).
  final int fuelPerCell;

  /// 선장실을 뺀 기능 모듈 수 상한 (설계서 §3.3, BALANCE.md A3.3).
  final int moduleLimit;

  /// 선체 틀(§3.4)을 쓰는가. 게임의 모든 선형은 true 다. false 는 틀과 무관한 규칙을
  /// 직사각형 격자로 확인하는 테스트용이다.
  final bool framed;

  /// 선체 틀(설계서 §3.4, BALANCE.md A3.1): 줄 [y] 의 양쪽 끝에서 쓸 수 없는 칸 수.
  /// 용골 줄은 2칸(폭 6 이하는 1칸), 그 위 줄은 1칸, 나머지는 0 이다. 아래가 좁은
  /// V 자라 어떻게 쌓아도 배 모양이 된다.
  int frameInset(int y) => !framed
      ? 0
      : switch (y) {
          0 => width <= 6 ? 1 : 2,
          1 => 1,
          _ => 0,
        };

  /// (x, y) 가 격자 안이고 선체 틀 안인가.
  bool inFrame(int x, int y) {
    if (y < 0 || y >= height) return false;
    final inset = frameInset(y);
    return x >= inset && x < width - inset;
  }

  /// id 로 찾는다. 없으면 [FormatException].
  static HullSpec byId(String id) {
    for (final h in all) {
      if (h.id == id) return h;
    }
    throw FormatException('알 수 없는 선형: $id');
  }
}
