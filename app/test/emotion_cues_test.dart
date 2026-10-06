import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/game/emotion_cues.dart';
import 'package:pirate_busters/game/hit_stop.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';

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
}
