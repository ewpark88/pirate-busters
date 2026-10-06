import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// AI 난이도 이름 (설계서 §5.2).
String levelLabel(AppLocalizations l10n, AiLevel level) => switch (level) {
  AiLevel.easy => l10n.levelEasy,
  AiLevel.normal => l10n.levelNormal,
  AiLevel.hard => l10n.levelHard,
  AiLevel.hell => l10n.levelHell,
};

/// 항구 아이콘 (에셋 `ui/icons/`).
abstract final class PortIcons {
  static const String _dir = 'assets/images/ui/icons';
  static const String ship = '$_dir/ship.png';
  static const String crew = '$_dir/crew.png';
  static const String gear = '$_dir/gear.png';
  static const String lock = '$_dir/lock.png';
  static const String quest = '$_dir/quest.png';
}

/// 항구 위쪽: 프로필(레벨·경험치 막대)·골드·설정 (설계서 §13.2, §13 공통).
/// 닉네임·티어·진주는 R4.
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(
        children: [
          Tooltip(
            message: l10n.portXp(
              numbers.format(progress.xp),
              numbers.format(progress.xpToNext),
            ),
            child: _LevelBadge(
              label: l10n.portLevel(progress.level),
              fill: (progress.xp / progress.xpToNext).clamp(0, 1).toDouble(),
            ),
          ),
          const SizedBox(width: 10),
          _Pill(
            icon: MetaIcons.gold,
            child: CountUp(
              value: progress.gold,
              builder: (context, v) =>
                  OutlinedText(numbers.format(v), size: 17),
            ),
          ),
          const Spacer(),
          if (onTestBattle != null) ...[
            PbIconButton(
              icon: PortIcons.quest,
              tooltip: l10n.devTestBattle,
              onPressed: onTestBattle,
            ),
            const SizedBox(width: 8),
          ],
          PbIconButton(
            icon: PortIcons.crew,
            tooltip: l10n.menuHotseat,
            onPressed: onHotseat,
          ),
          const SizedBox(width: 8),
          PbIconButton(
            icon: PortIcons.gear,
            tooltip: l10n.settings,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

/// 레벨 글자와 경험치 막대.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label, required this.fill});

  final String label;
  final double fill;

  @override
  Widget build(BuildContext context) => _Pill(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedText(label, size: 17, font: AppFonts.display),
        const SizedBox(width: 8),
        Container(
          width: 92,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF0E1014),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF5B79C9), width: 1.5),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fill,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF63D06A),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// 금 테두리 둥근 판 (위쪽 재화·레벨).
class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.icon});

  final Widget child;
  final String? icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: EdgeInsets.fromLTRB(icon == null ? 14 : 6, 0, 14, 0),
    decoration: BoxDecoration(
      color: const Color(0xE61B1E25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.gold, width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x66000000), offset: Offset(0, 3)),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Image.asset(icon!, width: 28, height: 28),
          const SizedBox(width: 6),
        ],
        child,
      ],
    ),
  );
}

/// 항구 아래 탭: 조선소 · 출항(크고 돌출) · 선원 (설계서 §13.2). 랭크·상점 탭은 R4.
class PortTabs extends StatelessWidget {
  const PortTabs({
    required this.shipyardLocked,
    required this.onShipyard,
    required this.onCrew,
    required this.onSail,
    required this.labels,
    this.shipyardDot = false,
    super.key,
  });

  final bool shipyardLocked;

  /// 조선소에 지금 할 수 있는 배 업그레이드가 있다: 빨간 점 (설계서 §13.2).
  final bool shipyardDot;
  final VoidCallback onShipyard;
  final VoidCallback onCrew;
  final VoidCallback onSail;
  final ({String shipyard, String crew, String sail}) labels;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PopIn(
          order: 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PbButton(
                label: labels.shipyard,
                icon: shipyardLocked ? PortIcons.lock : PortIcons.ship,
                kind: PbButtonKind.secondary,
                height: 54,
                minWidth: 150,
                onPressed: onShipyard,
              ),
              if (shipyardDot && !shipyardLocked)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Image.asset(MetaIcons.redDot, width: 18, height: 18),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        PopIn(
          child: PbButton(
            label: labels.sail,
            height: 72,
            minWidth: 240,
            fontSize: 28,
            onPressed: onSail,
          ),
        ),
        const SizedBox(width: 14),
        PopIn(
          order: 2,
          child: PbButton(
            label: labels.crew,
            icon: PortIcons.crew,
            kind: PbButtonKind.secondary,
            height: 54,
            minWidth: 150,
            onPressed: onCrew,
          ),
        ),
      ],
    ),
  );
}
