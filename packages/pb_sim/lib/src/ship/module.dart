import 'package:pb_sim/src/json_read.dart';
import 'package:pb_sim/src/ship/hull.dart';
import 'package:pb_sim/src/ship/material.dart';

/// 기능 모듈 (설계서 §3.3). 선실은 `CabinCell` 로 따로 둔다. 순서는 해시에 들어가므로
/// 새 값은 뒤에 붙인다. 비용은 BALANCE.md A3.3 (임시값, ADR-038).
enum ModuleKind {
  /// 포문: 올린 선실 해적의 피해 +10% (선실 옵션).
  gunPort('gunPort', cost: 2, cabinOption: true),

  /// 화약고: 모든 해적 피해 +10%, 부서지면 유폭.
  magazine('magazine', cost: 3),

  /// 펌프: 턴 끝 침수량 −4%p.
  pump('pump', cost: 3),

  /// 목수 공방: 턴 끝 ‘구멍’ 단계 블록 1칸 복구.
  workshop('workshop', cost: 3),

  /// 소나무 돛대(기본형): 위로 돛대 칸을 세운다. 부러지면 위가 무너지고 연료 2배·
  /// 속도 절반. 꼭대기 칸은 돛 자리 (설계서 §3.3, BALANCE.md A3.2).
  mast(
    'mast',
    cost: 2,
    rig: BlockMaterial.rigPine,
    rigHeight: 3,
    seatPercent: 20,
  ),

  /// 망루: 궤적 표시 50% (선실 옵션).
  lookout('lookout', cost: 2, cabinOption: true),

  /// 선장실: 필수 1개. 부서지면 모든 해적 쿨다운 +1턴.
  captain('captain', cost: 0),

  /// 연료통: 탱크 +40, 부서지면 탱크 −40 과 주변 1칸 피해.
  fuelTank('fuelTank', cost: 2),

  /// 대나무 돛대: 낮고 싸다. 부러져도 연료 1.5배.
  mastBamboo(
    'mastBamboo',
    cost: 1,
    rig: BlockMaterial.rigBamboo,
    rigHeight: 2,
    seatPercent: 15,
    brokenFuelPermille: 1500,
  ),

  /// 참나무 돛대: 기준 피해 한 발을 버틴다.
  mastOak(
    'mastOak',
    cost: 3,
    rig: BlockMaterial.rigOak,
    rigHeight: 3,
    seatPercent: 20,
    weight: 500,
  ),

  /// 철 돛대: 불 면역, 무거워 흘수선이 내려간다.
  mastIron(
    'mastIron',
    cost: 4,
    rig: BlockMaterial.rigIron,
    rigHeight: 3,
    seatPercent: 20,
    weight: 1000,
  ),

  /// 망대 돛대: 가장 높고 돛 자리 피해가 크다.
  mastCrow(
    'mastCrow',
    cost: 3,
    rig: BlockMaterial.rigCrow,
    rigHeight: 4,
    seatPercent: 30,
    weight: 500,
  );

  const ModuleKind(
    this.jsonName, {
    required this.cost,
    this.cabinOption = false,
    this.rig,
    this.rigHeight = 0,
    this.seatPercent = 0,
    this.brokenFuelPermille = 2000,
    this.weight = 0,
  });

  /// 데이터 이름.
  final String jsonName;

  /// 건조 포인트.
  final int cost;

  /// 선실 칸에만 겹쳐 다는 선실 옵션인가 (포문·망루).
  final bool cabinOption;

  /// 돛대면 돛대 칸 재질, 아니면 null (설계서 §3.3, BALANCE.md A3.2).
  final BlockMaterial? rig;

  /// 돛대 칸 수(격자 위끝에서 잘린다).
  final int rigHeight;

  /// 돛 자리 해적 피해 보너스(%).
  final int seatPercent;

  /// 부러졌을 때 1칸당 연료 배율(‰).
  final int brokenFuelPermille;

  /// 흘수선 무게 ×1000 (돛대 한 개 전체).
  final int weight;

  bool get isMast => rig != null;

  /// 기능 모듈 한도에 세는가: 선장실과 선실 옵션(포문·망루)은 빠진다 (설계서 §3.3).
  bool get countsToLimit => this != captain && !cabinOption;

  /// 데이터 이름으로 찾는다. 없으면 [FormatException].
  static ModuleKind byName(String name) {
    for (final k in values) {
      if (k.jsonName == name) return k;
    }
    throw FormatException('알 수 없는 모듈: $name');
  }
}

/// 설계도의 모듈 한 칸. 블록이 있는 칸 위에 붙인다. 돛대는 [level](1~5)을 갖는다.
class ModuleCell {
  const ModuleCell(this.x, this.y, this.kind, {this.level = 1});

  /// `[x, y, 종류]`, 돛대 레벨이 2 이상이면 `[x, y, 종류, 레벨]`.
  factory ModuleCell.fromJson(Object? raw) {
    if (raw is! List<Object?> || raw.length < 3 || raw.length > 4) {
      throw FormatException('모듈은 [x, y, 종류(, 레벨)] 여야 한다: $raw');
    }
    return ModuleCell(
      asInt(raw[0], 'x'),
      asInt(raw[1], 'y'),
      ModuleKind.byName(asString(raw[2], '모듈')),
      level: raw.length == 4 ? asInt(raw[3], '레벨') : 1,
    );
  }

  final int x;
  final int y;
  final ModuleKind kind;

  /// 돛대 레벨 (설계서 §3.3 돛대 업그레이드). 돛대가 아니면 1.
  final int level;

  /// 돛대 칸 (x, y+1) … 위로 [ModuleKind.rigHeight] 칸, 격자 높이 [height] 에서 잘린다.
  List<(int, int)> rigCells(int height) => [
    for (var k = 1; k <= kind.rigHeight && y + k < height; k++) (x, y + k),
  ];

  List<Object?> toJson() => [x, y, kind.jsonName, if (level != 1) level];
}

/// (y, x) 순으로 정렬한 모듈.
List<ModuleCell> sortModules(Iterable<ModuleCell> modules) =>
    modules.toList()..sort((a, b) => a.y != b.y ? a.y - b.y : a.x - b.x);

/// 모듈 배치 규칙의 첫 문제, 없으면 null (설계서 §3.3). [sorted] 는 [sortModules] 결과.
///
/// 블록 칸 위, 한 칸에 하나, 포문·망루는 선실 칸에만(선실 칸에는 선실 옵션만),
/// 선장실 1개, 선장실을 뺀 모듈 수는 선형의 기능 모듈 한도 안.
String? moduleProblem(
  HullSpec hull,
  List<ModuleCell> sorted, {
  required bool Function(int x, int y) hasBlock,
  required bool Function(int x, int y) isCabin,
}) {
  var captains = 0;
  var counted = 0;
  for (var i = 0; i < sorted.length; i++) {
    final m = sorted[i];
    final at = '(${m.x}, ${m.y})';
    if (!hasBlock(m.x, m.y)) return '모듈은 블록 위에 있어야 한다: $at';
    if (i > 0 && sorted[i - 1].x == m.x && sorted[i - 1].y == m.y) {
      return '같은 칸에 모듈이 둘: $at';
    }
    if (m.kind.cabinOption != isCabin(m.x, m.y)) {
      return m.kind.cabinOption
          ? '${m.kind.jsonName} 는 선실 칸에만 단다: $at'
          : '선실 칸에는 포문·망루만 단다: $at';
    }
    if (m.level != 1 &&
        (!m.kind.isMast ||
            m.level < 1 ||
            m.level > BlockMaterial.maxRigLevel)) {
      return '모듈 레벨이 맞지 않는다: $at ${m.level}';
    }
    if (m.kind.isMast) {
      final rig = m.rigCells(hull.height);
      if (rig.isEmpty) return '돛대 위에 칸이 없다: $at';
      for (final (x, y) in rig) {
        if (hasBlock(x, y)) return '돛대 칸 자리에 블록이 있다: ($x, $y)';
      }
    }
    if (m.kind == ModuleKind.captain) captains++;
    if (m.kind.countsToLimit) counted++;
  }
  if (captains != 1) return '선장실은 1개여야 한다: $captains';
  if (counted > hull.moduleLimit) {
    return '기능 모듈 한도 초과: $counted > ${hull.moduleLimit}';
  }
  return null;
}

/// 돛대 꼭대기 칸(돛 자리, 설계서 §3.3) 목록.
List<(int, int)> mastSeats(HullSpec hull, Iterable<ModuleCell> modules) => [
  for (final m in modules)
    if (m.kind.isMast && m.rigCells(hull.height).isNotEmpty)
      m.rigCells(hull.height).last,
];

/// 모듈 건조 포인트 합계.
int moduleCost(Iterable<ModuleCell> modules) {
  var cost = 0;
  for (final m in modules) {
    cost += m.kind.cost;
  }
  return cost;
}
