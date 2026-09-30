import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/data/game_catalog.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';

/// 게임 데이터(해적·탄종·추천 설계도). 부트스트랩에서 덮어쓴다.
final gameCatalogProvider = Provider<GameCatalog>(
  (ref) => throw UnimplementedError('gameCatalogProvider 를 덮어써야 한다'),
);

/// 내 설계도·덱 저장소. 부트스트랩에서 덮어쓴다.
final fleetStoreProvider = Provider<FleetStore>(
  (ref) => throw UnimplementedError('fleetStoreProvider 를 덮어써야 한다'),
);

/// 부트스트랩에서 덮어쓴다.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsStoreProvider 를 덮어써야 한다'),
);

/// 언어 선택. 바꾸면 저장하고 앱이 재시작 없이 바로 다시 그려진다 (설계서 §14.1).
final languageProvider = NotifierProvider<LanguageNotifier, LanguageChoice>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<LanguageChoice> {
  @override
  LanguageChoice build() => ref.read(settingsStoreProvider).language;

  Future<void> choose(LanguageChoice choice) async {
    state = choice;
    await ref.read(settingsStoreProvider).setLanguage(choice);
  }
}

/// 저사양 모드 (설계서 §13.8). 켜면 바다 굴절 셰이더를 끈다.
final lowEndProvider = NotifierProvider<LowEndNotifier, bool>(
  LowEndNotifier.new,
);

class LowEndNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).lowEnd;

  Future<void> set({required bool on}) async {
    state = on;
    await ref.read(settingsStoreProvider).setLowEnd(on: on);
  }
}

/// 효과음. 부트스트랩에서 flutter_soloud 로 덮어쓴다. 기본은 소리 없음(테스트).
final soundServiceProvider = Provider<SoundService>(
  (ref) => const SilentSoundService(),
);
