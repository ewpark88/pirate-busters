import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:pirate_busters/app/app.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/audio/sfx_bank.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/campaign/campaign_catalog.dart';
import 'package:pirate_busters/data/fleet_store.dart';
import 'package:pirate_busters/data/game_catalog.dart';
import 'package:pirate_busters/data/replay_store.dart';
import 'package:pirate_busters/meta/progress_store.dart';
import 'package:pirate_busters/settings/settings_store.dart';

/// 시작 순서: 화면 방향 → 저장소 → 효과음 합성·불러오기 → 앱.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 가로 고정, 좌·우 모두 허용, 몰입 모드 (개발 계획서 M4).
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Hive.initFlutter();
  final settings = await HiveSettingsStore.open();
  final catalog = await GameCatalog.load(rootBundle);
  final campaign = await CampaignCatalog.load(rootBundle, catalog);
  final fleet = await HiveFleetStore.open();
  final progress = await HiveProgressStore.open();
  final replays = await HiveReplayStore.open();
  final sound = SoloudSoundService();
  await sound.load(SfxBank.build());
  runApp(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(settings),
        gameCatalogProvider.overrideWithValue(catalog),
        campaignProvider.overrideWithValue(campaign),
        fleetStoreProvider.overrideWithValue(fleet),
        progressStoreProvider.overrideWithValue(progress),
        replayStoreProvider.overrideWithValue(replays),
        soundServiceProvider.overrideWithValue(sound),
      ],
      child: const PirateBustersApp(),
    ),
  );
}
