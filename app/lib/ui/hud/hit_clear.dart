import 'dart:async';

import 'package:flutter/widgets.dart';

/// 연출 중 흐린 HUD 안에서 [value] 가 줄면 [clearFor] 동안 또렷하게 보인다
/// (설계서 §13.4 ‘선체 내구도 막대는 피해를 받는 순간 잠깐 또렷해진다’, A33).
class HitClear extends StatefulWidget {
  const HitClear({
    required this.value,
    required this.opacity,
    required this.child,
    super.key,
  });

  final double value;

  /// 평소 진하기(연출 중이면 흐림).
  final double opacity;
  final Widget child;

  static const Duration clearFor = Duration(milliseconds: 900);
  static const Duration fade = Duration(milliseconds: 220);

  @override
  State<HitClear> createState() => _HitClearState();
}

class _HitClearState extends State<HitClear> {
  Timer? _timer;
  bool _clear = false;

  @override
  void didUpdateWidget(HitClear oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value < oldWidget.value - 1e-6) {
      _clear = true;
      _timer?.cancel();
      _timer = Timer(HitClear.clearFor, () {
        if (mounted) setState(() => _clear = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: _clear ? 1 : widget.opacity,
    duration: _clear ? Duration.zero : HitClear.fade,
    child: widget.child,
  );
}
