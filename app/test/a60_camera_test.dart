import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/game/camera_motion.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/input/field_gestures.dart';

import 'test_catalog.dart';

/// 기본 배치: 내 배 −900, 상대 배 900, 내 배가 오른쪽을 본다.
(Vector2, double) _goal(
  CameraDirector c, {
  Vector2? shot,
  int anchor = 0,
}) => c.target(
  myX: -900,
  enemyX: 900,
  facing: 1,
  projectile: shot,
  anchor: anchor,
);

/// [frames] 프레임(1/60초)을 돌린다.
void _run(CameraDirector c, int frames, {Vector2? shot, int anchor = 0}) {
  for (var i = 0; i < frames; i++) {
    c.update(1 / 60, _goal(c, shot: shot, anchor: anchor));
  }
}

void main() {
  group('탄 추적 카메라 (설계서 §2.1, A60)', () {
    test('스프링은 목표를 넘치지 않고 다가가며 오래 지나면 목표에 닿는다', () {
      final s = CameraSpring();
      var v = 0.0;
      for (var i = 0; i < 600; i++) {
        v = s.step(v, 100, 6, 1 / 60);
        expect(v, lessThanOrEqualTo(100 + 1e-9));
      }
      expect(v, closeTo(100, 1e-6));
    });

    test('쏜 순간에는 화면이 휙 잡아채지 않고 서서히 붙는다', () {
      final c = CameraDirector();
      _run(c, 300);
      final before = c.center.x;
      final shot = Vector2(before + 300, -100);
      c.update(1 / 60, _goal(c, shot: shot));
      final first = (c.center.x - before).abs();
      // 옛 1차 추종(rate 12)은 첫 프레임에 거리의 18% 를 움직였다.
      expect(first, lessThan(300 * 0.05));
      _run(c, 120, shot: shot);
      expect(
        (c.center.x - shot.x).abs(),
        lessThan(CameraDirector.baseWidth / 4),
      );
    });

    test('목표 화면이 바뀌어도 속도가 이어져 한 프레임에 크게 꺾이지 않는다', () {
      final c = CameraDirector();
      var shot = Vector2(-700, -100);
      final steps = <double>[];
      for (var i = 0; i < 90; i++) {
        shot = Vector2(shot.x + 12, -100);
        final x = c.center.x;
        c.update(1 / 60, _goal(c, shot: shot));
        steps.add(c.center.x - x);
      }
      // 탄이 사라지고 착탄 화면으로 바뀐다.
      c.impact(Vector2(shot.x, -40));
      for (var i = 0; i < 10; i++) {
        final x = c.center.x;
        c.update(1 / 60, _goal(c));
        steps.add(c.center.x - x);
      }
      for (var i = 1; i < steps.length; i++) {
        expect((steps[i] - steps[i - 1]).abs(), lessThan(8), reason: '$i');
      }
    });

    test('탄이 오르내려도 화면 높이는 탄보다 덜 움직인다', () {
      final c = CameraDirector();
      _run(c, 60, shot: Vector2(-600, -80));
      final y0 = c.center.y;
      _run(c, 10, shot: Vector2(-600, -400));
      expect((c.center.y - y0).abs(), lessThan(320 * 0.6));
    });

    test('날아가는 쪽으로 앞을 비워 탄은 화면 가운데보다 조금 뒤에 온다', () {
      final c = CameraDirector();
      var shot = Vector2(-700, -100);
      for (var i = 0; i < 60; i++) {
        shot = Vector2(shot.x + 10, -100);
        c.update(1 / 60, _goal(c, shot: shot));
      }
      final (goal, w) = _goal(c, shot: shot);
      expect(goal.x, greaterThan(shot.x));
      expect(
        goal.x - shot.x,
        lessThanOrEqualTo(CameraDirector.shotLeadMax * w),
      );
    });
  });

  group('빈 바다 끌어 보기 (설계서 §2.1, A60)', () {
    test('끌면 기본 화면이 옮겨 가고 두 배 뒤 바다 끝(6칸 여백)을 넘지 않는다 (설계서 §2.5)', () {
      final c = CameraDirector();
      final (base, _) = _goal(c);
      c.panBy(600);
      expect(_goal(c).$1.x, base.x + 600);
      c.panBy(5000);
      expect(_goal(c).$1.x, 900 + 6 * Coords.cell);
      c.panBy(-20000);
      expect(_goal(c).$1.x, -900 - 6 * Coords.cell);
    });

    test('손을 떼고 잠시 지나면 내 배 화면으로 돌아온다', () {
      final c = CameraDirector()..panBy(400);
      _run(c, 1);
      c.pan.dragging = false;
      _run(c, ((CameraPan.returnDelay - 0.2) * 60).round());
      expect(c.pan.x, isNot(0));
      _run(c, 30);
      expect(c.pan.x, 0);
    });

    test('끄는 동안은 돌아오지 않는다', () {
      final c = CameraDirector()..panBy(400);
      _run(c, 400);
      expect(c.pan.x, 400);
    });

    test('해적을 고르거나 쏘거나 턴이 바뀌면 끌기가 풀린다', () {
      final c = CameraDirector();
      _run(c, 1);
      c.panBy(400);
      _run(c, 1, anchor: 1);
      expect(c.pan.x, 0, reason: '턴 전환');
      c.panBy(400);
      _run(c, 1, anchor: 1, shot: Vector2(-600, -100));
      expect(c.pan.x, 0, reason: '발사');
      _run(c, 1, anchor: 1);
      c
        ..panBy(400)
        ..focusFeet = Vector2(-900, -40);
      _run(c, 1, anchor: 1);
      expect(c.pan.x, 0, reason: '해적 고르기');
    });

    test('탄이 나는 동안·착탄 연출 중에는 끌어도 옮기지 않는다', () {
      final c = CameraDirector();
      _run(c, 1, shot: Vector2(-600, -100));
      c.panBy(300);
      expect(c.pan.x, 0);
      c.impact(Vector2(800, -40));
      _run(c, 1);
      c.panBy(300);
      expect(c.pan.x, 0);
    });
  });

  group('전장 제스처 (설계서 §2.1·§2.2, A60)', () {
    Future<(BattleGame, BattleSession)> pumpField(WidgetTester tester) async {
      final session = BattleSession(
        testSetup.newMatch(7),
        humanSides: const {0, 1},
        speciesOf: testCatalog.speciesOf,
      );
      rootBundle.clear();
      late BattleGame game;
      await tester.runAsync(() async {
        game = BattleGame(session)..onGameResize(Vector2(960, 440));
        // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
        // ignore: invalid_use_of_internal_member
        await game.load();
        // 위와 같은 내부 수명 주기 호출이다.
        // ignore: invalid_use_of_internal_member
        game.mount();
        // ignore: cascade_invocations, mount 은 위의 ignore 가 필요해 캐스케이드로 못 묶는다.
        game.update(0);
        await game.ready();
        for (var i = 0; i < 30; i++) {
          game.update(1 / 20);
        }
      });
      tester.view.physicalSize = const Size(960, 440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FieldGestures(
            game: game,
            session: session,
            child: const SizedBox.expand(),
          ),
        ),
      );
      return (game, session);
    }

    testWidgets('빈 하늘을 끌면 화면이 옮겨 가고 조준은 시작되지 않는다', (tester) async {
      final (game, session) = await pumpField(tester);
      game.update(1 / 60);
      await tester.dragFrom(const Offset(480, 20), const Offset(-200, 0));
      expect(game.director.pan.x, greaterThan(0), reason: '왼쪽으로 끌면 오른쪽을 본다');
      expect(game.director.pan.dragging, isFalse);
      expect(session.aim, isNull);
    });

    testWidgets('핀치하다 한 손가락만 떼면 남은 손가락으로 조준·끌기가 시작되지 않는다', (tester) async {
      final (game, session) = await pumpField(tester);
      final a = await tester.startGesture(const Offset(400, 40), pointer: 7);
      final b = await tester.startGesture(const Offset(560, 40), pointer: 8);
      await a.moveBy(const Offset(-40, 0));
      await b.moveBy(const Offset(40, 0));
      await tester.pump();
      await b.up();
      await a.moveBy(const Offset(-150, 0));
      await tester.pump();
      expect(game.director.pan.x, 0);
      expect(session.aim, isNull);
      await a.up();
    });
  });
}
