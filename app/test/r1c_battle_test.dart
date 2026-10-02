import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Canvas;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/shot_flow.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/view/fire_view.dart';
import 'package:pirate_busters/game/view/ship_view.dart';
import 'package:pirate_busters/input/aim_mode.dart';
import 'package:pirate_busters/input/pull_aim.dart';

import 'test_catalog.dart';

/// 턴마다 [build] 가 커맨드를 내는 상대.
class _Script implements Controller {
  _Script(this.build);

  final List<Command> Function(MatchState s) build;

  @override
  TurnBundle turnFor(MatchState state) => TurnBundle(
    turn: state.turn,
    side: state.activeSide,
    commands: build(state),
  );
}

/// 왼쪽(사람) [deck], 오른쪽(상대) [enemy]. 왼쪽이 선공인 시드를 찾는다.
BattleSession _session(
  List<String> deck,
  List<String> enemy, {
  Controller? opponent,
  bool humanFirst = true,
}) {
  for (var seed = 1; ; seed++) {
    final m = testSetup.newMatch(
      seed,
      deck: deck,
      enemyDeck: enemy,
      rules: const MatchRules(waveLevel: 0),
      costLimit: 20,
      enemyCostLimit: 20,
    );
    if ((m.state.activeSide == 0) != humanFirst) continue;
    return BattleSession(
      m,
      humanSides: const {0},
      speciesOf: testCatalog.speciesOf,
      opponent: opponent,
    );
  }
}

void _drain(BattleSession s) {
  var guard = 0;
  while (s.playback != null && guard++ < 2000) {
    s.update(50);
  }
}

void main() {
  group('비행 중 탭 (설계서 §2.2, §4.8)', () {
    test('컴퓨터가 낸 분열 TAP 은 화면 진행에서도 적용되어 리플레이와 해시가 같다', () {
      final s = _session(
        const ['p01_octo'],
        const ['p04_uni'],
        humanFirst: false,
        opponent: _Script(
          (_) => const [
            FireCommand(t: 500, slot: 0, angle: 45000, power: 9000),
            TapCommand(t: 500, slot: 0, ticks: 15),
            EndTurnCommand(t: 900),
          ],
        ),
      );
      final turn = s.state.turn;
      var guard = 0;
      while (s.state.turn == turn && guard++ < 4000) {
        s.update(50);
      }
      final log = s.match.turnLog;
      expect(log.first.commands.whereType<TapCommand>(), hasLength(1));
      final again = testSetup.newMatch(
        s.state.seed,
        deck: const ['p01_octo'],
        enemyDeck: const ['p04_uni'],
        rules: const MatchRules(waveLevel: 0),
        costLimit: 20,
        enemyCostLimit: 20,
      );
      log.forEach(again.playTurn);
      expect(hashMatchState(again.state), hashMatchState(s.state));
    });

    test('알바를 쏘면 탭을 기다리고, 탭하면 그 방향으로 꺾인다', () {
      final s = _session(const ['p29_alba'], const ['p01_octo'])
        ..update(500)
        ..fire(0, 30000, 9000);
      final shot = s.playback! as ShotPlayback;
      expect(shot.awaitingTap, isTrue);
      for (var i = 0; i < 6; i++) {
        s.update(50);
      }
      s.tap(dir: 1);
      expect((s.playback! as ShotPlayback).awaitingTap, isFalse);
      expect(
        s.state.events.where((e) => e.kind == SimEventKind.steered),
        hasLength(1),
      );
      expect(s.match.turnLog, isEmpty);
      _drain(s);
    });

    test('발사 바로 뒤 같은 해적의 TAP 만 함께 계산한다', () {
      final b = TurnBundle(
        turn: 1,
        side: 0,
        commands: const [
          FireCommand(t: 1, slot: 0, angle: 1, power: 1),
          TapCommand(t: 1, slot: 0, ticks: 3),
          FireCommand(t: 2, slot: 1, angle: 1, power: 1),
          TapCommand(t: 2, slot: 0, ticks: 3),
        ],
      );
      expect(followingTap(b, 0)?.ticks, 3);
      expect(followingTap(b, 2), isNull);
      expect(followingTap(b, 1), isNull);
    });
  });

  group('조준 (설계서 §2.2, §4.8)', () {
    test('보통은 0~85°, 지원 해적은 뒤쪽 175° 까지, 어뢰는 아래쪽까지 당길 수 있다', () {
      final c = testCatalog.pirates;
      expect(aimRangeFor(c.byId('p01_octo')), (0, 85000));
      expect(aimRangeFor(c.byId('p36_tok')), (0, 175000));
      expect(aimRangeFor(c.byId('p23_bara')), (-85000, 85000));
      // 위로 끌면(손가락 아래로 당기는 반대) 아래쪽으로 쏜다: 어뢰는 360° 에서 뺀 값.
      final torpedo = PullAim(facing: 1, minAngle: -85000)
        ..start()
        ..drag(-100, -20);
      expect(torpedo.shot.angle, greaterThan(300000));
      expect(shownDegrees(torpedo.shot.angle), lessThan(0));
      final normal = PullAim(facing: 1)
        ..start()
        ..drag(-100, -20);
      expect(normal.shot.angle, 0, reason: '보통 해적은 수평에서 막힌다');
      final support = PullAim(facing: 1, maxAngle: 175000)
        ..start()
        ..drag(60, 100);
      expect(support.shot.angle, greaterThan(90000), reason: '뒤쪽으로 넘어간다');
    });

    test('궤적 점선 비율: 봉쇄 0% > 램프 100% > 망루·조준경 50% > 기본', () {
      final s = _session(const ['p08_bones', 'p01_octo'], const ['p01_octo']);
      final me = s.state.sides[0];
      expect(trailPercentFor(me, 1, base: 20), 20);
      expect(trailPercentFor(me, 0, base: 20), 50, reason: '본즈 조준경');
      me.status.trailBoostTurn = me.turnNow;
      expect(trailPercentFor(me, 1, base: 20), 100);
      me.status.trailBlockTurn = me.turnNow;
      expect(trailPercentFor(me, 1, base: 20), 0);
    });

    test('아래쪽 각도는 음수 도로 보인다', () {
      expect(shownDegrees(350000), -10);
      expect(shownDegrees(45000), 45);
    });
  });

  test('고유 능력 이름표: 상태·지원 효과는 이름표가 있고, 없는 능력은 null', () {
    expect(HitTag.ofAbility(Ability.sealCabin), HitTag.seal);
    expect(HitTag.ofAbility(Ability.bail), HitTag.bail);
    expect(HitTag.ofAbility(Ability.lantern), HitTag.boost);
    expect(HitTag.ofAbility(Ability.twin), isNull);
  });

  testWidgets('불·방벽·떠 있는 기뢰·봉쇄가 걸린 전장과 새 이벤트 연출이 오류 없이 돈다', (
    tester,
  ) async {
    rootBundle.clear();
    await tester.runAsync(() async {
      final s = _session(
        const ['p02_starry', 'p01_octo'],
        const ['p01_octo', 'p36_tok'],
      );
      final game = BattleGame(s)..onGameResize(Vector2(960, 440));
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      await game.load();
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      game.mount();
      // ignore: cascade_invocations, mount 은 위의 ignore 가 필요해 캐스케이드로 못 묶는다.
      game.update(0);
      await game.ready();
      final enemy = s.state.sides[1];
      final grid = enemy.grid;
      final cells = [
        for (var i = 0; i < grid.cellCount; i++)
          if (grid.hasBlockAt(i)) i,
      ];
      enemy
        ..fireTurns[cells.last] = 2
        ..fireTurns[cells[cells.length - 2]] = 1;
      enemy.status
        ..sealTurn = s.state.turn + 1
        ..sealedSlot = 0
        ..moveLockTurn = s.state.turn + 1;
      s.state.barriers.add(
        Barrier(owner: 0, x: 0, top: 4000, hp: 100, turnsLeft: 2),
      );
      s.state.effects.add(
        TurnEffect(
          kind: EffectKind.floatMine,
          owner: 0,
          ownerSlot: 0,
          target: 1,
          trigger: 0,
          turnsLeft: 2,
          spec: s.state.sides[0].crew.pirates[0].spec,
          x: enemy.bowX - 3000,
        ),
      );
      game.update(1 / 30);
      final fire = game.world.children
          .whereType<ShipView>()
          .last
          .children
          .whereType<FireView>()
          .single;
      expect(fire.burning, hasLength(2));
      enemy.fireTurns[cells.last] = 0;
      game.update(1 / 30);
      expect(fire.charred, contains(cells.last), reason: '꺼진 칸은 그을린다');
      game.cues.dispatch([
        for (final k in [
          SimEventKind.ignited,
          SimEventKind.burned,
          SimEventKind.chained,
          SimEventKind.statusApplied,
          SimEventKind.mineFloated,
          SimEventKind.steered,
          SimEventKind.supported,
          SimEventKind.intercepted,
          SimEventKind.barrierPlaced,
          SimEventKind.barrierHit,
          SimEventKind.revived,
          SimEventKind.healed,
        ])
          SimEvent(
            k,
            side: 1,
            slot: 0,
            cell: cells.last,
            x: 1000,
            y: 2000,
            value:
                k == SimEventKind.statusApplied || k == SimEventKind.supported
                ? Ability.sealCabin.index
                : 3,
          ),
      ]);
      for (var i = 0; i < 20; i++) {
        game.update(1 / 30);
      }
      final recorder = ui.PictureRecorder();
      game.render(Canvas(recorder));
      recorder.endRecording().dispose();
    });
  });
}
