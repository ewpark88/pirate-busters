import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/game/view/fx_text.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';
import 'package:pirate_busters/game/view/shake.dart';
import 'package:pirate_busters/settings/settings_store.dart';

SimEvent ev(SimEventKind kind, {int value = 0}) =>
    SimEvent(kind, side: 1, value: value);

List<SimEvent> batch({
  int destroyed = 0,
  int collapsed = 0,
  int pirate = 0,
  bool down = false,
  ModuleKind? module,
}) => [
  ev(SimEventKind.impact),
  for (var i = 0; i < destroyed; i++) ev(SimEventKind.blockDestroyed),
  for (var i = 0; i < collapsed; i++) ev(SimEventKind.blockCollapsed),
  if (pirate > 0) ev(SimEventKind.pirateHit, value: pirate),
  if (down) ev(SimEventKind.pirateDown),
  if (module != null) ev(SimEventKind.moduleDestroyed, value: module.index),
];

void main() {
  group('한 방 크기 (설계서 §10.4, A32)', () {
    test('배에 맞은 착탄이 없으면 크기가 0 이다', () {
      expect(HitWeight.of([ev(SimEventKind.splash)]).score, 0);
      expect(HitWeight.of(const []).score, 0);
    });

    test('구멍만 낸 한 발은 가볍고, 여러 칸을 부수거나 해적을 쓰러뜨리면 묵직하다', () {
      expect(HitWeight.of(batch()).level, HitLevel.light);
      expect(HitWeight.of(batch(destroyed: 1)).level, HitLevel.light);
      expect(HitWeight.of(batch(destroyed: 2)).level, HitLevel.medium);
      expect(HitWeight.of(batch(pirate: 80)).level, HitLevel.medium);
      expect(HitWeight.of(batch(destroyed: 4)).level, HitLevel.heavy);
      expect(HitWeight.of(batch(pirate: 80, down: true)).level, HitLevel.heavy);
      expect(
        HitWeight.of(batch(module: ModuleKind.magazine)).level,
        HitLevel.medium,
      );
    });

    test('화약고·연료통만 유폭으로 세고 다른 모듈은 더하지 않는다', () {
      final plain = HitWeight.of(batch()).score;
      expect(
        HitWeight.of(batch(module: ModuleKind.fuelTank)).score,
        plain + 400,
      );
      expect(HitWeight.of(batch(module: ModuleKind.pump)).score, plain);
    });

    test('치명은 해적을 맞혔을 때만 더한다', () {
      expect(
        HitWeight.of(batch(pirate: 100), critHit: true).score,
        HitWeight.of(batch(pirate: 100)).score + HitWeight.crit,
      );
      expect(
        HitWeight.of(batch(), critHit: true).score,
        HitWeight.of(batch()).score,
      );
    });

    test('크기가 클수록 멈춤·흔들림·줌이 커지고 상한을 넘지 않는다', () {
      var last = HitWeight.of(batch());
      for (var n = 1; n <= 12; n++) {
        final w = HitWeight.of(batch(destroyed: n, pirate: n * 30));
        expect(w.score, greaterThanOrEqualTo(last.score));
        expect(w.hitStopSec, greaterThanOrEqualTo(last.hitStopSec));
        expect(w.trauma, greaterThanOrEqualTo(last.trauma));
        expect(w.punch, greaterThanOrEqualTo(last.punch));
        last = w;
      }
      expect(last.score, HitWeight.max);
      expect(last.hitStopSec, closeTo(0.16, 1e-9));
      expect(last.punch, closeTo(0.12, 1e-9));
      expect(HitWeight.of(batch()).hitStopSec, greaterThanOrEqualTo(0.05));
    });

    test('같은 이벤트면 같은 크기다', () {
      expect(
        HitWeight.of(batch(destroyed: 3, pirate: 55)).score,
        HitWeight.of(batch(destroyed: 3, pirate: 55)).score,
      );
    });
  });

  group('쌓이는 흔들림 (설계서 §10.4, A32)', () {
    test('흔들림은 충격량의 제곱이라 큰 한 방이 작은 한 방보다 훨씬 크다', () {
      final light = ScreenTrauma()..add(HitWeight.of(batch()).trauma);
      final heavy = ScreenTrauma()
        ..add(HitWeight.of(batch(destroyed: 5)).trauma);
      expect(heavy.amp(), greaterThan(light.amp() * 2));
    });

    test('연달아 맞으면 쌓이되 충격량 1 을 넘지 않고, 시간이 지나면 멈춘다', () {
      final t = ScreenTrauma();
      for (var i = 0; i < 5; i++) {
        t.add(0.6);
      }
      expect(t.value, 1);
      expect(t.amp(), ScreenTrauma.maxPx);
      expect(t.angle(0.3).abs(), lessThanOrEqualTo(ScreenTrauma.maxAngle));
      t.update(1);
      expect(t.value, lessThan(1));
      t.update(1);
      expect(t.amp(), 0);
    });

    test('흔들림 줄이기를 켜면 세기와 기울기가 줄어든다', () {
      final t = ScreenTrauma()..add(1);
      expect(t.amp(calm: true), t.amp() * ScreenTrauma.calmScale);
      expect(
        t.angle(0.21, calm: true),
        closeTo(t.angle(0.21) * ScreenTrauma.calmScale, 1e-12),
      );
    });

    test('물 착탄처럼 쌓지 않는 흔들림은 지금보다 작으면 바꾸지 않는다', () {
      final t = ScreenTrauma()
        ..add(0.8)
        ..atLeast(0.3);
      expect(t.value, 0.8);
    });
  });

  group('피해 숫자 단계 (설계서 §10.4, A32)', () {
    test('가벼운 한 방은 작은 흰 숫자, 큰 한 방은 큰 주황, 치명은 가장 큰 빨강이다', () {
      expect(DamageStyle.of(HitWeight.of(batch())), DamageStyle.small);
      expect(
        DamageStyle.of(HitWeight.of(batch(destroyed: 2))),
        DamageStyle.big,
      );
      expect(
        DamageStyle.of(HitWeight.of(batch()), crit: true),
        DamageStyle.crit,
      );
      expect(DamageStyle.big.fontSize, greaterThan(DamageStyle.small.fontSize));
      expect(DamageStyle.crit.fontSize, greaterThan(DamageStyle.big.fontSize));
      expect(DamageStyle.small.wobbles, isFalse);
      expect(DamageStyle.big.wobbles, isTrue);
    });
  });

  test('화면 흔들림 줄이기는 기본 꺼짐이고 켜면 설정에 남는다 (설계서 §13.8)', () async {
    final store = MemorySettingsStore();
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    expect(c.read(calmShakeProvider), isFalse);
    await c.read(calmShakeProvider.notifier).set(on: true);
    expect(c.read(calmShakeProvider), isTrue);
    expect(store.calmShake, isTrue);
  });
}
