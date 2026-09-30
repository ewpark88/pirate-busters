// mozzi lib/domain/services/sound_service.dart·data/audio/soloud_sound_service.dart
// 에서 가져와 고쳤다 (ADR-004). 루프는 쓰지 않는다.

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// 전투 효과음 (설계서 §10.3): 포성, 나무 부서짐, 물보라, 철판 튕김.
enum Sfx { cannon, wood, splash, clang }

/// 효과음 재생. 소리는 코드로 합성해 [load] 로 넘긴다 (ADR-029).
abstract interface class SoundService {
  /// 합성한 WAV 바이트를 불러온다. 실패해도 게임은 소리 없이 진행한다.
  Future<void> load(Map<Sfx, Uint8List> wavs);

  /// 한 번 재생. [pitch] 는 재생 속도 배율(음높이).
  void play(Sfx sfx, {double pitch = 1, double volume = 1});
}

/// 소리를 내지 않는다. 테스트와 소리 초기화 실패 때 쓴다.
class SilentSoundService implements SoundService {
  const SilentSoundService();

  @override
  Future<void> load(Map<Sfx, Uint8List> wavs) async {}

  @override
  void play(Sfx sfx, {double pitch = 1, double volume = 1}) {}
}

/// flutter_soloud 저지연 재생.
class SoloudSoundService implements SoundService {
  final SoLoud _soloud = SoLoud.instance;
  final Map<Sfx, AudioSource> _sources = {};

  @override
  Future<void> load(Map<Sfx, Uint8List> wavs) async {
    try {
      if (!_soloud.isInitialized) await _soloud.init();
      for (final e in wavs.entries) {
        _sources[e.key] = await _soloud.loadMem('${e.key.name}.wav', e.value);
      }
    } on Object catch (e) {
      debugPrint('효과음 초기화 실패, 소리 없이 진행: $e');
      _sources.clear();
    }
  }

  @override
  void play(Sfx sfx, {double pitch = 1, double volume = 1}) {
    final src = _sources[sfx];
    if (src == null) return;
    final h = _soloud.play(src, volume: volume);
    if (pitch != 1) _soloud.setRelativePlaySpeed(h, pitch);
  }
}
