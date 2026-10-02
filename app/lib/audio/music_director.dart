import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/audio/sound_service.dart';

/// 배경음악 켜기 (설계서 §10.3 ‘설정의 음악 끄기’).
final musicOnProvider = NotifierProvider<MusicOnNotifier, bool>(
  MusicOnNotifier.new,
);

class MusicOnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).music;

  Future<void> set({required bool on}) async {
    state = on;
    await ref.read(settingsStoreProvider).setMusic(on: on);
  }
}

/// 지금 틀 곡과 빠르기. 항구는 항구 곡, 전투는 전투 곡(폭풍 타임에 빠르게, §10.3).
final musicTrackProvider =
    NotifierProvider<MusicTrackNotifier, (Music?, double)>(
      MusicTrackNotifier.new,
    );

class MusicTrackNotifier extends Notifier<(Music?, double)> {
  @override
  (Music?, double) build() => (null, 1);

  /// [track] 을 [speed] 로 튼다. 같은 값이면 바꾸지 않는다.
  void play(Music? track, {double speed = 1}) {
    // 앱(ProviderScope)이 먼저 닫히면 아무것도 하지 않는다.
    if (!ref.mounted) return;
    if (state != (track, speed)) state = (track, speed);
  }
}

/// 폭풍 타임의 음악 빠르기 배율.
const double stormMusicSpeed = 1.2;

/// 앱 루트에서 곡·설정이 바뀔 때마다 [SoundService] 에 넘긴다.
class MusicDirector extends ConsumerStatefulWidget {
  const MusicDirector({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<MusicDirector> createState() => _MusicDirectorState();
}

class _MusicDirectorState extends ConsumerState<MusicDirector> {
  void _apply() {
    final (track, speed) = ref.read(musicTrackProvider);
    final on = ref.read(musicOnProvider);
    ref.read(soundServiceProvider).playMusic(on ? track : null, speed: speed);
  }

  @override
  void initState() {
    super.initState();
    ref
      ..listenManual(musicTrackProvider, (_, _) => _apply())
      ..listenManual(musicOnProvider, (_, _) => _apply());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
