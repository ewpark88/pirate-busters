import 'package:pb_sim/src/json_read.dart';
import 'package:pb_sim/src/ship/hull.dart';
import 'package:pb_sim/src/ship/material.dart';

/// 설계도의 블록 한 칸. y = 0 이 용골 줄이다.
class BlockCell {
  const BlockCell(this.x, this.y, this.material);

  final int x;
  final int y;
  final BlockMaterial material;
}

/// 배 설계도: 선형 + 블록 배치 (설계서 §3.4).
///
/// 만들 때 격자 범위, 칸 중복, 건조 포인트 상한을 검사한다. 칸은 (y, x) 순으로
/// 정렬해 보관하므로 입력 순서와 무관하게 같은 설계도는 같은 값이 된다.
class Blueprint {
  /// 검사에 실패하면 [ArgumentError].
  factory Blueprint(HullSpec hull, Iterable<BlockCell> cells) {
    final sorted = cells.toList()
      ..sort((a, b) => a.y != b.y ? a.y - b.y : a.x - b.x);
    var cost = 0;
    for (var i = 0; i < sorted.length; i++) {
      final c = sorted[i];
      if (c.x < 0 || c.x >= hull.width || c.y < 0 || c.y >= hull.height) {
        throw ArgumentError('격자 밖 블록: (${c.x}, ${c.y})');
      }
      if (i > 0 && sorted[i - 1].x == c.x && sorted[i - 1].y == c.y) {
        throw ArgumentError('같은 칸에 블록이 둘: (${c.x}, ${c.y})');
      }
      cost += c.material.cost;
    }
    if (cost > hull.buildPoints) {
      throw ArgumentError('건조 포인트 초과: $cost > ${hull.buildPoints}');
    }
    return Blueprint._(hull, List.unmodifiable(sorted), cost);
  }

  Blueprint._(this.hull, this.cells, this.cost);

  /// JSON 에서 읽는다. 형식 오류는 [FormatException], 규칙 위반은 [ArgumentError].
  factory Blueprint.fromJson(Map<String, Object?> json) {
    final hull = HullSpec.byId(readString(json, 'hull'));
    final cells = [
      for (final raw in readList(json, 'cells')) _cellFromJson(raw),
    ];
    return Blueprint(hull, cells);
  }

  final HullSpec hull;

  /// (y, x) 순으로 정렬된 블록.
  final List<BlockCell> cells;

  /// 총 건조 비용.
  final int cost;

  /// `{"hull": "sloop", "cells": [[x, y, "oak"], ...]}`
  Map<String, Object?> toJson() => {
    'hull': hull.id,
    'cells': [
      for (final c in cells) [c.x, c.y, c.material.name],
    ],
  };

  static BlockCell _cellFromJson(Object? raw) {
    if (raw is! List<Object?> || raw.length != 3) {
      throw FormatException('블록은 [x, y, 재질] 이어야 한다: $raw');
    }
    return BlockCell(
      asInt(raw[0], 'x'),
      asInt(raw[1], 'y'),
      BlockMaterial.byName(asString(raw[2], '재질')),
    );
  }
}
