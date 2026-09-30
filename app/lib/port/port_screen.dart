import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/port/port_game.dart';
import 'package:pirate_busters/port/port_widgets.dart';
import 'package:pirate_busters/port/settings_screen.dart';
import 'package:pirate_busters/shipyard/shipyard_screen.dart';
import 'package:pirate_busters/ui/battle_screen.dart';

/// 항구(메인 화면, 설계서 §13.2). MVP 는 위쪽 프로필·재화·설정, 가운데 내 배,
/// 아래 조선소·출항·선원 탭만 둔다(개발 계획서 M7). 미션·상자·우편은 R4.
class PortScreen extends ConsumerStatefulWidget {
  const PortScreen({super.key});

  @override
  ConsumerState<PortScreen> createState() => _PortScreenState();
}

class _PortScreenState extends ConsumerState<PortScreen> {
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
    _game = PortGame(_session!);
  }

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(_rebuild);
  }

  /// 출항 (설계서 §13.3). 캠페인 지도는 다음 묶음에서 붙인다. 지금은 AI 난이도만 고른다.
  Future<void> _sail() async {
    final l10n = AppLocalizations.of(context);
    final level = await showDialog<AiLevel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.chooseLevel),
        children: [
          for (final level in AiLevel.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(level),
              child: Text(levelLabel(l10n, level)),
            ),
        ],
      ),
    );
    if (level != null) await _open(BattleScreen(level: level));
  }

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
