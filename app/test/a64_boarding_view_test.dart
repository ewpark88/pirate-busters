import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Canvas;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/view/boarder_view.dart';
import 'package:pirate_busters/game/view/crew_reactions.dart';

import 'test_catalog.dart';

/// A64 강습 해적 적 갑판 체류 화면 (설계서 §2.3, §10.4, ADR-110). 판정은 시뮬레이션이
/// 하고, 화면은 선 해적·올라탐·물기·반격·떨어짐을 그리기만 한다.
Future<BattleGame> _game(WidgetTester tester) async {
  late BattleGame game;
  await tester.runAsync(() async {
    final m = testSetup.newMatch(
      1,
      deck: const ['p31_sharky'],
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

void _render(BattleGame game) {
  final recorder = ui.PictureRecorder();
  game.render(Canvas(recorder));
  recorder.endRecording().dispose();
}

void main() {
  test('적 배 위에 선 해적은 자기 배에 그리지 않는다', () {
    expect(PirateStatus.boarding.showsAtHome, isFalse);
    expect(PirateStatus.down.showsAtHome, isFalse);
    expect(PirateStatus.aboard.showsAtHome, isTrue);
    expect(PirateStatus.swimming.showsAtHome, isTrue);
  });

  testWidgets('선 강습 해적을 적 배 위에 그리고, 올라탐·반격·물기·떨어짐 연출이 돈다', (
    tester,
  ) async {
    rootBundle.clear();
    final game = await _game(tester);
    final state = game.session.state;
    final enemy = state.sides[1];
    final sharky = state.sides[0].crew.pirates[0];
    final cell = deckCellAt(enemy.grid, enemy.grid.width ~/ 2);
    sharky
      ..status = PirateStatus.boarding
      ..boardCell = cell;
    enemy.crew.foe = state.sides[0].crew;
    final tags = <HitTag>[];
    game
      ..tagText = (t) {
        tags.add(t);
        return t.name;
      }
      ..update(1 / 60);
    final view = game.world.children.whereType<BoarderView>().single;
    final feet = view.feetOf(0, 0);
    expect(feet, isNotNull);
    expect(
      (feet!.x - game.cues.cellWorld(1, cell).x).abs(),
      lessThan(20),
      reason: '밟은 칸 위',
    );
    game.cues.dispatch([
      SimEvent(SimEventKind.boarded, side: 0, slot: 0, cell: cell),
      const SimEvent(SimEventKind.boardDefended, side: 1, slot: 0),
      const SimEvent(SimEventKind.pirateHit, side: 0, slot: 0, value: 30),
      SimEvent(
        SimEventKind.effectFired,
        side: 1,
        slot: 0,
        cell: cell,
        value: EffectKind.biteAgain.index,
      ),
      const SimEvent(SimEventKind.pirateHit, side: 1, slot: 0, value: 45),
    ]);
    expect(tags, containsAll([HitTag.boarded, HitTag.repel, HitTag.bite]));
    for (var i = 0; i < 10; i++) {
      game.update(1 / 30);
    }
    _render(game);
    // 흔들려 바다에 빠졌다: ‘털어냄’ 이름표, 떨어지며 사라진다.
    sharky
      ..status = PirateStatus.swimming
      ..boardCell = -1;
    game.cues.dispatch([
      const SimEvent(SimEventKind.pirateFell, side: 0, slot: 0),
    ]);
    expect(tags, contains(HitTag.shakenOff));
    game.update(1 / 60);
    expect(view.fallingOf(0, 0), isTrue);
    _render(game);
    for (var i = 0; i < 40; i++) {
      game.update(1 / 30);
    }
    expect(view.fallingOf(0, 0), isFalse);
    expect(view.feetOf(0, 0), isNull, reason: '떨어진 뒤 사라진다');
  });
}
