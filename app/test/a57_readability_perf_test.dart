import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/game/view/hull_water.dart';
import 'package:pirate_busters/ui/hud/battle_banners.dart';
import 'package:pirate_busters/ui/hud/hud_gauge.dart';

import 'test_catalog.dart';

SideState _stageSide() => BattleSetup(
  testCatalog,
).newStageMatch(3, testCampaign.stage('1-5')).state.sides[1];

void main() {
  group('A57 수리 +n% (A41 점검 제안 3)', () {
    Widget gauge(double v) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 120,
          child: HudGauge(
            value: v,
            color: Colors.blue,
            gainLabel: (p) => '+$p%',
          ),
        ),
      ),
    );

    testWidgets('선체가 오르면 오른 몫을 잠깐 띄우고 사라진다', (tester) async {
      await tester.pumpWidget(gauge(.6));
      await tester.pumpWidget(gauge(.72));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('+12%'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('+12%'), findsNothing);
    });

    testWidgets('깎일 때는 띄우지 않는다', (tester) async {
      await tester.pumpWidget(gauge(.8));
      await tester.pumpWidget(gauge(.5));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byKey(const ValueKey('gauge-gain')), findsNothing);
    });
  });

  group('A57 상대 턴 배치 (A43 점검 버그 6)', () {
    test('상대 턴 배너는 위쪽 패널·시간 판정 띠(화면 위 30%)보다 아래에 둔다', () {
      expect(BattleBanners.foeTurnAlignment.y, greaterThan(-0.4));
      expect(BattleBanners.foeTurnAlignment.y, lessThan(0));
    });
  });

  group('A57 선체 경로 캐시 (설계서 §10.4 저사양)', () {
    test('같은 격자면 경로를 다시 만들지 않고, 칸이 바뀌면 다시 만든다', () {
      final side = _stageSide();
      final grid = side.grid;
      final materials = [
        for (var i = 0; i < grid.width * grid.height; i++)
          grid.hasBlockAt(i)
              ? grid.materialAt(i % grid.width, i ~/ grid.width)!.index
              : ShipGrid.emptyCell,
      ];
      Rect cell(int x, int y) => Rect.fromLTWH(x * 10.0, -y * 10.0, 10, 10);
      final cache = HullPathCache();
      final (a, _) = cache.of(grid.hull, materials, grid.width, cell);
      final (b, _) = cache.of(grid.hull, List.of(materials), grid.width, cell);
      expect(identical(a, b), isTrue);
      expect(cache.builds, 1);
      final first = materials.indexWhere((m) => m != ShipGrid.emptyCell);
      materials[first] = ShipGrid.emptyCell;
      cache.of(grid.hull, materials, grid.width, cell);
      expect(cache.builds, 2);
    });
  });
}
