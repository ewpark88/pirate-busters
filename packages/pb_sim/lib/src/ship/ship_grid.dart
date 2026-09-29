import 'package:pb_sim/src/ship/blueprint.dart';
import 'package:pb_sim/src/ship/hull.dart';
import 'package:pb_sim/src/ship/material.dart';

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
    return ShipGrid._(hull, materials, hp);
  }

  ShipGrid._(this.hull, this._materials, this._hp);

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

  /// 선체 내구도 합계.
  int get totalHp {
    var sum = 0;
    for (final h in _hp) {
      sum += h;
    }
    return sum;
  }
}
