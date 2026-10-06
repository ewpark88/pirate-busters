import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/meta/my_ship.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_shop.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';

import 'test_catalog.dart';

bool _noEight(String id) => id != '1-8';

void main() {
  group('확장 단계 열림 (설계서 §3.1, BALANCE.md A3.1)', () {
    test('새 게임은 돛단배(6×5, 선실 2)로 시작한다', () {
      const p = PlayerProgress();
      expect(p.ship.stage, 1);
      expect(
        [p.ship.hull.width, p.ship.hull.height, p.ship.hull.cabinSlots],
        [
          6,
          5,
          2,
        ],
      );
    });

    test('1-4·1-8(없으면 1-5)·1-12 를 깨면 차례로 열린다', () {
      int opened(Set<String> cleared) =>
          ShipUpgrades.openedStage(cleared.contains, _noEight);
      expect(opened({}), 1);
      expect(opened({'1-4'}), 2);
      expect(opened({'1-4', '1-5'}), 3);
      expect(opened({'1-4', '1-5', '1-12'}), 4);
      expect(opened({'1-5', '1-12'}), 1, reason: '앞 단계를 건너뛰지 않는다');
      expect(
        ShipUpgrades.openedStage({'1-4', '1-5'}.contains, (_) => true),
        2,
        reason: '1-8 이 있으면 1-5 로는 안 열린다',
      );
    });

    test('배 업그레이드 전 저장은 깬 스테이지만큼 단계를 골드 없이 받는다', () {
      final old = PlayerProgress.fromJson({
        'gold': 70,
        'stars': {'1-1': 3, '1-4': 2, '1-5': 1},
      });
      expect(old.ship.stage, 3);
      expect(old.gold, 70);
      final back = PlayerProgress.parse(old.encode());
      expect(back.ship.stage, 3);
    });
  });

  group('배 업그레이드는 모두 골드 (설계서 §13.6, BALANCE.md A13.6)', () {
    const rich = PlayerProgress(gold: 5000);

    test('확장 단계는 열린 뒤에만, 골드가 있어야 짓는다', () {
      expect(ShipShop.buildStage(rich, opened: 1), isNull, reason: '안 열림');
      expect(
        ShipShop.buildStage(const PlayerProgress(gold: 149), opened: 2),
        isNull,
        reason: '골드 모자람',
      );
      final next = ShipShop.buildStage(rich, opened: 2)!;
      expect([next.ship.stage, next.gold], [2, 4850]);
      final dev = ShipShop.buildStage(
        const PlayerProgress(),
        opened: 1,
        free: true,
      )!;
      expect([dev.ship.stage, dev.gold], [2, 0], reason: '개발 도구');
    });

    test('선형 레벨·재질·모듈·돛대 종류·돛대 레벨 금액이 표와 같다', () {
      expect(ShipShop.levelHull(rich)!.gold, 4900);
      expect(
        [
          for (var lv = 2; lv <= 10; lv++) ShipUpgrades.hullLevelGold(lv),
        ].fold(0, (a, b) => a + b),
        15950,
        reason: 'A13.7 Lv1→10 합계',
      );
      expect(ShipUpgrades.hullLevelGold(20), 24000);
      expect(ShipUpgrades.hullLevelGold(50), 204000);
      final iron = ShipShop.unlockMaterial(rich, BlockMaterial.iron)!;
      expect(
        [iron.gold, iron.ship.hasMaterial(BlockMaterial.iron)],
        [
          4400,
          true,
        ],
      );
      expect(ShipShop.unlockMaterial(iron, BlockMaterial.iron), isNull);
      expect(
        ShipShop.unlockMaterial(rich, BlockMaterial.oak),
        isNull,
        reason: '처음부터',
      );
      expect(
        ShipShop.levelMast(rich, ModuleKind.mastOak),
        isNull,
        reason: '안 엶',
      );
      final oak = ShipShop.unlockModule(rich, ModuleKind.mastOak)!;
      final lv2 = ShipShop.levelMast(oak, ModuleKind.mastOak)!;
      expect(
        [oak.gold, lv2.gold, lv2.ship.mastLevel(ModuleKind.mastOak)],
        [
          4850,
          4750,
          2,
        ],
      );
    });

    test('업그레이드는 저장했다 읽어도 같다', () {
      final p = ShipShop.unlockModule(
        ShipShop.levelHull(rich)!,
        ModuleKind.workshop,
      )!;
      final back = PlayerProgress.parse(p.encode());
      expect(jsonEncode(back.ship.toJson()), jsonEncode(p.ship.toJson()));
    });
  });

  group('설계도 키우기 (설계서 §3.1)', () {
    test('작은 단계 설계도는 가운데를 맞춰 옮기고 새 칸은 빈다', () {
      final small = testCatalog.preset('balanced', stage: 1).blueprint.toJson();
      final grown = ShipShop.grow(small, 2);
      expect(grown['stage'], 2);
      final first = (small['cells']! as List).first as List;
      final moved = (grown['cells']! as List).first as List;
      expect(moved[0], (first[0]! as int) + 1, reason: '폭 6 → 8');
      expect(ShipShop.grow(grown, 1), same(grown), reason: '줄이지 않는다');
    });

    test('키운 설계도는 새 선실을 놓기 전까지 규칙에 안 맞아 추천 설계도로 나간다', () async {
      final fleet = MemoryFleetStore();
      await fleet.saveBlueprint(
        0,
        testCatalog.preset('balanced', stage: 1).blueprint,
      );
      expect(fleet.blueprint(0, stage: 1), isNotNull);
      expect(fleet.blueprint(0, stage: 2), isNull, reason: '선실 2 < 3');
      expect(fleet.draft(0, 2)!['stage'], 2);
      const ship = ShipUpgrades(stage: 2, hullLevel: 3);
      final mine = myBlueprint(fleet, testCatalog, ship);
      expect([mine.hull.stage, mine.hull.level], [2, 3]);
      expect(
        mine.cells.any((c) => c.material == BlockMaterial.net),
        isFalse,
        reason: '안 연 망사는 소나무로',
      );
    });

    test('전투에 나가는 배에는 선형 레벨과 돛대 레벨이 찍힌다', () {
      const ship = ShipUpgrades(
        stage: 4,
        hullLevel: 5,
        mastLevels: {'mast': 3},
      );
      final b = ship.stamp(testCatalog.preset('balanced').blueprint);
      expect(b.hull.level, 5);
      expect(
        b.modules.firstWhere((m) => m.kind == ModuleKind.mast).level,
        3,
      );
    });
  });

  test('무과금 기준: 확장 단계와 1층 해금이 지금 해역 1 첫 클리어 골드 안에 든다 (B11)', () {
    final stages = ShipUpgrades.stageGold.values.fold(0, (a, b) => a + b);
    final tier1 =
        ShipUpgrades.materialGold[BlockMaterial.net]! +
        ShipUpgrades.moduleGold[ModuleKind.workshop]! +
        ShipUpgrades.moduleGold[ModuleKind.gunPort]! +
        ShipUpgrades.moduleGold[ModuleKind.mastOak]!;
    expect([stages, tier1], [950, 550]);
    const sea1FirstClears = 50 * 3 + 100 + 120 + 150 + 200 + 300 + 500;
    expect(stages + tier1, lessThanOrEqualTo(sea1FirstClears));
  });
}
