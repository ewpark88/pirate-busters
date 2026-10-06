import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/hull.dart';
import 'package:pb_sim/src/ship/material.dart';

/// 블록 손상 단계 (설계서 §10.2). 렌더용 파생값이라 상태·해시에는 넣지 않는다.
enum DamageStage {
  /// 내구도 2/3 초과.
  intact,

  /// 1/3 초과 ~ 2/3 이하.
  cracked,

  /// 0 초과 ~ 1/3 이하.
  holed,

  /// 블록이 없다.
  destroyed,
}

/// 전투 중 배의 격자 상태. 칸은 행 우선(index = y × width + x)으로 고정된 순서다.
class ShipGrid {
  /// 설계도로 새 격자를 만든다. 모든 블록은 최대 내구도로 시작한다.
  factory ShipGrid.fromBlueprint(Blueprint blueprint) {
    final hull = blueprint.hull;
    final size = hull.width * hull.height;
    final materials = List<int>.filled(size, emptyCell);
    final hp = List<int>.filled(size, 0);
    for (final c in blueprint.cells) {
      final i = c.y * hull.width + c.x;
      materials[i] = c.material.index;
      hp[i] = c.material.durability;
    }
    // 돛대 칸 (설계서 §3.3): 돛대 레벨만큼 내구도가 오른다.
    for (final m in blueprint.modules) {
      final rig = m.kind.rig;
      if (rig == null) continue;
      for (final (x, y) in m.rigCells(hull.height)) {
        final i = y * hull.width + x;
        materials[i] = rig.index;
        hp[i] = rig.durabilityAt(m.level);
      }
    }
    return ShipGrid._(
      hull,
      materials,
      hp,
      _sumOf(hp),
      List.of(materials),
      List.of(hp),
    );
  }

  ShipGrid._(
    this.hull,
    this._materials,
    this._hp,
    this.initialTotalHp,
    this._built,
    this._max,
  );

  /// 빈 칸의 재질 값.
  static const int emptyCell = -1;

  final HullSpec hull;
  final List<int> _materials;
  final List<int> _hp;

  /// 판 시작 때의 재질. 부서진 칸(구멍, 설계서 §2.5)을 가려낸다.
  final List<int> _built;

  /// 칸마다 최대 내구도 (돛대 칸은 레벨이 반영된다).
  final List<int> _max;

  /// 칸 [index] 의 최대 내구도. 손상 단계 경계의 기준이다.
  int maxHpAt(int index) => _max[index];

  int get width => hull.width;
  int get height => hull.height;

  /// 칸 수 (width × height).
  int get cellCount => _materials.length;

  int indexOf(int x, int y) => y * hull.width + x;

  bool inBounds(int x, int y) =>
      x >= 0 && x < hull.width && y >= 0 && y < hull.height;

  /// 칸의 재질. 비어 있으면 null.
  BlockMaterial? materialAt(int x, int y) {
    final m = _materials[indexOf(x, y)];
    return m == emptyCell ? null : BlockMaterial.values[m];
  }

  /// 칸의 현재 내구도. 비어 있으면 0.
  int hpAt(int x, int y) => _hp[indexOf(x, y)];

  /// 블록이 있는가. 격자 밖이면 false.
  bool hasBlock(int x, int y) =>
      inBounds(x, y) && _materials[indexOf(x, y)] != emptyCell;

  /// 인덱스로 블록이 있는가.
  bool hasBlockAt(int index) => _materials[index] != emptyCell;

  /// 설계도에 블록이 있었는데 지금 없는 칸인가 (설계서 §2.5 부서진 칸).
  bool isBroken(int x, int y) {
    final i = indexOf(x, y);
    return _built[i] != emptyCell && _materials[i] == emptyCell;
  }

  /// 칸의 손상 단계. 3등분 경계는 정수 곱셈으로 비교한다.
  DamageStage stageAt(int x, int y) {
    final m = materialAt(x, y);
    if (m == null) return DamageStage.destroyed;
    return stageFor(hpAt(x, y), _max[indexOf(x, y)]);
  }

  /// 내구도 [durability] 인 블록이 [hp] 남았을 때의 손상 단계. 렌더도 이 함수를
  /// 써서 경계를 복사하지 않는다 (설계서 §10.2).
  static DamageStage stageFor(int hp, int durability) {
    final hp3 = hp * 3;
    if (hp3 > durability * 2) return DamageStage.intact;
    if (hp3 > durability) return DamageStage.cracked;
    return DamageStage.holed;
  }

  /// 칸에 [amount] 피해를 준다. 블록이 이번에 파괴됐으면 true.
  bool damage(int x, int y, int amount) {
    if (!hasBlock(x, y) || amount <= 0) return false;
    final i = indexOf(x, y);
    final left = _hp[i] - amount;
    if (left > 0) {
      _hp[i] = left;
      return false;
    }
    removeAt(i);
    return true;
  }

  /// ‘구멍’ 단계 블록을 [amount] 만큼 고친다(최대 내구도까지). 부서진 칸은 고칠 수
  /// 없다 (설계서 §2.5). 고쳤으면 true.
  bool repair(int x, int y, int amount) {
    if (!hasBlock(x, y) || stageAt(x, y) != DamageStage.holed) return false;
    final i = indexOf(x, y);
    final max = _max[i];
    final next = _hp[i] + amount;
    _hp[i] = next > max ? max : next;
    return true;
  }

  /// 블록을 없앤다 (파괴·붕괴).
  void removeAt(int index) {
    _materials[index] = emptyCell;
    _hp[index] = 0;
  }

  /// 인덱스 순서의 재질 값(빈 칸 = [emptyCell]). 해시·렌더용 읽기 전용 보기.
  List<int> get rawMaterials => List.unmodifiable(_materials);

  /// 인덱스 순서의 내구도. 해시·렌더용 읽기 전용 보기.
  List<int> get rawHp => List.unmodifiable(_hp);

  /// 남은 블록 수.
  int get blockCount {
    var n = 0;
    for (final m in _materials) {
      if (m != emptyCell) n++;
    }
    return n;
  }

  /// 판 시작 때 선체 내구도 합계.
  final int initialTotalHp;

  /// 선체 내구도 합계.
  int get totalHp => _sumOf(_hp);

  static int _sumOf(List<int> values) {
    var sum = 0;
    for (final v in values) {
      sum += v;
    }
    return sum;
  }
}
