import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/emotion_cues.dart';
import 'package:pirate_busters/game/hit_stop.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';

import 'test_catalog.dart';

void main() {
  group('감정 연출 강조 문구 (설계서 §10.4, A32)', () {
    const light = HitWeight(200);
    const heavy = HitWeight(800);

    test('선실 직격이 가장 앞이고 그다음 큰 피해다', () {
      final t = EmotionTracker()..turnStart(1);
      expect(t.onBatch(heavy, cabinHit: true), Emphasis.cabin);
      t.turnStart(2);
      expect(t.onBatch(heavy, cabinHit: false), Emphasis.boom);
    });

    test('돛대가 부러지면 선실 직격 다음, 큰 피해보다 앞서 돛대 문구를 띄운다 (A30)', () {
      expect(
        (EmotionTracker()..turnStart(1)).onBatch(
          heavy,
          cabinHit: false,
          mastBroken: true,
        ),
        Emphasis.mast,
      );
      expect(
        (EmotionTracker()..turnStart(1)).onBatch(
          light,
          cabinHit: true,
          mastBroken: true,
        ),
        Emphasis.cabin,
      );
      expect(
        (EmotionTracker()..turnStart(1)).onBatch(
          HitWeight.none,
          cabinHit: false,
          mastBroken: true,
        ),
        Emphasis.mast,
        reason: '피해가 작아도 돛대가 부러지면 띄운다',
      );
    });

    test('같은 턴 두 번째 명중에 연속 명중을 띄운다', () {
      final t = EmotionTracker()..turnStart(1);
      expect(t.onBatch(light, cabinHit: false), isNull);
      expect(t.onBatch(HitWeight.none, cabinHit: false), isNull, reason: '빗나감');
      expect(t.onBatch(light, cabinHit: false), Emphasis.doubleHit);
    });

    test('한 턴에 문구는 하나만 띄우고 새 턴에 다시 띄운다', () {
      final t = EmotionTracker()..turnStart(1);
      expect(t.onBatch(heavy, cabinHit: false), Emphasis.boom);
      expect(t.onBatch(heavy, cabinHit: true), isNull);
      t.turnStart(2);
      expect(t.onBatch(light, cabinHit: true), Emphasis.cabin);
    });

    test('같은 순서면 같은 문구다', () {
      List<Emphasis?> run() {
        final t = EmotionTracker()..turnStart(1);
        return [
          t.onBatch(light, cabinHit: false),
          t.onBatch(light, cabinHit: false),
          t.onBatch(heavy, cabinHit: true),
        ];
      }

      expect(run(), run());
    });
  });

  group('슬로모션 (설계서 §10.4, A32)', () {
    test('정한 시간만 연출이 느리게 흐르고 시간이 지나면 돌아온다', () {
      final stop = HitStop()..slow(0.6);
      expect(stop.slowing, isTrue);
      var shown = 0.0;
      var real = 0.0;
      while (stop.slowing) {
        shown += stop.visualDt(0.016);
        real += 0.016;
      }
      expect(real, closeTo(0.6, 0.02));
      expect(shown, closeTo(0.6 * HitStop.slowScale, 0.01));
      expect(stop.visualDt(0.016), 0.016);
    });

    test('멈춤이 먼저 끝난 뒤 느려진다', () {
      final stop = HitStop()
        ..trigger(0.1)
        ..slow(0.3);
      expect(stop.visualDt(0.05), 0);
      expect(stop.visualDt(0.05), 0);
      expect(stop.visualDt(0.05), closeTo(0.05 * HitStop.slowScale, 1e-9));
    });
  });

  testWidgets('지원탄·설치탄이 선실에 내려앉아도 슬로모션·강조 문구를 내지 않는다', (tester) async {
    rootBundle.clear();
    await tester.runAsync(() async {
      final session = BattleSession(
        testSetup.newMatch(3),
        humanSides: const {0},
        speciesOf: testCatalog.speciesOf,
        opponent: const AiController(level: AiLevel.easy),
      );
      final game = BattleGame(session)..onGameResize(Vector2(960, 440));
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      await game.load();
      // 같은 이유로 내부 수명 주기를 직접 부른다.
      // ignore: invalid_use_of_internal_member
      game.mount();
      // ignore: cascade_invocations, mount 은 위의 ignore 가 필요해 캐스케이드로 못 묶는다.
      game.update(0);
      await game.ready();
      final me = session.state.sides[0];
      final cabin = me.cabins.first;
      final cell = cabin.y * me.grid.width + cabin.x;
      final landed = [
        SimEvent(SimEventKind.impact, side: 0, cell: cell, y: 2000),
      ];
      final cues = game.cues..emote(landed, const HitWeight(800), quiet: true);
      expect(cues.stop.slowing, isFalse, reason: '조용히 내려앉는 탄');
      cues.emote(landed, const HitWeight(800));
      expect(cues.stop.slowing, isTrue, reason: '보통 탄의 선실 직격');
      session.dispose();
    });
  });
}
