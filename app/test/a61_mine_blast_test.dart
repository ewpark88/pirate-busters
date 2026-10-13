import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/game/cues_unique.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';

import 'test_catalog.dart';

/// 터진 기뢰·설치탄 연출 (A61, 설계서 §4.8, §10.4). 턴 효과 폭발은 비행 착탄이
/// 아니라 착탄 이벤트가 없어, 폭발·카메라·흔들림이 빠져 배가 혼자 가라앉아 보였다.
Future<BattleGame> _game(WidgetTester tester) async {
  late BattleGame game;
  await tester.runAsync(() async {
    final m = testSetup.newMatch(
      1,
      deck: const ['p21_puffy'],
      enemyDeck: const ['p01_octo'],
      rules: const MatchRules(waveLevel: 0),
      costLimit: 20,
      enemyCostLimit: 20,
    );
    game = BattleGame(
      BattleSession(m, humanSides: const {0}, speciesOf: testCatalog.speciesOf),
    )..onGameResize(Vector2(960, 440));
    // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
    // ignore: invalid_use_of_internal_member
    await game.load();
    // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
    // ignore: invalid_use_of_internal_member
    game.mount();
    // ignore: cascade_invocations, mount 은 위의 ignore 가 필요해 캐스케이드로 못 묶는다.
    game.update(0);
    await game.ready();
  });
  return game;
}

SimEvent _fired(EffectKind k, {int cell = -1, int x = 0}) => SimEvent(
  SimEventKind.effectFired,
  side: 1,
  slot: 0,
  cell: cell,
  x: x,
  value: k.index,
);

void main() {
  test('크라키는 붙는 순간 터지므로 조용히 내려앉지 않는다', () {
    PirateSpec spec(String id) => testCatalog.pirates.byId(id);
    expect(BattleCues.landsQuietly(spec('p25_kraki')), isFalse);
    expect(BattleCues.landsQuietly(spec('p21_puffy')), isTrue);
    expect(BattleCues.landsQuietly(spec('p22_jelly')), isTrue);
  });

  test('기뢰 폭발 묶음은 착탄 이벤트가 없어도 한 방 크기를 매긴다', () {
    final w = HitWeight.of([
      _fired(EffectKind.mineBlast, cell: 3),
      const SimEvent(SimEventKind.blockDestroyed, side: 1, cell: 3),
    ]);
    expect(w.score, HitWeight.base + HitWeight.perDestroyed);
    expect(HitWeight.of([_fired(EffectKind.flockDrop)]).score, 0);
  });

  testWidgets('설치탄·떠 있는 기뢰 폭발만 따로 그리고, 펠리 폭탄은 뒤따르는 착탄이 그린다', (
    tester,
  ) async {
    rootBundle.clear();
    final game = await _game(tester);
    expect(game.cues.isMineBlast(_fired(EffectKind.mineBlast)), isTrue);
    expect(game.cues.isMineBlast(_fired(EffectKind.floatMine)), isTrue);
    expect(game.cues.isMineBlast(_fired(EffectKind.flockDrop)), isFalse);
    expect(game.cues.isMineBlast(_fired(EffectKind.gnawBite)), isFalse);
  });

  for (final (name, kind, onHull) in [
    ('붙은 설치탄', EffectKind.mineBlast, true),
    ('떠 있는 기뢰', EffectKind.floatMine, true),
    ('선체가 없는 줄의 떠 있는 기뢰', EffectKind.floatMine, false),
  ]) {
    testWidgets('$name 이 터지면 폭발·흔들림·카메라 당김·이름표가 난다', (tester) async {
      rootBundle.clear();
      final game = await _game(tester);
      final ship = game.session.state.sides[1];
      final grid = ship.grid;
      final cell = [
        for (var i = 0; i < grid.cellCount; i++)
          if (grid.hasBlockAt(i)) i,
      ].last;
      final tags = <HitTag>[];
      game.tagText = (t) {
        tags.add(t);
        return t.name;
      };
      final before = game.cues.fx.children.length;
      game.cues.dispatch([
        _fired(kind, cell: onHull ? cell : -1, x: ship.bowX),
        if (onHull)
          SimEvent(SimEventKind.blockHit, side: 1, cell: cell, value: 40),
        const SimEvent(SimEventKind.flood, side: 1, value: 20),
      ]);
      expect(game.cues.fx.trauma.value, greaterThan(0), reason: '흔들림');
      expect(tags, contains(HitTag.mineBlast));
      game.director.update(CameraDirector.punchIn, (Vector2.zero(), 900));
      expect(game.director.punchScale, lessThan(1), reason: '카메라 당김');
      // 띄운 효과는 다음 프레임에 붙는다.
      game.update(1 / 60);
      expect(
        game.cues.fx.children.length,
        greaterThan(before + 3),
        reason: '물기둥·폭발',
      );
    });
  }
}
