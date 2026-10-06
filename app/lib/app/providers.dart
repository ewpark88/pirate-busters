import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/campaign/campaign_catalog.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/data/game_catalog.dart';
import 'package:pirate_busters/data/replay_store.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/platform/ads.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/platform/iap.dart';
import 'package:pirate_busters/platform/remote_values.dart';
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

/// 2발 뒤 자동 턴 종료 (설계서 §2.2, ADR-042).
final autoEndTurnProvider = NotifierProvider<AutoEndTurnNotifier, bool>(
  AutoEndTurnNotifier.new,
);

class AutoEndTurnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).autoEndTurn;

  Future<void> set({required bool on}) async {
    state = on;
    await ref.read(settingsStoreProvider).setAutoEndTurn(on: on);
  }
}

/// 캠페인 데이터(해역·스테이지). 부트스트랩에서 덮어쓴다.
final campaignProvider = Provider<CampaignCatalog>(
  (ref) => throw UnimplementedError('campaignProvider 를 덮어써야 한다'),
);

/// 진행 저장소. 부트스트랩에서 덮어쓴다.
final progressStoreProvider = Provider<ProgressStore>(
  (ref) => throw UnimplementedError('progressStoreProvider 를 덮어써야 한다'),
);

/// 플레이어 진행 (설계서 §4.5, §6.1, §13.1). 바꾸면 바로 저장한다.
final progressProvider = NotifierProvider<ProgressNotifier, PlayerProgress>(
  ProgressNotifier.new,
);

class ProgressNotifier extends Notifier<PlayerProgress> {
  @override
  PlayerProgress build() => ref.read(progressStoreProvider).progress;

  /// [change] 로 새 진행을 만들어 저장한다.
  Future<void> update(PlayerProgress Function(PlayerProgress p) change) async {
    state = change(state);
    await ref.read(progressStoreProvider).save(state);
  }
}

/// 효과음·진동 켜기 (설계서 §13.8).
final soundOnProvider = NotifierProvider<SoundOnNotifier, bool>(
  SoundOnNotifier.new,
);

class SoundOnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).sound;

  Future<void> set({required bool on}) async {
    state = on;
    await ref.read(settingsStoreProvider).setSound(on: on);
  }
}

final vibrationOnProvider = NotifierProvider<VibrationOnNotifier, bool>(
  VibrationOnNotifier.new,
);

class VibrationOnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).vibration;

  Future<void> set({required bool on}) async {
    state = on;
    await ref.read(settingsStoreProvider).setVibration(on: on);
  }
}

/// 화면 흔들림 줄이기 (설계서 §13.8, §10.4).
final calmShakeProvider = NotifierProvider<CalmShakeNotifier, bool>(
  CalmShakeNotifier.new,
);

class CalmShakeNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).calmShake;

  Future<void> set({required bool on}) async {
    state = on;
    await ref.read(settingsStoreProvider).setCalmShake(on: on);
  }
}

/// 분석·광고·결제·원격 설정 (개발 계획서 M7). 기본은 아무것도 안 하는 구현. 실제 SDK 는
/// 설정 파일(google-services.json 등)이 들어온 뒤 부트스트랩에서 덮어쓴다.
final analyticsProvider = Provider<Analytics>((ref) => const NoopAnalytics());
final adsProvider = Provider<RewardedAds>((ref) => const NoAds());
final iapProvider = Provider<Iap>((ref) => const NoIap());
final remoteValuesProvider = Provider<RemoteValues>(
  (ref) => const EmptyRemoteValues(),
);

/// 광고 제거 구매 상태 (설계서 §9).
final adsRemovedProvider = NotifierProvider<AdsRemovedNotifier, bool>(
  AdsRemovedNotifier.new,
);

class AdsRemovedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(iapProvider).adsRemoved;

  Future<void> buy() async {
    if (!await ref.read(iapProvider).buyRemoveAds()) return;
    state = true;
    ref.read(analyticsProvider).log(Events.iapPurchase, {'item': 'remove_ads'});
  }
}

/// 리플레이 저장소. 부트스트랩에서 덮어쓴다. 기본은 메모리.
final replayStoreProvider = Provider<ReplayStore>((ref) => MemoryReplayStore());

/// 효과음. 부트스트랩에서 flutter_soloud 로 덮어쓴다. 기본은 소리 없음(테스트).
final soundServiceProvider = Provider<SoundService>(
  (ref) => const SilentSoundService(),
);
