import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/audio/music_director.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/campaign/campaign_map_screen.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/dev/test_battle_screen.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/port/port_game.dart';
import 'package:pirate_busters/port/port_widgets.dart';
import 'package:pirate_busters/port/settings_screen.dart';
import 'package:pirate_busters/shipyard/shipyard_screen.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';
import 'package:pirate_busters/ui/battle_screen.dart';

/// 항구(메인 화면, 설계서 §13.2). MVP 는 위쪽 프로필·재화·설정, 가운데 내 배,
/// 아래 조선소·출항·선원 탭만 둔다(개발 계획서 M7). 미션·상자·우편은 R4.
class PortScreen extends ConsumerStatefulWidget {
  const PortScreen({super.key});

  @override
  ConsumerState<PortScreen> createState() => _PortScreenState();
}

class _PortScreenState extends ConsumerState<PortScreen> {
  /// 설정의 저사양 모드 (설계서 §12). 항구 배경 겹 수를 줄인다.
  final ValueNotifier<bool> _lowEnd = ValueNotifier(false);
  BattleSession? _session;
  late PortGame _game;

  /// 대표 설계도·덱으로 정지된 판을 만들어 배를 그린다. 화면에 돌아올 때마다 다시 만든다.
  void _rebuild() {
    final catalog = ref.read(gameCatalogProvider);
    final fleet = ref.read(fleetStoreProvider);
    _session?.dispose();
    _session = BattleSession(
      BattleSetup(catalog).newMatchFor(
        1,
        blueprint: fleet.blueprint(fleet.activeSlot),
        deck: fleet.deck,
      ),
      humanSides: const {0},
      speciesOf: catalog.speciesOf,
    );
    _game = PortGame(_session!, lowEnd: _lowEnd);
  }

  @override
  void initState() {
    super.initState();
    _rebuild();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 항구 곡 (설계서 §10.3).
      ref.read(musicTrackProvider.notifier).play(Music.port);
      unawaited(_firstRun());
    });
  }

  /// 처음 실행: 프롤로그(건너뛰기 가능) 뒤 캠페인 지도(튜토리얼 3판)로 (설계서 §13.1, §15.2).
  Future<void> _firstRun() async {
    final progress = ref.read(progressProvider);
    final cuts = StoryData.of(StoryData.prologue);
    if (progress.prologueSeen || cuts == null) return;
    await ref.read(progressProvider.notifier).update((p) => p.seePrologue());
    if (!mounted) return;
    await CutsceneScreen.show(context, cuts);
    if (mounted) await _open(const CampaignMapScreen());
  }

  @override
  void dispose() {
    _session?.dispose();
    _lowEnd.dispose();
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(_rebuild);
  }

  /// 출항 (설계서 §13.3): 캠페인 지도로 간다. 모드 선택(랭크·오늘의 해전)은 R4.
  Future<void> _sail() => _open(const CampaignMapScreen());

  void _shipyard(PlayerProgress progress) {
    if (progress.shipyardUnlocked) {
      unawaited(_open(const ShipyardScreen()));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).portShipyardLocked),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = ref.watch(progressProvider);
    _lowEnd.value = ref.watch(lowEndProvider);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배를 누르면 조선소 (§13.2).
          GestureDetector(
            onTap: () => _shipyard(progress),
            child: GameWidget(game: _game),
          ),
          SafeArea(
            child: Column(
              children: [
                PortTopBar(
                  progress: progress,
                  onSettings: () => _open(const SettingsScreen()),
                  onHotseat: () => _open(const BattleScreen(hotseat: true)),
                  onTestBattle: devTools
                      ? () => _open(const TestBattleScreen())
                      : null,
                ),
                const Spacer(),
                PortTabs(
                  shipyardLocked: !progress.shipyardUnlocked,
                  onShipyard: () => _shipyard(progress),
                  onCrew: () => _open(const CrewScreen()),
                  onSail: _sail,
                  labels: (
                    shipyard: l10n.menuShipyard,
                    crew: l10n.menuCrew,
                    sail: l10n.portSail,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
