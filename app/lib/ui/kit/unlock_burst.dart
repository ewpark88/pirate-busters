import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 잠금이 풀리는 순간의 연출 (설계서 §13 공통 “해금은 튕기며 반짝인다”, A55):
/// [locked] 가 true 에서 false 로 바뀌면 [child] 가 크게 튀었다 돌아오고 금빛 고리가
/// 퍼진다. 움직임 끄기(저사양)면 아무것도 하지 않는다.
class UnlockBurst extends StatefulWidget {
  const UnlockBurst({required this.locked, required this.child, super.key});

  final bool locked;
  final Widget child;

  static const Duration duration = Duration(milliseconds: 650);

  @override
  State<UnlockBurst> createState() => UnlockBurstState();
}

/// 연출 진행(테스트가 읽는다).
class UnlockBurstState extends State<UnlockBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: UnlockBurst.duration,
    value: 1,
  );

  /// 연출 중인가.
  bool get bursting => clock.isAnimating;

  @override
  void didUpdateWidget(UnlockBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locked && !widget.locked && !KitMotion.reducedOf(context)) {
      unawaited(clock.forward(from: 0));
    }
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: clock,
    child: widget.child,
    builder: (context, child) {
      final t = clock.value;
      if (t >= 1) return child!;
      final pop = 1 + 0.18 * Curves.easeOut.transform(1 - (t * 2 - 1).abs());
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.scale(scale: pop, child: child),
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1 + t * .6,
                child: DecoratedBox(
                  key: const ValueKey('unlock-ring'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD45A).withValues(alpha: 1 - t),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
