import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/anim/rarity_fx.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/hit_stop.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/game/view/collapse_fx.dart';
import 'package:pirate_busters/game/view/effect_badges.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

import 'test_catalog.dart';

void main() {
  group('명중 연출 (설계서 §10.4)', () {
    test('히트스톱: 명중 뒤 정한 시간만 연출 dt 가 0 이고 그 뒤에는 그대로 흐른다', () {
      final stop = HitStop();
      expect(stop.visualDt(0.016), 0.016, reason: '명중 전에는 멈추지 않는다');
      stop.trigger(0.1);
      var frozen = 0.0;
      var dt = stop.visualDt(0.016);
      while (dt == 0) {
        frozen += 0.016;
        dt = stop.visualDt(0.016);
      }
      expect(frozen, closeTo(0.1, 0.02));
      expect(dt, 0.016);
    });

    test('연사탄처럼 잇달아 맞아도 0.3초 안에는 더 큰 한 방이 아니면 다시 멈추지 않는다', () {
      final stop = HitStop()..trigger(0.05);
      for (var i = 0; i < 6; i++) {
        stop.visualDt(0.016);
      }
      stop.trigger(0.05);
      expect(stop.visualDt(0.016), 0.016);
      stop.trigger(0.12, heavy: true);
      expect(stop.trembling, isTrue, reason: '묵직한 한 방은 멈춘 동안 떨린다');
      expect(stop.visualDt(0.016), 0, reason: '더 큰 한 방은 간격 안이어도 멈춘다');
      for (var i = 0; i < 20; i++) {
        stop.visualDt(0.016);
      }
      expect(stop.trembling, isFalse);
      stop.trigger(0.05);
      expect(stop.visualDt(0.016), 0);
    });

    test('명중 때 카메라가 빠르게 당겼다가 부드럽게 돌아온다', () {
      final c = CameraDirector();
      expect(c.punchScale, 1);
      c
        ..impact(Vector2(300, -40), punch: 0.1)
        ..update(CameraDirector.punchIn, (Vector2.zero(), 900));
      expect(c.punchScale, closeTo(0.9, 1e-9), reason: '가장 많이 당긴 순간');
      c.update(CameraDirector.punchOut / 2, (Vector2.zero(), 900));
      expect(c.punchScale, inExclusiveRange(0.9, 1));
      expect(c.punchScale, greaterThan(1 - 0.1 / 2), reason: '풀림은 처음에 빠르다');
      c.update(CameraDirector.punchOut, (Vector2.zero(), 900));
      expect(c.punchScale, 1);
      // 물에 떨어진 탄은 줌을 당기지 않는다.
      c.impact(Vector2(300, 0));
      expect(c.punchScale, 1);
    });

    test('약한 한 방은 이미 당긴 큰 줌을 덮어쓰지 않는다', () {
      final c = CameraDirector()
        ..impact(Vector2.zero(), punch: 0.12)
        ..update(CameraDirector.punchIn, (Vector2.zero(), 900))
        ..impact(Vector2.zero(), punch: 0.04);
      expect(c.punchScale, closeTo(0.88, 1e-9));
    });

    test('지원탄·설치탄은 선체에 닿아도 명중 연출 없이 조용히 내려앉는다', () {
      PirateSpec spec(String id) => testCatalog.pirates.byId(id);
      expect(BattleCues.landsQuietly(spec('p36_tok')), isTrue, reason: '지원');
      expect(BattleCues.landsQuietly(spec('p21_puffy')), isTrue, reason: '설치');
      expect(BattleCues.landsQuietly(spec('p01_octo')), isFalse);
      expect(BattleCues.landsQuietly(spec('p31_sharky')), isFalse);
      // 턴 효과로 터진 것(쏜 해적 없음)은 폭발로 그린다.
      expect(BattleCues.landsQuietly(null), isFalse);
    });

    test('특별한 결과만 이름표가 붙는다: 저격 치명, 관통, 연쇄 …', () {
      expect(HitTag.ofAmmo(AmmoType.sniper), HitTag.crit);
      expect(HitTag.ofAmmo(AmmoType.pierce), HitTag.pierce);
      expect(HitTag.ofAmmo(AmmoType.chain), HitTag.chain);
      expect(HitTag.ofAmmo(AmmoType.mine), HitTag.mine);
      expect(HitTag.ofAmmo(AmmoType.assault), HitTag.bite);
      expect(HitTag.ofAmmo(AmmoType.support), HitTag.repair);
      expect(HitTag.ofAmmo(AmmoType.explosive), isNull);
      expect(HitTag.ofAmmo(AmmoType.split), isNull);
    });
  });

  testWidgets('붕괴 (§10.4): 끊긴 덩어리는 삐걱인 뒤 기울며 떨어지고 수면에서 물보라를 낸다', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawPaint(ui.Paint());
      final image = await recorder.endRecording().toImage(8, 8);
      Vector2? splashAt;
      final piece = FallingPiece(
        parts: [
          PiecePart(Sprite(image), Vector2(-16, 0), Vector2.all(32)),
          PiecePart(Sprite(image), Vector2(16, 0), Vector2.all(32)),
        ],
        at: Vector2(100, -96),
        velocity: Vector2(30, 0),
        spin: collapseSpin(2),
        delay: collapseStagger,
        onSplash: (at) => splashAt = at,
      );
      expect(piece.size, Vector2(64, 32), reason: '두 칸 덩어리 크기');
      piece.update(collapseStagger / 2);
      expect(piece.position, Vector2(100, -96), reason: '늦게 떨어지는 덩어리는 제자리');
      var steps = 0;
      while (splashAt == null && steps < 200) {
        piece.update(1 / 60);
        steps++;
      }
      expect(splashAt, isNotNull);
      expect(splashAt!.y, 0, reason: '해수면');
      expect(splashAt!.x, greaterThan(100), reason: '기운 쪽으로 밀려 떨어진다');
      expect(piece.angle, greaterThan(0));
    });
  });

  group('파괴 조각·덩어리 묶기 (설계서 §10.4, A32)', () {
    test('나무는 가로 판자 세 장, 철판은 네 조각, 저사양은 절반이다', () {
      expect(shardPlan(7, iron: false), hasLength(3));
      expect(shardPlan(7, iron: true), hasLength(4));
      expect(shardPlan(7, iron: false, fewer: true), hasLength(2));
      expect(shardPlan(7, iron: true, fewer: true), hasLength(2));
      for (final s in shardPlan(7, iron: false)) {
        expect(s.src.width, 1, reason: '판자는 결을 따라 가로로 갈라진다');
        expect(s.velocity.y, lessThan(0), reason: '위로 튄다');
      }
    });

    test('같은 칸이면 같은 조각이고, 착탄 반대쪽으로 더 튄다', () {
      final a = shardPlan(1203, iron: false, away: 1);
      final b = shardPlan(1203, iron: false, away: 1);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].velocity, b[i].velocity);
        expect(a[i].spin, b[i].spin);
      }
      double meanX(List<ShardSpec> p) =>
          p.map((s) => s.velocity.x).reduce((x, y) => x + y) / p.length;
      expect(
        meanX(shardPlan(5, iron: true, away: 1)),
        greaterThan(meanX(shardPlan(5, iron: true, away: -1))),
      );
    });

    test('끊긴 칸은 이웃끼리 한 덩어리로 묶이고 아래 덩어리가 먼저다', () {
      // 폭 5 격자: 0·1 이 붙어 있고, 3 과 8(= 3 의 위)이 붙어 있다. 4 와 5 는 줄이
      // 달라 이웃이 아니다.
      expect(groupCells([8, 1, 3, 0], 5), [
        [0, 1],
        [3, 8],
      ]);
      expect(groupCells([4, 5], 5), [
        [4],
        [5],
      ]);
      expect(groupCells(const [], 5), isEmpty);
      expect(
        collapseSpin(4),
        lessThan(collapseSpin(1)),
        reason: '큰 덩어리는 천천히 기운다',
      );
    });
  });

  testWidgets('계열이 다른 해적 여덟을 쏘아도 명중·배지·붕괴 연출이 오류 없이 돈다', (tester) async {
    const decks = [
      ['p01_octo', 'p06_pang', 'p11_finn', 'p16_suri'],
      ['p21_puffy', 'p31_sharky', 'p36_tok', 'p28_pelly'],
    ];
    for (final deck in decks) {
      rootBundle.clear();
      await tester.runAsync(() async {
        BattleSession? session;
        for (final seed in [1, 2, 3, 4, 5, 6, 7, 8]) {
          final s = BattleSession(
            testSetup.newMatch(seed, deck: deck, costLimit: 99),
            humanSides: const {0},
            speciesOf: testCatalog.speciesOf,
            opponent: const AiController(level: AiLevel.easy),
          );
          if (s.isHumanTurn) {
            session = s;
            break;
          }
        }
        expect(session, isNotNull);
        final game = BattleGame(session!)..onGameResize(Vector2(960, 440));
        // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
        // ignore: invalid_use_of_internal_member
        await game.load();
        // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
        // ignore: invalid_use_of_internal_member
        game.mount();
        // ignore: cascade_invocations, mount 은 위의 ignore 가 필요해 캐스케이드로 못 묶는다.
        game.update(0);
        await game.ready();
        final ship = game.world.children.whereType<ShipView>().first;
        // 무너지는 덩어리 그림: 블록이 있던 칸은 타일, 빈 칸은 없다.
        final cabin = session.state.sides[0].cabins.first;
        final width = session.state.sides[0].grid.width;
        expect(ship.builtTile(cabin.y * width + cabin.x), isNotNull);
        expect(ship.builtTile(-1), isNull);
        // 계열 8개의 명중 모양과 등급 연출을 한 번씩 띄운다 (§10.4, §10.5).
        final fx = game.world.children.whereType<FxLayer>().single;
        const legend = RarityTier(
          color: Color(0xFFFFC83A),
          hi: Color(0xFFFFF6C8),
          aura: 2,
          ring: 2,
          shards: 10,
          shake: 1.15,
        );
        for (final family in Family.values) {
          fx
            ..hit(Vector2(0, -40), family, tier: legend)
            ..hit(Vector2(0, -40), family, tier: legend, facing: -1);
        }
        expect(fx.shake, 0, reason: '흔들림은 명중 모양이 아니라 한 방 크기가 정한다');
        fx.repair(Vector2(0, -40), tier: legend);
        final rest = ship.angle;
        ship.rock(1);
        game.update(1 / 30);
        expect(ship.angle, isNot(rest), reason: '맞은 방향으로 흔들린다');
        // 해적마다 한 발씩: 쏠 수 있을 때만 쏘고 몇 초 돌린다.
        var shots = 0;
        for (var slot = 0; slot < deck.length; slot++) {
          if (session.isHumanTurn && session.canFire(slot)) {
            session.fire(slot, 38000, 8200);
          }
          var flying = false;
          for (var i = 0; i < 150; i++) {
            game.update(1 / 30);
            flying |= session.playback != null;
          }
          if (flying) shots++;
          final recorder = ui.PictureRecorder();
          game.render(ui.Canvas(recorder));
          recorder.endRecording().dispose();
        }
        expect(shots, greaterThanOrEqualTo(2), reason: '$deck');
        // 남은 턴 수 배지 (§10.4): 설치탄은 붙은 칸에, 투하는 표시한 곳 위에 뜬다.
        final spec = session.state.sides[0].crew.pirates[0].spec;
        final enemy = session.state.sides[1];
        final cell =
            enemy.cabins.first.y * enemy.grid.width + enemy.cabins.first.x;
        TurnEffect effect(EffectKind kind, {int cell = -1, int x = 0}) =>
            TurnEffect(
              kind: kind,
              owner: 0,
              ownerSlot: 0,
              target: 1,
              trigger: 0,
              turnsLeft: 2,
              spec: spec,
              cell: cell,
              x: x,
            );
        final mine = effect(EffectKind.mineBlast, cell: cell);
        final drop = effect(EffectKind.flockDrop, x: 5 * cellUnit);
        session.state.effects.addAll([mine, drop]);
        final badges = game.world.children.whereType<EffectBadges>().single;
        final (cx, cy) = enemy.frame.cellCenter(
          enemy.cabins.first.x,
          enemy.cabins.first.y,
        );
        expect(badges.positionOf(mine), Coords.point(cx, cy));
        expect(badges.positionOf(drop).x, Coords.x(5 * cellUnit));
        expect(badges.positionOf(drop).y, -EffectBadges.dropHeight);
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        recorder.endRecording().dispose();
      });
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('리플레이 해시는 연출 유무와 무관하게 같다 (완료 조건, 절대 규칙 3)', (tester) async {
    BattleSession start() => BattleSession(
      testSetup.newMatch(
        3,
        deck: const ['p04_uni', 'p06_pang', 'p11_finn', 'p36_tok'],
        costLimit: 99,
      ),
      humanSides: const {0},
      speciesOf: testCatalog.speciesOf,
      opponent: const AiController(level: AiLevel.easy),
    );
    // 같은 걸음에 같은 커맨드를 넣는다: 내 턴이면 쏠 수 있는 해적이 한 발 쏜다.
    void act(BattleSession s, int step) {
      if (step % 90 != 0 || !s.isHumanTurn || s.playback != null) return;
      for (var slot = 0; slot < 4; slot++) {
        if (s.canFire(slot)) {
          s.fire(slot, 40000, 8000);
          return;
        }
      }
    }

    const steps = 900;
    final plain = start();
    for (var i = 0; i < steps; i++) {
      act(plain, i);
      plain
        ..update(33)
        ..takeCues();
    }
    final shown = start();
    rootBundle.clear();
    await tester.runAsync(() async {
      final game = BattleGame(shown)..onGameResize(Vector2(960, 440));
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      await game.load();
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      game.mount();
      await game.ready();
      for (var i = 0; i < steps; i++) {
        act(shown, i);
        // 히트스톱·카메라·입자가 도는 전장. dt 0.033초 = 세션 33ms.
        game.update(0.033);
      }
    });
    expect(plain.state.turn, greaterThan(1), reason: '턴이 넘어갈 만큼 진행했다');
    expect(hashMatchState(shown.state), hashMatchState(plain.state));
    expect(tester.takeException(), isNull);
  });
}
