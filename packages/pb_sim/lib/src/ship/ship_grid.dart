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
    return ShipGrid._(hull, materials, hp, _sumOf(hp));
  }

  ShipGrid._(this.hull, this._materials, this._hp, this.initialTotalHp);

  /// 빈 칸의 재질 값.
  static const int emptyCell = -1;

  final HullSpec hull;
  final List<int> _materials;
  final List<int> _hp;

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

  /// 칸의 손상 단계. 3등분 경계는 정수 곱셈으로 비교한다.
  DamageStage stageAt(int x, int y) {
    final m = materialAt(x, y);
    if (m == null) return DamageStage.destroyed;
    final hp3 = hpAt(x, y) * 3;
    if (hp3 > m.durability * 2) return DamageStage.intact;
    if (hp3 > m.durability) return DamageStage.cracked;
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
