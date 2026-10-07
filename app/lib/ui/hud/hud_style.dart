import 'package:flutter/material.dart';

/// HUD 색 (에셋 tokens.json `palette.hud`, `team`).
abstract final class HudColors {
  static const Color panel = Color(0xE615171D);
  static const Color panelHi = Color(0xFF262A33);
  static const Color border = Color(0xFFC9962E);
  static const Color text = Color(0xFFEFE6D2);
  static const Color mute = Color(0xFF9A917F);
  static const Color blue = Color(0xFF2F62C4);
  static const Color red = Color(0xFFB3302B);
  static const Color warn = Color(0xFFFFC24A);
  static const Color danger = Color(0xFFE06A5A);
  static const Color good = Color(0xFF7FD36B);

  static Color team(int side) => side == 0 ? blue : red;
}

/// HUD 패널 테두리 상자.
class HudPanel extends StatelessWidget {
  const HudPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.borderColor = HudColors.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: HudColors.panel,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor, width: 1.5),
    ),
    child: Padding(
      padding: padding,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: HudColors.text, fontSize: 14),
        child: child,
      ),
    ),
  );
}
