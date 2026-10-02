import 'package:flutter/material.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 버튼 종류 (에셋 `ui/kit/button_*`): 주(빨강, 출항·확정), 금(보상·다시 하기),
/// 보조(어두운 판, 돌아가기·취소).
enum PbButtonKind { primary, gold, secondary }

/// 게임 UI 키트 버튼 (설계서 §13 공통 화면 규칙). [onPressed] 가 null 이면 흐려진다.
class PbButton extends StatelessWidget {
  const PbButton({
    required this.label,
    required this.onPressed,
    this.kind = PbButtonKind.primary,
    this.icon,
    this.height = 48,
    this.minWidth = 120,
    this.fontSize = 18,
    super.key,
  });

  /// 작은 보조 버튼(목록 안·툴바).
  const PbButton.small({
    required this.label,
    required this.onPressed,
    this.kind = PbButtonKind.secondary,
    this.icon,
    super.key,
  }) : height = 38,
       minWidth = 72,
       fontSize = 15;

  final String label;
  final VoidCallback? onPressed;
  final PbButtonKind kind;

  /// 글자 앞에 놓는 그림 경로(메타 아이콘).
  final String? icon;
  final double height;
  final double minWidth;
  final double fontSize;

  String get _art => switch (kind) {
    PbButtonKind.primary => KitArt.buttonPrimary,
    PbButtonKind.gold => KitArt.buttonGold,
    PbButtonKind.secondary => KitArt.buttonSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final text = kind == PbButtonKind.gold
        ? const Color(0xFFFFF4D6)
        : const Color(0xFFFFFFFF);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            constraints: BoxConstraints(minWidth: minWidth),
            height: height,
            padding: EdgeInsets.fromLTRB(16, 0, 16, height * 0.08),
            decoration: BoxDecoration(
              image: KitArt.nine(_art, KitArt.buttonSlice, KitArt.buttonScale),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Image.asset(icon!, width: fontSize + 6, height: fontSize + 6),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: OutlinedText(label, size: fontSize, color: text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 둥근 아이콘 버튼 (뒤로 가기·설정 같은 작은 단추). 보조 버튼 그림을 쓴다.
class PbIconButton extends StatelessWidget {
  const PbIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 44,
    super.key,
  });

  final String icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Pressable(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.2),
          decoration: BoxDecoration(
            image: KitArt.nine(
              KitArt.buttonSecondary,
              KitArt.buttonSlice,
              KitArt.buttonScale * 1.6,
            ),
          ),
          child: Image.asset(icon),
        ),
      ),
    ),
  );
}
