import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/audio/sfx_bank.dart';
import 'package:pirate_busters/audio/shanty_music.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/game/view/blast_glow.dart';
import 'package:pirate_busters/game/view/blast_sheet.dart';
import 'package:pirate_busters/settings/settings_store.dart';

void main() {
  group('폭발 (설계서 §10.4, A13·S4)', () {
    test('폭발 시트는 프레임을 처음부터 끝까지 한 장씩 차례로 넘긴다', () {
      for (final sheet in BlastSheet.all) {
        final frames = [
          for (var t = 0.0; t < sheet.life; t += .005) sheet.frameAt(t),
        ];
        expect(frames.first, 0, reason: sheet.file);
        expect(frames.last, sheet.count - 1, reason: sheet.file);
        for (var i = 1; i < frames.length; i++) {
          expect(frames[i] - frames[i - 1], inInclusiveRange(0, 1));
        }
        expect(frames.toSet(), hasLength(sheet.count), reason: sheet.file);
        expect(sheet.frameAt(sheet.life * 2), sheet.count - 1);
      }
    });

    test('저사양에서는 짝수 프레임만 써서 프레임 수가 반이 된다', () {
      const sheet = BlastSheet.medium;
      final low = {
        for (var t = 0.0; t < sheet.life; t += .005) sheet.lowFrameAt(t),
      };
      expect(low.every((f) => f.isEven), isTrue);
      expect(low, hasLength(sheet.count ~/ 2));
    });

    test('폭발은 끝으로 갈수록 퍼지고 마지막 25% 동안 사라진다', () {
      expect(SheetBlast.spreadAt(1), greaterThan(SheetBlast.spreadAt(0)));
      expect(SheetBlast.alphaAt(.5), 1);
      expect(SheetBlast.alphaAt(.9), inExclusiveRange(0, 1));
      expect(SheetBlast.alphaAt(1), 0);
    });

    test('섬광은 처음이 가장 밝고 끝에 꺼지며, 충격파는 계속 퍼진다', () {
      expect(GlowFlash.alphaAt(0), 1);
      expect(GlowFlash.alphaAt(1), 0);
      expect(ShockRing.spreadAt(.5), greaterThan(ShockRing.spreadAt(.1)));
      expect(ShockRing.spreadAt(1), closeTo(1, 1e-9));
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
