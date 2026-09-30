import 'package:flutter/material.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/crew/crew_screen.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/shipyard/shipyard_screen.dart';
import 'package:pirate_busters/ui/battle_screen.dart';

/// 간이 시작 메뉴 (개발 계획서 M5). 항구 화면(설계서 §13.2)은 M7 에서 만든다.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    Widget button(String label, IconData icon, Widget screen) => Padding(
      padding: const EdgeInsets.all(6),
      child: FilledButton.icon(
        onPressed: () => open(screen),
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(minimumSize: const Size(220, 48)),
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFF1E6FB8),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.appTitle,
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: FilledButton.icon(
                      onPressed: () => _chooseLevel(context, open),
                      icon: const Icon(Icons.sports_esports),
                      label: Text(l10n.menuBattleAi),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(220, 48),
                      ),
                    ),
                  ),
                  button(
                    l10n.menuHotseat,
                    Icons.people,
                    const BattleScreen(hotseat: true),
                  ),
                  button(
                    l10n.menuShipyard,
                    Icons.construction,
                    const ShipyardScreen(),
                  ),
                  button(l10n.menuCrew, Icons.groups, const CrewScreen()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AI 난이도 4단계 고르기 (설계서 §5.2).
  Future<void> _chooseLevel(
    BuildContext context,
    void Function(Widget screen) open,
  ) async {
    final l10n = AppLocalizations.of(context);
    final level = await showDialog<AiLevel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.chooseLevel),
        children: [
          for (final level in AiLevel.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(level),
              child: Text(switch (level) {
                AiLevel.easy => l10n.levelEasy,
                AiLevel.normal => l10n.levelNormal,
                AiLevel.hard => l10n.levelHard,
                AiLevel.hell => l10n.levelHell,
              }),
            ),
        ],
      ),
    );
    if (level != null) open(BattleScreen(level: level));
  }
}
