import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/module_painter.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

void main() {
  group('메타 아이콘·모듈 그림 (에셋 v0.23, ADR-063)', () {
    test('HUD·결과·설정·항구·전투 준비가 쓰는 아이콘 그림이 모두 있다', () {
      final paths = [
        MetaIcons.hull,
        MetaIcons.flood,
        MetaIcons.crew,
        MetaIcons.turns,
        MetaIcons.timer,
        MetaIcons.fullView,
        MetaIcons.endTurn,
        MetaIcons.pause,
        MetaIcons.surrender,
        MetaIcons.outOfRange,
        MetaIcons.cancel,
        MetaIcons.moveForward,
        MetaIcons.moveBack,
        MetaIcons.ad2x,
        MetaIcons.replay,
        MetaIcons.starOn,
        MetaIcons.starOff,
        MetaIcons.language,
        MetaIcons.sound,
        MetaIcons.vibrate,
        MetaIcons.lowSpec,
        MetaIcons.gold,
        for (final p in Personality.values) MetaIcons.personality(p),
        for (var sea = 1; sea <= 6; sea++) MetaIcons.factionOfSea(sea),
      ];
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('해역 1 세력 깃발은 붉은집게 초계대다 (설계서 §15.3)', () {
      expect(MetaIcons.factionOfSea(1), endsWith('faction_redclaw.png'));
    });

    test('모듈 8종 모두 그림과 자리가 있고 선실 그림 2장이 있다', () {
      for (final k in ModuleKind.values) {
        final file = 'assets/images/${BattleSprites.moduleFile(k)}';
        expect(File(file).existsSync(), isTrue, reason: file);
        expect(BattleSprites.files, contains(BattleSprites.moduleFile(k)));
        expect(ModulePainter.art, contains(k));
      }
      for (final (x, y) in [(0, 0), (1, 0)]) {
        expect(File(ShipGridView.cabinImage(x, y)).existsSync(), isTrue);
      }
    });

    test('포문은 앞벽 밖으로 8px 나가고 망루는 선실 위 1칸으로 솟는다', () {
      final (gunAt, gunSize) = ModulePainter.art[ModuleKind.gunPort]!;
      expect(gunAt.dx + gunSize.width, 40);
      final (nestAt, nestSize) = ModulePainter.art[ModuleKind.lookout]!;
      expect(nestAt.dy, -32);
      expect(nestAt.dy + nestSize.height, 32);
      // 돛대 밑동은 돛대 모듈 칸 가운데, 칸 위에서 6px 아래.
      final foot = ModulePainter.mastFoot(const Rect.fromLTWH(64, -96, 32, 32));
      expect((foot.dx, foot.dy), (80, -90));
    });

    test('돛대는 돛대 모듈마다 서고, 모듈 칸이 부서지면 없고, 모듈이 없으면 가운데에 선다', () {
      // 가로 4칸 × 2줄. 칸 번호 = y × 4 + x.
      const e = ShipGrid.emptyCell;
      Rect cell(int x, int y) =>
          Rect.fromLTWH(x * 32.0, -(y + 1) * 32.0, 32, 32);
      final materials = [0, 0, 0, 0, 0, 0, 0, 0];
      final masts = {
        1: ModuleKind.mast,
        6: ModuleKind.mast,
        2: ModuleKind.pump,
      };
      final feet = ModulePainter.mastFeet(materials, 4, masts, cell)!;
      expect(feet.map((f) => (f.dx, f.dy)), [(48, -26), (80, -58)]);
      // 6번 칸(돛대 모듈)이 부서지면 그 돛대는 없다.
      final broken = [...materials]..[6] = e;
      expect(ModulePainter.mastFeet(broken, 4, masts, cell), hasLength(1));
      // 돛대 모듈이 없는 배는 null(가장 높은 블록 위 가운데).
      expect(
        ModulePainter.mastFeet(materials, 4, {2: ModuleKind.pump}, cell),
        isNull,
      );
    });
  });
}
