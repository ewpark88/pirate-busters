import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/audio/music_director.dart';
import 'package:pirate_busters/audio/sound_library.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/settings/settings_store.dart';

/// [files] 에 있는 경로만 읽히는 에셋 묶음.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);

  final Set<String> files;

  @override
  Future<ByteData> load(String key) async {
    if (!files.contains(key)) throw FlutterError('없음: $key');
    return ByteData.sublistView(Uint8List.fromList([79, 103, 103, 83]));
  }
}

class _MusicRecorder implements SoundService {
  final List<Music?> tracks = [];

  @override
  Future<void> load(Map<Sfx, Uint8List> wavs) async {}

  @override
  Future<void> loadMusic(Map<Music, Uint8List> wavs) async {}

  @override
  void play(Sfx sfx, {double pitch = 1, double volume = 1}) {}

  @override
  void playMusic(Music? track, {double speed = 1}) => tracks.add(track);
}

void main() {
  group('CC0 음원 (설계서 §10.3, 계획서 A19)', () {
    test('목록에 있는 음원 파일이 모두 있고 docs 에 출처가 적혀 있다', () {
      final assets = <String>[
        for (final s in Sfx.values) ...AudioAssets.sfx(s),
        for (final m in Music.values) AudioAssets.music(m),
      ];
      final credits = File('../docs/ASSETS.md').readAsStringSync();
      for (final a in assets) {
        expect(File(a).existsSync(), isTrue, reason: a);
        expect(credits, contains(a.split('/').last), reason: a);
      }
      // 같은 소리는 2~3개 변형을 돌려 쓴다.
      for (final s in Sfx.values) {
        expect(AudioAssets.sfx(s).length, inInclusiveRange(2, 3), reason: '$s');
      }
    });

    test('음원을 못 읽은 소리·곡만 합성음으로 채운다', () async {
      final cannon = AudioAssets.sfx(Sfx.cannon);
      final bundle = _Bundle({
        cannon[0],
        cannon[2],
        AudioAssets.music(Music.port),
      });
      final sfx = await SoundLibrary.loadSfx(
        bundle,
        synth: (_) => Uint8List(3),
      );
      expect(sfx[Sfx.cannon]!.map((c) => c.name), [
        'sfx_cannon_1.ogg',
        'sfx_cannon_3.ogg',
      ]);
      expect(sfx[Sfx.wood]!.single.name, 'wood.wav');
      expect(sfx[Sfx.wood]!.single.bytes, hasLength(3));
      final music = await SoundLibrary.loadMusic(
        bundle,
        synth: (_) => Uint8List(5),
      );
      expect(music[Music.port]!.name, 'music_port.ogg');
      expect(music[Music.battle]!.name, 'battle.wav');
    });

    test('변형은 돌아가며 쓰고 소리마다 따로 센다', () {
      final picker = VariantPicker(random: math.Random(1));
      expect(
        [for (var i = 0; i < 5; i++) picker.next(Sfx.wood, 3)],
        [
          0,
          1,
          2,
          0,
          1,
        ],
      );
      expect(picker.next(Sfx.splash, 3), 0);
      expect(picker.next(Sfx.sink, 1), 0);
    });

    test('음높이는 조금만 흔들고 승리·패배 악구는 흔들지 않는다', () {
      final picker = VariantPicker(random: math.Random(7));
      for (var i = 0; i < 50; i++) {
        final p = picker.jitter(Sfx.cannon, 1);
        expect(
          p,
          inInclusiveRange(1 - VariantPicker.spread, 1 + VariantPicker.spread),
        );
      }
      expect(picker.jitter(Sfx.win, 1.2), 1.2);
      expect(picker.jitter(Sfx.lose, 1), 1);
    });
  });

  testWidgets('음악을 끄면 곡을 멈추고 켜면 다시 튼다 (설계서 §10.3)', (tester) async {
    final sound = _MusicRecorder();
    final settings = MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(settings),
        soundServiceProvider.overrideWithValue(sound),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MusicDirector(child: SizedBox()),
      ),
    );
    container.read(musicTrackProvider.notifier).play(Music.port);
    await tester.pump();
    await container.read(musicOnProvider.notifier).set(on: false);
    await tester.pump();
    await container.read(musicOnProvider.notifier).set(on: true);
    await tester.pump();
    expect(sound.tracks, [Music.port, null, Music.port]);
  });
}
