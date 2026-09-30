import 'package:pb_sim/src/json_read.dart';
import 'package:pb_sim/src/ship/hull.dart';

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

  /// 돛대: 부러지면 위 블록 붕괴, 연료 2배·속도 절반.
  mast('mast', cost: 2),

  /// 망루: 궤적 표시 50% (선실 옵션).
  lookout('lookout', cost: 2, cabinOption: true),

  /// 선장실: 필수 1개. 부서지면 모든 해적 쿨다운 +1턴.
  captain('captain', cost: 0),

  /// 연료통: 탱크 +40, 부서지면 탱크 −40 과 주변 1칸 피해.
  fuelTank('fuelTank', cost: 2);

  const ModuleKind(
    this.jsonName, {
    required this.cost,
    this.cabinOption = false,
  });

  /// 데이터 이름.
  final String jsonName;

  /// 건조 포인트.
  final int cost;

  /// 선실 칸에만 겹쳐 다는 선실 옵션인가 (포문·망루).
  final bool cabinOption;

  /// 기능 모듈 한도에 세는가: 선장실만 빠진다 (선실은 모듈 목록에 없다).
  bool get countsToLimit => this != captain;

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

  List<Object?> toJson() => [x, y, kind.jsonName];
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
    if (m.kind == ModuleKind.captain) captains++;
    if (m.kind.countsToLimit) counted++;
  }
  if (captains != 1) return '선장실은 1개여야 한다: $captains';
  if (counted > hull.moduleLimit) {
    return '기능 모듈 한도 초과: $counted > ${hull.moduleLimit}';
  }
  return null;
}

/// 모듈 건조 포인트 합계.
int moduleCost(Iterable<ModuleCell> modules) {
  var cost = 0;
  for (final m in modules) {
    cost += m.kind.cost;
  }
  return cost;
}
