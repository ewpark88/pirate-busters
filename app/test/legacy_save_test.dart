import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/meta/my_ship.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';

import 'test_catalog.dart';

/// 게임 정리(ADR-111) 전에 저장한 설계도: 확장 단계·펌프·코르크·참나무 돛대가 있다.
const String _legacyBlueprint = '''
{"hull":"sloop","stage":1,
 "cells":[[1,0,"oak"],[2,0,"oak"],[3,0,"oak"],[4,0,"oak"],
          [1,1,"pine"],[2,1,"cork"],[3,1,"pine"],[4,1,"pine"]],
 "cabins":[[1,1],[2,1]],
 "modules":[[3,1,"mastOak"],[4,1,"captain"],[2,0,"pump"]]}
''';

void main() {
  test('옛 규칙으로 저장한 설계도는 예외 없이 빈 칸으로 본다 (실기기 회색 화면 회귀)', () async {
    final fleet = MemoryFleetStore();
    await fleet.writeBlueprint(0, _legacyBlueprint);
    expect(fleet.draft(0), isNotNull);
    expect(fleet.blueprint(0), isNull);
  });

  test('옛 설계도가 출전 칸에 있으면 내 배는 추천 설계도로 대신한다', () async {
    final fleet = MemoryFleetStore();
    await fleet.writeBlueprint(0, _legacyBlueprint);
    final ship = myBlueprint(fleet, testCatalog, const ShipUpgrades());
    expect(ship.modules, isNotEmpty);
    expect(jsonEncode(ship.toJson()), isNot(contains('pump')));
  });

  test('깨진 JSON·규칙 위반 설계도도 빈 칸으로 본다', () async {
    final fleet = MemoryFleetStore();
    await fleet.writeBlueprint(0, '{not json');
    await fleet.writeBlueprint(1, '{"hull":"sloop","cells":[],"cabins":[]}');
    await fleet.writeBlueprint(2, '{"hull":"galleon","cells":[],"cabins":[]}');
    expect(
      [fleet.blueprint(0), fleet.blueprint(1), fleet.blueprint(2)],
      [isNull, isNull, isNull],
    );
  });
}
