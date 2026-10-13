import 'package:pb_sim/src/json_read.dart';
import 'package:pb_sim/src/ship/hull.dart';
import 'package:pb_sim/src/ship/material.dart';

/// 모듈 (설계서 §3.3): 선장실과 돛대 두 가지. 선실은 `CabinCell` 로 따로 둔다. 순서는
/// 해시에 들어가므로 새 값은 뒤에 붙인다. 수치는 BALANCE.md A3.3 (ADR-111).
enum ModuleKind {
  /// 선장실: 필수 1개. 붙은 블록이 부서지면 진다 (설계서 §2.7).
  captain('captain'),

  /// 돛대: 1개까지. 위로 돛대 칸 3칸을 세우고, 꼭대기 칸은 망대다(해적 1명, 피해
  /// +30%). 돛대 칸이 부러지면 망대 해적은 바다로 떨어진다 (설계서 §3.3).
  mast('mast', rig: BlockMaterial.rigPine, rigHeight: 3, seatPercent: 30);

  const ModuleKind(
    this.jsonName, {
    this.rig,
    this.rigHeight = 0,
    this.seatPercent = 0,
  });

  /// 데이터 이름.
  final String jsonName;

  /// 건조 포인트: 모듈은 모두 0 (BALANCE.md A3.3).
  int get cost => 0;

  /// 돛대면 돛대 칸 재질, 아니면 null.
  final BlockMaterial? rig;

  /// 돛대 칸 수(격자 위끝에서 잘린다).
  final int rigHeight;

  /// 망대 해적 피해 보너스(%).
  final int seatPercent;

  bool get isMast => rig != null;

  /// 데이터 이름으로 찾는다. 없으면 [FormatException].
  static ModuleKind byName(String name) {
    for (final k in values) {
      if (k.jsonName == name) return k;
    }
    throw FormatException('알 수 없는 모듈: $name');
  }
}

/// 설계도의 모듈 한 칸. 블록이 있는 칸 위에 붙인다.
class ModuleCell {
  const ModuleCell(this.x, this.y, this.kind);

  /// `[x, y, 종류]`.
  factory ModuleCell.fromJson(Object? raw) {
    if (raw is! List<Object?> || raw.length != 3) {
      throw FormatException('모듈은 [x, y, 종류] 여야 한다: $raw');
    }
    return ModuleCell(
      asInt(raw[0], 'x'),
      asInt(raw[1], 'y'),
      ModuleKind.byName(asString(raw[2], '모듈')),
    );
  }

  final int x;
  final int y;
  final ModuleKind kind;

  /// 돛대 칸 (x, y+1) … 위로 [ModuleKind.rigHeight] 칸, 격자 높이 [height] 에서 잘린다.
  List<(int, int)> rigCells(int height) => [
    for (var k = 1; k <= kind.rigHeight && y + k < height; k++) (x, y + k),
  ];

  List<Object?> toJson() => [x, y, kind.jsonName];
}

/// (y, x) 순으로 정렬한 모듈.
List<ModuleCell> sortModules(Iterable<ModuleCell> modules) =>
    modules.toList()..sort((a, b) => a.y != b.y ? a.y - b.y : a.x - b.x);

/// 모듈 배치 규칙의 첫 문제, 없으면 null (설계서 §3.3). [sorted] 는 [sortModules] 결과.
///
/// 블록 칸 위, 한 칸에 하나, 선실 칸에는 붙이지 않는다, 선장실 1개, 돛대 1개까지이고
/// 돛대 칸 자리는 비어 있어야 한다.
String? moduleProblem(
  HullSpec hull,
  List<ModuleCell> sorted, {
  required bool Function(int x, int y) hasBlock,
  required bool Function(int x, int y) isCabin,
}) {
  var captains = 0;
  var masts = 0;
  for (var i = 0; i < sorted.length; i++) {
    final m = sorted[i];
    final at = '(${m.x}, ${m.y})';
    if (!hasBlock(m.x, m.y)) return '모듈은 블록 위에 있어야 한다: $at';
    if (i > 0 && sorted[i - 1].x == m.x && sorted[i - 1].y == m.y) {
      return '같은 칸에 모듈이 둘: $at';
    }
    if (isCabin(m.x, m.y)) return '선실 칸에는 모듈을 붙이지 않는다: $at';
    if (m.kind.isMast) {
      masts++;
      final rig = m.rigCells(hull.height);
      if (rig.isEmpty) return '돛대 위에 칸이 없다: $at';
      for (final (x, y) in rig) {
        if (hasBlock(x, y)) return '돛대 칸 자리에 블록이 있다: ($x, $y)';
      }
    }
    if (m.kind == ModuleKind.captain) captains++;
  }
  if (captains != 1) return '선장실은 1개여야 한다: $captains';
  if (masts > 1) return '돛대는 1개까지다: $masts';
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
