import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/game/shield_cue.dart';
import 'package:pirate_busters/game/view/hull_water.dart';
import 'package:pirate_busters/ui/hud/battle_hud.dart';
import 'package:pirate_busters/ui/hud/hud_gauge.dart';

import 'test_catalog.dart';

SideState _bossSide() => BattleSetup(
  testCatalog,
).newStageMatch(3, testCampaign.stage('1-5')).state.sides[1];

SimEvent _hit(int side, int cell) =>
    SimEvent(SimEventKind.blockHit, side: side, cell: cell, value: 10);

void main() {
  group('A57 방패 표시 (설계서 §5.4, A43 점검 제안 3)', () {
    test('방패가 선 배에 블록 피해가 나면 ‘방패’ 이름표 대상이고 깨지지는 않았다', () {
      final boss = _bossSide();
      final cue = ShieldCue.of(boss, [_hit(1, boss.shieldCells.first)]);
      expect(cue.stood, isTrue);
      expect(cue.broke, isFalse);
    });

    test('블록 피해가 없거나 방패가 없는 배는 표시하지 않는다', () {
      final boss = _bossSide();
      expect(ShieldCue.of(boss, const []).stood, isFalse);
      final plain = BattleSetup(
        testCatalog,
      ).newStageMatch(3, testCampaign.stage('1-3')).state.sides[1];
      expect(ShieldCue.of(plain, [_hit(1, 0)]).stood, isFalse);
    });

    test('이번 묶음에 마지막 방패 칸이 부서지면 ‘방패 깨짐’과 그 칸을 준다', () {
      final boss = _bossSide();
      final shield = boss.shieldCells..forEach(boss.grid.removeAt);
      final cues = [
        for (final i in shield) ...[
          _hit(1, i),
          SimEvent(SimEventKind.blockDestroyed, side: 1, cell: i),
        ],
      ];
      final cue = ShieldCue.of(boss, cues);
      expect(cue.stood, isTrue, reason: '묶음이 시작될 때는 서 있었다');
      expect(cue.broke, isTrue);
      expect(cue.lastCell, shield.last);
      // 이미 깨진 뒤의 다음 묶음은 방패 이름표가 없다.
      expect(ShieldCue.of(boss, [_hit(1, 0)]).stood, isFalse);
    });
  });

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
      expect(BattleHud.foeTurnAlignment.y, greaterThan(-0.4));
      expect(BattleHud.foeTurnAlignment.y, lessThan(0));
    });
  });

  group('A57 선체 경로 캐시 (설계서 §10.4 저사양)', () {
    test('같은 격자면 경로를 다시 만들지 않고, 칸이 바뀌면 다시 만든다', () {
      final side = _bossSide();
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
