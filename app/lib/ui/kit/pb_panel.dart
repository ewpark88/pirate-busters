import 'package:flutter/material.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/ui/kit/kit_art.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 금 테두리·리벳 패널 (에셋 `ui/kit/panel`, 설계서 §13 공통 화면 규칙).
class PbPanel extends StatelessWidget {
  const PbPanel({
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 14),
    super.key,
  });

  final Widget child;

  /// 패널 머리 글자. 있으면 위에 금빛 제목을 둔다.
  final String? title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      image: KitArt.nine(KitArt.panel, KitArt.panelSlice, KitArt.panelScale),
    ),
    child: title == null
        ? child
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedText(
                title!,
                size: 15,
                color: AppColors.gold,
                font: AppFonts.display,
              ),
              const SizedBox(height: 6),
              Flexible(child: child),
            ],
          ),
  );
}

/// 탭 줄 (에셋 `ui/kit/tab_*`). 고른 탭은 금 테두리, 나머지는 어둡다.
class PbTabs extends StatelessWidget {
  const PbTabs({
    required this.labels,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, label) in labels.indexed)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Semantics(
            button: true,
            selected: i == selected,
            label: label,
            excludeSemantics: true,
            child: Pressable(
              onTap: () => onSelect(i),
              child: Container(
                height: 38,
                constraints: const BoxConstraints(minWidth: 84),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  image: KitArt.nine(
                    i == selected ? KitArt.tabActive : KitArt.tabIdle,
                    KitArt.tabSlice,
                    KitArt.tabScale,
                  ),
                ),
                child: OutlinedText(
                  label,
                  size: 15,
                  color: i == selected ? AppColors.gold : AppColors.mute,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// 작은 수치 칩: 그림·글자를 둥근 어두운 판에 담는다. [warn] 이면 붉은 테두리.
class PbChip extends StatelessWidget {
  const PbChip({required this.label, this.icon, this.warn = false, super.key});

  final String label;
  final String? icon;
  final bool warn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xE61B1E25),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: warn ? AppColors.danger : AppColors.gold.withValues(alpha: 0.7),
        width: 1.5,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Image.asset(icon!, width: 18, height: 18),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: warn ? AppColors.danger : AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

/// 켜기·끄기 단추 (설계서 §13 공통). 켜지면 초록 판 위로 손잡이가 미끄러진다.
class PbToggle extends StatelessWidget {
  const PbToggle({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// 읽어 주기용 이름.
  final String label;

  @override
  Widget build(BuildContext context) {
    final fast = KitMotion.reducedOf(context);
    final d = fast ? Duration.zero : const Duration(milliseconds: 160);
    return Semantics(
      toggled: value,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: d,
          width: 60,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AppColors.green : const Color(0xFF2A2E37),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold, width: 2),
          ),
          child: AnimatedAlign(
            duration: d,
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.knob,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x66000000), offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
