import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pirate_busters/audio/sfx_bank.dart';
import 'package:pirate_busters/audio/shanty_music.dart';
import 'package:pirate_busters/audio/sound_service.dart';

/// 불러온 소리 한 개: 이름(형식을 알리는 확장자 포함)과 바이트.
typedef SoundClip = ({String name, Uint8List bytes});

/// CC0 음원 목록 (설계서 §10.3, 계획서 A19). 출처·라이선스는 docs/ASSETS.md
/// 「음원 (A19, CC0)」. 파일은 `assets/audio/sfx_<소리>_<번호>.ogg`,
/// `assets/audio/music_<곡>.ogg` 이다.
abstract final class AudioAssets {
  static const String dir = 'assets/audio';

  /// 소리마다 변형 수.
  static const Map<Sfx, int> variants = {
    Sfx.cannon: 3,
    Sfx.wood: 3,
    Sfx.splash: 3,
    Sfx.clang: 3,
    Sfx.boom: 3,
    Sfx.sink: 2,
    Sfx.win: 3,
    Sfx.lose: 3,
    Sfx.click: 3,
  };

  static List<String> sfx(Sfx s) => [
    for (var i = 1; i <= (variants[s] ?? 0); i++) '$dir/sfx_${s.name}_$i.ogg',
  ];

  static String music(Music m) => '$dir/music_${m.name}.ogg';
}

/// 음원을 읽는다. 하나도 못 읽은 소리·곡은 코드 합성음으로 채운다 (설계서 §10.3).
abstract final class SoundLibrary {
  static Future<Map<Sfx, List<SoundClip>>> loadSfx(
    AssetBundle bundle, {
    Uint8List Function(Sfx) synth = SfxBank.wav,
  }) async => {
    for (final s in Sfx.values)
      s:
          await _clips(AudioAssets.sfx(s), bundle) ??
          [(name: '${s.name}.wav', bytes: synth(s))],
  };

  static Future<Map<Music, SoundClip>> loadMusic(
    AssetBundle bundle, {
    Uint8List Function(Music) synth = ShantyMusic.wav,
  }) async => {
    for (final m in Music.values)
      m:
          (await _clips([AudioAssets.music(m)], bundle))?.first ??
          (name: '${m.name}.wav', bytes: synth(m)),
  };

  /// 읽은 파일만 돌려준다. 하나도 없으면 null.
  static Future<List<SoundClip>?> _clips(
    List<String> paths,
    AssetBundle bundle,
  ) async {
    final out = <SoundClip>[];
    for (final p in paths) {
      try {
        final data = await bundle.load(p);
        out.add((name: p.split('/').last, bytes: data.buffer.asUint8List()));
      } on Object catch (e) {
        debugPrint('음원 없음, 합성음으로 대신: $p ($e)');
      }
    }
    return out.isEmpty ? null : out;
  }
}

/// 변형 고르기와 음높이 흔들기 (설계서 §10.3 ‘반복감을 줄인다’). 소리마다 변형을
/// 돌아가며 쓰고, 재생 속도를 조금씩 흔든다. 승리·패배 악구는 흔들지 않는다.
class VariantPicker {
  VariantPicker({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  final Map<Sfx, int> _next = {};

  /// 흔들기 폭(±비율).
  static const double spread = .06;

  /// [sfx] 의 다음 변형 번호(0부터, [count] 개를 돌아가며).
  int next(Sfx sfx, int count) {
    if (count <= 1) return 0;
    final i = (_next[sfx] ?? 0) % count;
    _next[sfx] = i + 1;
    return i;
  }

  /// [pitch] 를 ±[spread] 안에서 흔든다.
  double jitter(Sfx sfx, double pitch) {
    if (sfx == Sfx.win || sfx == Sfx.lose) return pitch;
    return pitch * (1 + (_random.nextDouble() * 2 - 1) * spread);
  }
}
