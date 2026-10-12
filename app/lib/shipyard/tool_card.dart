import 'package:flutter/material.dart';
import 'package:pirate_busters/app/app_theme.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 같은 도구인지 (재질·모듈은 종류까지).
bool sameTool(ShipTool a, ShipTool b) => switch ((a, b)) {
  (MaterialTool(material: final x), MaterialTool(material: final y)) => x == y,
  (ModuleTool(kind: final x), ModuleTool(kind: final y)) => x == y,
  (CabinTool(), CabinTool()) || (EraseTool(), EraseTool()) => true,
  _ => false,
};

/// 팔레트 카드 한 장 (설계서 §13.6): 그림, 이름, 아래 줄에 건조 포인트 또는
/// 자물쇠·여는 골드. 고른 카드는 금 테두리, [dot] 이면 오른쪽 위 빨간 점.
class ToolCard extends StatelessWidget {
  const ToolCard({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
    this.costText,
    this.lockedGold,
    this.dot = false,
    super.key,
  });

  final String label;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  /// 건조 포인트 글자. null 이면 적지 않는다(선실·지우기).
  final String? costText;

  /// 잠겼으면 여는 골드.
  final int? lockedGold;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final locked = lockedGold != null;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF3A2F18)
                    : const Color(0xFF262A33),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppColors.gold : const Color(0xFF3A3F4A),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Opacity(
                    opacity: locked ? 0.45 : 1,
                    child: Image.asset(image, width: 28, height: 28),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: _text()),
                ],
              ),
            ),
            if (dot)
              Positioned(
                right: -2,
                top: -2,
                child: Image.asset(MetaIcons.redDot, width: 11, height: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _text() {
    final locked = lockedGold != null;
    final name = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        height: 1.1,
        color: locked
            ? AppColors.mute
            : (selected ? AppColors.gold : AppColors.text),
      ),
    );
    final sub = locked
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(MetaIcons.lock, width: 11, height: 11),
                const SizedBox(width: 2),
                Image.asset(MetaIcons.gold, width: 11, height: 11),
                const SizedBox(width: 2),
                Text(
                  '$lockedGold',
                  style: const TextStyle(fontSize: 11, color: AppColors.gold),
                ),
              ],
            ),
          )
        : costText == null
        ? null
        : Text(
            costText!,
            style: const TextStyle(fontSize: 11, color: AppColors.mute),
          );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [name, ?sub],
    );
  }
}
