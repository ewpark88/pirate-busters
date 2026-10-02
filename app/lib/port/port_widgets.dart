import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// AI 난이도 이름 (설계서 §5.2).
String levelLabel(AppLocalizations l10n, AiLevel level) => switch (level) {
  AiLevel.easy => l10n.levelEasy,
  AiLevel.normal => l10n.levelNormal,
  AiLevel.hard => l10n.levelHard,
  AiLevel.hell => l10n.levelHell,
};

/// 항구 위쪽: 프로필(레벨·경험치 막대)·골드·설정 (설계서 §13.2). 닉네임·티어·진주는 R4.
class PortTopBar extends StatelessWidget {
  const PortTopBar({
    required this.progress,
    required this.onSettings,
    required this.onHotseat,
    this.onTestBattle,
    super.key,
  });

  final PlayerProgress progress;
  final VoidCallback onSettings;

  /// 개발용 테스트 대전 (ADR-053). 개발 도구가 꺼져 있으면 null 이고 버튼이 없다.
  final VoidCallback? onTestBattle;

  /// 개발용 둘이서 해전 (ADR-029). 출시 전에 뺀다.
  final VoidCallback onHotseat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          HudPanel(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.portLevel(progress.level)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Tooltip(
                    message: l10n.portXp(
                      numbers.format(progress.xp),
                      numbers.format(progress.xpToNext),
                    ),
                    child: LinearProgressIndicator(
                      value: (progress.xp / progress.xpToNext).clamp(0, 1),
                      minHeight: 8,
                      color: HudColors.warn,
                      backgroundColor: HudColors.panelHi,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          HudPanel(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MetaIcons.image(MetaIcons.gold, size: 18),
                const SizedBox(width: 4),
                Text(numbers.format(progress.gold)),
              ],
            ),
          ),
          const Spacer(),
          if (onTestBattle != null)
            IconButton(
              tooltip: l10n.devTestBattle,
              onPressed: onTestBattle,
              icon: const Icon(Icons.bug_report, color: HudColors.text),
            ),
          IconButton(
            tooltip: l10n.menuHotseat,
            onPressed: onHotseat,
            icon: const Icon(Icons.people, color: HudColors.text),
          ),
          IconButton(
            tooltip: l10n.settings,
            onPressed: onSettings,
            icon: const Icon(Icons.settings, color: HudColors.text),
          ),
        ],
      ),
    );
  }
}

/// 항구 아래 탭: 조선소 · 출항(크고 돌출) · 선원 (설계서 §13.2). 랭크·상점 탭은 R4.
class PortTabs extends StatelessWidget {
  const PortTabs({
    required this.shipyardLocked,
    required this.onShipyard,
    required this.onCrew,
    required this.onSail,
    required this.labels,
    super.key,
  });

  final bool shipyardLocked;
  final VoidCallback onShipyard;
  final VoidCallback onCrew;
  final VoidCallback onSail;
  final ({String shipyard, String crew, String sail}) labels;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Tab(
          icon: shipyardLocked ? Icons.lock : Icons.construction,
          label: labels.shipyard,
          onTap: onShipyard,
          dim: shipyardLocked,
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onSail,
          icon: const Icon(Icons.sailing),
          label: Text(labels.sail, style: const TextStyle(fontSize: 22)),
          style: FilledButton.styleFrom(
            backgroundColor: HudColors.border,
            foregroundColor: HudColors.panel,
            minimumSize: const Size(200, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _Tab(icon: Icons.groups, label: labels.crew, onTap: onCrew),
      ],
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dim = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dim;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: dim ? 0.6 : 1,
    child: HudPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 110,
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    ),
  );
}
