import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sfx_bank.dart';
import 'package:pirate_busters/audio/shanty_music.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/battle_cues.dart';
import 'package:pirate_busters/game/view/explosion_fx.dart';
import 'package:pirate_busters/game/view/ship_motion.dart';
import 'package:pirate_busters/game/view/water_fx.dart';
import 'package:pirate_busters/settings/settings_store.dart';

import 'test_catalog.dart';

void main() {
  group('폭발 (설계서 §10.4, A13)', () {
    test('불덩이 그림은 뜨거움 → 불 → 식음 → 속불 연기 → 연기 순으로 한 번씩 바뀐다', () {
      final frames = [
        for (var t = 0.0; t < Fireball.life; t += .01) Fireball.frameAt(t),
      ];
      expect(frames.first, 0);
      expect(frames.last, ExplosionFx.fireballFrames.length - 1);
      for (var i = 1; i < frames.length; i++) {
        expect(frames[i] - frames[i - 1], inInclusiveRange(0, 1));
      }
      expect(frames.toSet(), {0, 1, 2, 3, 4});
    });

    test('불덩이는 빠르게 커지고 0.4초부터 흐려져 수명 끝에 사라진다', () {
      expect(Fireball.scaleAt(.1), greaterThan(Fireball.scaleAt(0) + .4));
      expect(Fireball.scaleAt(.5), greaterThan(Fireball.scaleAt(.3)));
      expect(Fireball.alphaAt(.2), 1);
      expect(Fireball.alphaAt(Fireball.life), 0);
      expect(Fireball.alphaAt(.5), inExclusiveRange(0, 1));
    });

    test('화약고·연료통만 유폭한다', () {
      expect(
        BattleCues.blastRadius(ModuleKind.magazine.index),
        ModuleNumbers.magazineRadius,
      );
      expect(
        BattleCues.blastRadius(ModuleKind.fuelTank.index),
        ModuleNumbers.fuelTankRadius,
      );
      expect(BattleCues.blastRadius(ModuleKind.pump.index), 0);
    });
  });

  test('턴 끝 침수가 늘 때만 물방울이 튀고, 펌프로 줄면 튀지 않는다 (설계서 §10.4)', () {
    expect(BattleCues.floodRose(12), isTrue);
    expect(BattleCues.floodRose(0), isFalse);
    expect(BattleCues.floodRose(-40), isFalse);
  });

  group('격침 (설계서 §10.4)', () {
    test('격침·침수 격침으로 끝난 판만 배가 가라앉는다', () {
      expect(isSinkOutcome(MatchOutcome.sunk), isTrue);
      expect(isSinkOutcome(MatchOutcome.floodSunk), isTrue);
      expect(isSinkOutcome(MatchOutcome.annihilation), isFalse);
      expect(isSinkOutcome(MatchOutcome.timeDecision), isFalse);
      expect(isSinkOutcome(MatchOutcome.surrender), isFalse);
    });

    test('가라앉기는 부드럽게 깊어지고 다 가라앉아야 결과 창을 띄운다', () {
      final m = ShipMotion();
      expect(m.settled, isTrue, reason: '가라앉지 않는 배는 기다리지 않는다');
      m.startSink();
      expect(m.settled, isFalse);
      var last = 0.0;
      for (var i = 0; i < 30; i++) {
        m.update(.1);
        expect(m.depth, greaterThanOrEqualTo(last));
        last = m.depth;
      }
      expect(m.settled, isTrue);
      expect(m.depth, ShipMotion.sinkDepth);
      expect(m.extraTilt(-1), -ShipMotion.sinkTilt);
      // 다시 불러도 처음부터 다시 가라앉지 않는다.
      m.startSink();
      expect(m.depth, ShipMotion.sinkDepth);
    });
  });

  group('침수 거품 (설계서 §10.4)', () {
    test('물이 새는 칸이 없으면 거품도 없고, 흘수선 아래 구멍 칸에서만 고르게 돌아가며 난다', () {
      final side = testSetup.newMatch(3).state.sides[0];
      expect(WaterFx.bubbleCells(side, 0, 2), isEmpty);
      // 용골 줄(y = 0, 늘 물속) 두 칸을 구멍 단계로 만든다.
      final grid = side.grid;
      final xs = [
        for (var x = 0; x < grid.width; x++)
          if (grid.hasBlock(x, 0)) x,
      ].take(3).toList();
      for (final x in xs) {
        grid.damage(x, 0, grid.hpAt(x, 0) * 4 ~/ 5);
      }
      final leaks = <(int, int)>{};
      forEachSubmergedLeak(side, (x, y, _) => leaks.add((x, y)));
      expect(leaks, isNotEmpty);
      for (var tick = 0; tick < 6; tick++) {
        final cells = WaterFx.bubbleCells(side, tick, 2);
        expect(cells.length, lessThanOrEqualTo(2));
        expect(leaks.containsAll(cells), isTrue);
      }
      // 여러 번 돌면 새는 칸이 모두 한 번씩은 거품을 낸다.
      final seen = {
        for (var tick = 0; tick < leaks.length; tick++)
          ...WaterFx.bubbleCells(side, tick, 2),
      };
      expect(seen, leaks);
    });
  });

  group('소리 (설계서 §10.3, ADR-068)', () {
    test('새 효과음(유폭·격침·승패 악구·버튼)도 만들어지고 같은 바이트가 나온다', () {
      for (final s in Sfx.values) {
        final a = SfxBank.wav(s);
        expect(a.length, greaterThan(44), reason: s.name);
        expect(SfxBank.wav(s), a, reason: '${s.name} 결정적');
      }
    });

    test('배경음악은 항구·전투 두 곡이고, 몇 초 길이의 루프가 늘 같은 바이트로 나온다', () {
      final all = ShantyMusic.build();
      expect(all.keys, Music.values);
      for (final m in Music.values) {
        final wav = all[m]!;
        // 22050Hz 16비트 모노: 4초 ~ 20초.
        final seconds = (wav.length - 44) / (22050 * 2);
        expect(seconds, inInclusiveRange(4, 20), reason: m.name);
        expect(ShantyMusic.wav(m), wav, reason: '${m.name} 결정적');
      }
    });

    test('음악 켜기 설정은 기본 켬이고 끈 값을 기억한다', () async {
      final store = MemorySettingsStore();
      expect(store.music, isTrue);
      await store.setMusic(on: false);
      expect(store.music, isFalse);
    });
  });
}
