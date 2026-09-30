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
  });

  /// 슬루프: 12×8, 선실 4, 건조 포인트 60, 2.8칸/초, 탱크 80, 1칸당 연료 4,
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
    fuelPerCell: 4,
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

  /// id 로 찾는다. 없으면 [FormatException].
  static HullSpec byId(String id) {
    for (final h in all) {
      if (h.id == id) return h;
    }
    throw FormatException('알 수 없는 선형: $id');
  }
}
