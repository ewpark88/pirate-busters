// mozzi lib/ui/play/hud_scale.dart 의 생각을 가져왔다 (ADR-004): 가로 고정 가상 화면.
import 'package:flutter/widgets.dart';

/// HUD 를 설계 크기([designWidth]×[designHeight]) 기준으로 배치하고 화면에 맞게
/// 줄이거나 키운다. 작은 폰에서도 배치가 무너지지 않고 글자가 함께 줄어든다
/// (설계서 §14.4).
class HudScale extends StatelessWidget {
  const HudScale({required this.child, super.key});

  static const double designWidth = 960;
  static const double designHeight = 440;

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final sx = box.maxWidth / designWidth;
      final sy = box.maxHeight / designHeight;
      final scale = (sx < sy ? sx : sy).clamp(0.5, 1.4);
      return FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: box.maxWidth / scale,
          height: box.maxHeight / scale,
          child: child,
        ),
      );
    },
  );
}
