/// 선형(건조 틀) 정의 (설계서 §3.1). 슬루프 하나다 (ADR-111).
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
  });

  /// 슬루프: 12×8, 선실 4(+ 망대 1), 건조 포인트 60, 2.8칸/초, 탱크 60, 1칸당 연료 10
  /// (BALANCE.md A3.1·A2.6·A2.7).
  static const HullSpec sloop = HullSpec(
    id: 'sloop',
    width: 12,
    height: 8,
    cabinSlots: 4,
    buildPoints: 60,
    moveSpeed: 2800,
    fuelTank: 60,
    fuelPerCell: 10,
  );

  /// 사용할 수 있는 선형.
  static const List<HullSpec> all = [sloop];

  final String id;

  /// 격자 가로 칸 수.
  final int width;

  /// 격자 세로 칸 수. y = 0 이 용골(바닥 줄)이다.
  final int height;

  /// 해적이 타는 선실 수. 망대 1명은 따로다 (설계서 §3.3).
  final int cabinSlots;

  /// 건조 비용 상한.
  final int buildPoints;

  /// 이동 속도, 1/1000칸/초 (연출과 턴 시간에만 영향).
  final int moveSpeed;

  /// 연료 탱크 (설계서 §2.5). 내 턴이 시작될 때 가득 찬다.
  final int fuelTank;

  /// 1칸 움직일 때 쓰는 연료.
  final int fuelPerCell;

  /// 출전 인원: 선실 + 망대 1명 (설계서 §4.5).
  int get crewSlots => cabinSlots + 1;

  /// (x, y) 가 격자 안인가 (설계서 §3.4).
  bool inFrame(int x, int y) => y >= 0 && y < height && x >= 0 && x < width;

  /// id 로 찾는다. 없으면 [FormatException].
  static HullSpec byId(String id) {
    for (final h in all) {
      if (h.id == id) return h;
    }
    throw FormatException('알 수 없는 선형: $id');
  }
}
