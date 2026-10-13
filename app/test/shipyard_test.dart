import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/crew/deck_eval.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';

import 'test_catalog.dart';

void main() {
  group('조선소 편집 (설계서 §13.6)', () {
    test('추천 설계도를 불러오면 규칙에 맞아 저장할 수 있고, 수치는 pb_sim 과 같다', () {
      final preset = testCatalog.preset('balanced').blueprint;
      final m = ShipyardModel()..load(preset);
      expect(m.canSave, isTrue);
      expect(m.stats.cost, preset.cost);
      expect(m.toBlueprint()!.toJson(), preset.toJson());
    });

    test('누르면 설치, 한 번 끌기는 되돌리기 한 번, 길게 누르면 지운다', () {
      final m = ShipyardModel()
        ..selectTool(const MaterialTool(BlockMaterial.pine))
        ..apply(2, 0);
      expect(m.materialAt(2, 0), BlockMaterial.pine);
      m.beginStroke();
      for (var x = 3; x < 7; x++) {
        m.apply(x, 0);
      }
      m.endStroke();
      expect(m.cells, hasLength(5));
      m.undo();
      expect(m.cells, hasLength(1), reason: '끌기 한 획이 한 번에 돌아간다');
      m.eraseAt(2, 0);
      expect(m.cells, isEmpty);
      m.undo();
      expect(m.cells, hasLength(1));
    });

    test('선실은 블록 위·4칸까지, 선장실·돛대는 선실이 아닌 블록 위에 하나씩 (설계서 §3.3)', () {
      final m = ShipyardModel()
        ..selectTool(const MaterialTool(BlockMaterial.oak));
      for (var x = 2; x < 9; x++) {
        m.apply(x, 0);
      }
      m
        ..selectTool(const CabinTool())
        ..apply(2, 3); // 블록이 없다
      expect(m.cabins, isEmpty);
      for (var x = 2; x < 7; x++) {
        m.apply(x, 0);
      }
      expect(m.cabins, hasLength(4), reason: '슬루프 선실 4');
      m
        ..selectTool(const ModuleTool(ModuleKind.captain))
        ..apply(2, 0);
      expect(m.moduleAt(2, 0), isNull, reason: '선실 칸');
      m.apply(7, 0);
      expect(m.moduleAt(7, 0), ModuleKind.captain);
      m.apply(8, 0);
      expect(m.moduleAt(7, 0), isNull, reason: '하나뿐이라 옮긴다');
      expect(m.moduleAt(8, 0), ModuleKind.captain);
    });

    test('격자 밖 칸에는 아무것도 놓지 않는다 (설계서 §3.4)', () {
      final m = ShipyardModel()
        ..selectTool(const MaterialTool(BlockMaterial.oak))
        ..apply(-1, 0)
        ..apply(12, 1)
        ..apply(0, 8);
      expect(m.cells, isEmpty);
      m.apply(0, 0);
      expect(m.materialAt(0, 0), BlockMaterial.oak);
    });

    test('용골과 끊긴 블록은 빨간 칸이고 그 상태로는 저장할 수 없다', () {
      final m = ShipyardModel()
        ..load(testCatalog.preset('fast').blueprint)
        ..selectTool(const MaterialTool(BlockMaterial.pine))
        ..apply(6, 6);
      expect(m.loose, {6 * m.width + 6});
      expect(m.canSave, isFalse);
      expect(m.toBlueprint(), isNull);
    });
  });

  group('설계도·덱 저장 (설계서 §3.4)', () {
    test('3칸에 저장했다 읽으면 같고, 깨진 칸은 빈 칸으로 본다', () async {
      final store = MemoryFleetStore();
      final b = testCatalog.preset('armored').blueprint;
      await store.saveBlueprint(2, b);
      expect(store.blueprint(2)!.toJson(), b.toJson());
      expect(store.blueprint(0), isNull);
      await store.writeBlueprint(1, '{"hull":"sloop"');
      expect(store.blueprint(1), isNull);
      await store.setDeck(['p01_octo', 'p06_pang']);
      expect(store.deck, ['p01_octo', 'p06_pang']);
    });

    test('저장한 덱이 코스트를 넘거나 모르는 해적이면 시작 해적으로 출전한다', () {
      final ok = testSetup.newMatchFor(1, deck: const ['p06_pang', 'p11_finn']);
      expect(ok.state.sides[0].crew.size, 2);
      final bad = testSetup.newMatchFor(1, deck: const ['p99_nobody']);
      expect(
        [for (final p in bad.state.sides[0].crew.pirates) p.spec.id],
        ['p01_octo', 'p36_tok'],
      );
    });
  });

  test('덱 평가: 계열 분포와 코스트 (설계서 §13.7)', () {
    final pirates = testCatalog.pirates;
    final deck = DeckEval([
      pirates.byId('p06_pang'),
      pirates.byId('p31_sharky'),
      pirates.byId('p01_octo'),
    ]);
    expect(deck.families, {
      Family.lob: 1,
      Family.direct: 1,
      Family.assault: 1,
    });
    expect(deck.cost, 9);
  });
}
