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

/// 선실 위치 (설계서 §3.3). 블록이 있는 칸 위에 둔다. 해적은 이 칸 안에 탄다.
class CabinCell {
  const CabinCell(this.x, this.y);

  final int x;
  final int y;
}

/// 배 설계도: 선형 + 블록 배치 + 선실 (설계서 §3.4).
///
/// 만들 때 격자 범위, 칸 중복, 건조 포인트 상한, 선실 수와 위치를 검사한다. 블록은
/// (y, x) 순으로 정렬해 보관한다. 선실은 입력 순서가 곧 선실 슬롯 번호다.
class Blueprint {
  /// 검사에 실패하면 [ArgumentError].
  factory Blueprint(
    HullSpec hull,
    Iterable<BlockCell> cells, {
    required List<CabinCell> cabins,
  }) {
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
    _checkKeel(hull, sorted);
    _checkCabins(hull, sorted, cabins);
    return Blueprint._(
      hull,
      List.unmodifiable(sorted),
      List.unmodifiable(cabins),
      cost,
    );
  }

  Blueprint._(this.hull, this.cells, this.cabins, this.cost);

  /// JSON 에서 읽는다. 형식 오류는 [FormatException], 규칙 위반은 [ArgumentError].
  factory Blueprint.fromJson(Map<String, Object?> json) {
    final hull = HullSpec.byId(readString(json, 'hull'));
    final cells = [
      for (final raw in readList(json, 'cells')) _cellFromJson(raw),
    ];
    final cabins = [
      for (final raw in readList(json, 'cabins')) _cabinFromJson(raw),
    ];
    return Blueprint(hull, cells, cabins: cabins);
  }

  final HullSpec hull;

  /// (y, x) 순으로 정렬된 블록.
  final List<BlockCell> cells;

  /// 선실 슬롯 순서의 선실 위치. 개수는 선형의 선실 슬롯 수와 같다.
  final List<CabinCell> cabins;

  /// 총 건조 비용.
  final int cost;

  /// `{"hull": "sloop", "cells": [[x, y, "oak"], ...], "cabins": [[x, y], ...]}`
  Map<String, Object?> toJson() => {
    'hull': hull.id,
    'cells': [
      for (final c in cells) [c.x, c.y, c.material.name],
    ],
    'cabins': [
      for (final c in cabins) [c.x, c.y],
    ],
  };

  /// 모든 블록이 용골(y = 0 줄)과 상하좌우로 이어져 있어야 한다 (설계서 §3.4).
  static void _checkKeel(HullSpec hull, List<BlockCell> sorted) {
    final w = hull.width;
    final filled = List<bool>.filled(w * hull.height, false);
    for (final c in sorted) {
      filled[c.y * w + c.x] = true;
    }
    final seen = List<bool>.filled(filled.length, false);
    final queue = <int>[
      for (var x = 0; x < w; x++)
        if (filled[x]) x,
    ];
    if (queue.isEmpty) throw ArgumentError('용골 줄(y = 0)에 블록이 없다');
    for (final i in queue) {
      seen[i] = true;
    }
    for (var head = 0; head < queue.length; head++) {
      final i = queue[head];
      final x = i % w;
      final y = i ~/ w;
      for (final (nx, ny) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]) {
        if (nx < 0 || nx >= w || ny < 0 || ny >= hull.height) continue;
        final j = ny * w + nx;
        if (filled[j] && !seen[j]) {
          seen[j] = true;
          queue.add(j);
        }
      }
    }
    for (final c in sorted) {
      if (!seen[c.y * w + c.x]) {
        throw ArgumentError('용골과 이어지지 않은 블록: (${c.x}, ${c.y})');
      }
    }
  }

  static void _checkCabins(
    HullSpec hull,
    List<BlockCell> sorted,
    List<CabinCell> cabins,
  ) {
    if (cabins.length != hull.cabinSlots) {
      throw ArgumentError(
        '선실 수는 ${hull.cabinSlots} 이어야 한다: ${cabins.length}',
      );
    }
    for (var i = 0; i < cabins.length; i++) {
      final c = cabins[i];
      if (!sorted.any((b) => b.x == c.x && b.y == c.y)) {
        throw ArgumentError('선실은 블록 위에 있어야 한다: (${c.x}, ${c.y})');
      }
      for (var j = 0; j < i; j++) {
        if (cabins[j].x == c.x && cabins[j].y == c.y) {
          throw ArgumentError('같은 칸에 선실이 둘: (${c.x}, ${c.y})');
        }
      }
    }
  }

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

  static CabinCell _cabinFromJson(Object? raw) {
    if (raw is! List<Object?> || raw.length != 2) {
      throw FormatException('선실은 [x, y] 여야 한다: $raw');
    }
    return CabinCell(asInt(raw[0], 'x'), asInt(raw[1], 'y'));
  }
}
