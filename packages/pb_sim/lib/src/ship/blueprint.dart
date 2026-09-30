import 'package:pb_sim/src/json_read.dart';
import 'package:pb_sim/src/ship/build_check.dart';
import 'package:pb_sim/src/ship/hull.dart';
import 'package:pb_sim/src/ship/material.dart';
import 'package:pb_sim/src/ship/module.dart';

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

/// 배 설계도: 선형 + 블록 배치 + 선실 + 기능 모듈 (설계서 §3.3, §3.4).
///
/// 만들 때 격자 범위, 칸 중복, 용골 연결, 선실 수와 위치, 모듈 배치 규칙, 건조 포인트
/// 상한(블록 + 모듈)을 검사한다. 블록·모듈은 (y, x) 순으로 정렬해 보관한다. 선실은
/// 입력 순서가 곧 선실 슬롯 번호다.
class Blueprint {
  /// 검사에 실패하면 [ArgumentError] (규칙은 [buildProblem]).
  factory Blueprint(
    HullSpec hull,
    Iterable<BlockCell> cells, {
    required List<CabinCell> cabins,
    required List<ModuleCell> modules,
  }) {
    final sorted = _sortCells(cells);
    final problem = buildProblem(
      hull,
      sorted,
      cabins: cabins,
      modules: modules,
    );
    if (problem != null) throw ArgumentError(problem);
    final placed = sortModules(modules);
    var cost = moduleCost(placed);
    for (final c in sorted) {
      cost += c.material.cost;
    }
    return Blueprint._(
      hull,
      List.unmodifiable(sorted),
      List.unmodifiable(cabins),
      List.unmodifiable(placed),
      cost,
    );
  }

  Blueprint._(this.hull, this.cells, this.cabins, this.modules, this.cost);

  /// JSON 에서 읽는다. 형식 오류는 [FormatException], 규칙 위반은 [ArgumentError].
  factory Blueprint.fromJson(Map<String, Object?> json) {
    final (hull, cells, cabins, modules) = _partsFromJson(json);
    return Blueprint(hull, cells, cabins: cabins, modules: modules);
  }

  /// JSON 설계도의 건조 규칙 문제([buildProblem]), 없으면 null. 형식 오류는
  /// [FormatException]. 예외 없이 규칙만 확인할 때 쓴다(데이터 검사).
  static String? problemOfJson(Map<String, Object?> json) {
    final (hull, cells, cabins, modules) = _partsFromJson(json);
    return buildProblem(
      hull,
      _sortCells(cells),
      cabins: cabins,
      modules: modules,
    );
  }

  static (HullSpec, List<BlockCell>, List<CabinCell>, List<ModuleCell>)
  _partsFromJson(Map<String, Object?> json) => (
    HullSpec.byId(readString(json, 'hull')),
    [for (final raw in readList(json, 'cells')) _cellFromJson(raw)],
    [for (final raw in readList(json, 'cabins')) _cabinFromJson(raw)],
    [for (final raw in readList(json, 'modules')) ModuleCell.fromJson(raw)],
  );

  static List<BlockCell> _sortCells(Iterable<BlockCell> cells) =>
      cells.toList()..sort((a, b) => a.y != b.y ? a.y - b.y : a.x - b.x);

  final HullSpec hull;

  /// (y, x) 순으로 정렬된 블록.
  final List<BlockCell> cells;

  /// 선실 슬롯 순서의 선실 위치. 개수는 선형의 선실 슬롯 수와 같다.
  final List<CabinCell> cabins;

  /// (y, x) 순으로 정렬된 기능 모듈. 선장실이 꼭 하나 있다.
  final List<ModuleCell> modules;

  /// 총 건조 비용(블록 + 모듈).
  final int cost;

  /// `{"hull": "sloop", "cells": [[x, y, "oak"], ...], "cabins": [[x, y], ...],
  /// "modules": [[x, y, "pump"], ...]}`
  Map<String, Object?> toJson() => {
    'hull': hull.id,
    'cells': [
      for (final c in cells) [c.x, c.y, c.material.name],
    ],
    'cabins': [
      for (final c in cabins) [c.x, c.y],
    ],
    'modules': [for (final m in modules) m.toJson()],
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

  static CabinCell _cabinFromJson(Object? raw) {
    if (raw is! List<Object?> || raw.length != 2) {
      throw FormatException('선실은 [x, y] 여야 한다: $raw');
    }
    return CabinCell(asInt(raw[0], 'x'), asInt(raw[1], 'y'));
  }
}
