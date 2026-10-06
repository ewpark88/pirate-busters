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
    this.stage = maxStage,
    this.level = 1,
  });

  /// 선형 레벨 상한 (설계서 §13.6, BALANCE.md A13.6).
  static const int maxLevel = 50;

  /// 확장 단계 수 (설계서 §3.1, BALANCE.md A3.1 슬루프 확장 단계).
  static const int maxStage = 4;

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

  /// 슬루프 확장 단계 1~3 (설계서 §3.1, BALANCE.md A3.1). 4단계가 [sloop] 이다.
  /// 연료·속도는 단계와 상관없이 슬루프 값이다.
  static const List<HullSpec> sloopStages = [
    HullSpec(
      id: 'sloop',
      width: 6,
      height: 5,
      cabinSlots: 2,
      buildPoints: 20,
      moveSpeed: 2800,
      fuelTank: 80,
      fuelPerCell: 8,
      moduleLimit: 1,
      stage: 1,
    ),
    HullSpec(
      id: 'sloop',
      width: 8,
      height: 6,
      cabinSlots: 3,
      buildPoints: 32,
      moveSpeed: 2800,
      fuelTank: 80,
      fuelPerCell: 8,
      moduleLimit: 2,
      stage: 2,
    ),
    HullSpec(
      id: 'sloop',
      width: 10,
      height: 7,
      cabinSlots: 3,
      buildPoints: 45,
      moveSpeed: 2800,
      fuelTank: 80,
      fuelPerCell: 8,
      moduleLimit: 3,
      stage: 3,
    ),
    sloop,
  ];

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

  /// 확장 단계 1~[maxStage] (설계서 §3.1). 다 자란 선형은 [maxStage].
  final int stage;

  /// 선형 레벨 1~[maxLevel] (설계서 §13.6). 효과는 [atLevel] 이 이미 반영해 둔다.
  final int level;

  /// 블록 최대 내구도 배율(‰): 레벨마다 +1% (BALANCE.md A13.6 선형 업그레이드 보정).
  int get hpPermille => 1000 + 10 * (level - 1);

  /// 레벨 1 선형에 [lv] 레벨 효과를 더한 선형 (BALANCE.md A13.6): 짝수 레벨마다 건조
  /// 포인트 +1(최대 +25), 레벨마다 탱크 +1, Lv15·Lv50 에 기능 모듈 한도 +1.
  HullSpec atLevel(int lv) {
    if (lv < 1 || lv > maxLevel) throw FormatException('알 수 없는 선형 레벨: $lv');
    if (lv == 1) return this;
    final points = lv ~/ 2 > 25 ? 25 : lv ~/ 2;
    return HullSpec(
      id: id,
      width: width,
      height: height,
      cabinSlots: cabinSlots,
      buildPoints: buildPoints + points,
      moveSpeed: moveSpeed,
      fuelTank: fuelTank + (lv - 1),
      fuelPerCell: fuelPerCell,
      moduleLimit: moduleLimit + (lv >= 15 ? 1 : 0) + (lv >= 50 ? 1 : 0),
      framed: framed,
      stage: stage,
      level: lv,
    );
  }

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

  /// id·확장 단계·선형 레벨로 찾는다. 없으면 [FormatException].
  static HullSpec byId(String id, {int stage = maxStage, int level = 1}) {
    if (id == sloop.id) {
      if (stage < 1 || stage > maxStage) {
        throw FormatException('알 수 없는 확장 단계: $stage');
      }
      return sloopStages[stage - 1].atLevel(level);
    }
    for (final h in all) {
      if (h.id == id && h.stage == stage) return h.atLevel(level);
    }
    throw FormatException('알 수 없는 선형: $id');
  }
}
