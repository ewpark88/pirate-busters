import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_shop.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';

import 'test_catalog.dart';

void main() {
  group('배 해금은 철판만 골드 (설계서 §13.6, BALANCE.md A3.2)', () {
    const rich = PlayerProgress(gold: 5000);

    test('새 게임은 슬루프 하나에 소나무·참나무로 시작한다', () {
      const p = PlayerProgress();
      expect(p.ship.hull, same(HullSpec.sloop));
      expect(p.ship.hasMaterial(BlockMaterial.pine), isTrue);
      expect(p.ship.hasMaterial(BlockMaterial.oak), isTrue);
      expect(p.ship.hasMaterial(BlockMaterial.iron), isFalse);
    });

    test('철판은 300골드로 열고, 처음부터 쓰는 재질은 열 것이 없다', () {
      final iron = ShipShop.unlockMaterial(rich, BlockMaterial.iron)!;
      expect(
        [iron.gold, iron.ship.hasMaterial(BlockMaterial.iron)],
        [
          4700,
          true,
        ],
      );
      expect(ShipShop.unlockMaterial(iron, BlockMaterial.iron), isNull);
      expect(ShipShop.unlockMaterial(rich, BlockMaterial.oak), isNull);
      expect(
        ShipShop.unlockMaterial(
          const PlayerProgress(gold: 299),
          BlockMaterial.iron,
        ),
        isNull,
        reason: '골드 모자람',
      );
    });

    test('해금은 저장했다 읽어도 같고, 옛 저장의 단계·레벨 값은 버린다', () {
      final p = ShipShop.unlockMaterial(rich, BlockMaterial.iron)!;
      final back = PlayerProgress.parse(p.encode());
      expect(jsonEncode(back.ship.toJson()), jsonEncode(p.ship.toJson()));
      final old = ShipUpgrades.fromJson({
        'stage': 3,
        'hullLevel': 5,
        'materials': ['iron'],
      });
      expect(old.toJson(), {
        'materials': ['iron'],
      });
    });

    test('안 연 재질은 소나무로 바꿔 쓴다', () {
      const ship = ShipUpgrades();
      final b = ship.unlockedOnly(testCatalog.preset('armored').blueprint);
      expect(b.cells.any((c) => c.material == BlockMaterial.iron), isFalse);
      expect(
        b.cells,
        hasLength(testCatalog.preset('armored').blueprint.cells.length),
      );
    });
  });
}
