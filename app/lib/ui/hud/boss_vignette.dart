import 'dart:async';

import 'package:flutter/material.dart';

/// 보스전 화면 가장자리 붉은 테 (설계서 §13.4, ADR-096). 천천히 숨 쉬듯 깜빡이고,
/// [calm](움직임 줄이기)이거나 시스템 애니메이션이 꺼져 있으면 멈춘다. 터치는 막지 않는다.
class BossVignette extends StatefulWidget {
  const BossVignette({this.calm = false, super.key});

  final bool calm;

  /// 한 번 숨 쉬는 시간.
  static const Duration period = Duration(milliseconds: 2600);

  @override
  State<BossVignette> createState() => _BossVignetteState();
}

class _BossVignetteState extends State<BossVignette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: BossVignette.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BossVignette old) {
    super.didUpdateWidget(old);
    _sync();
  }

  bool get _still =>
      widget.calm || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  void _sync() {
    if (_still) {
      _breath
        ..stop()
        ..value = 0.5;
    } else if (!_breath.isAnimating) {
      unawaited(_breath.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _breath,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _EdgePainter(Curves.easeInOut.transform(_breath.value)),
      ),
    ),
  );
}

/// 화면 비율대로 늘린 타원 그라데이션: 가운데는 비우고 가장자리만 붉다.
class _EdgePainter extends CustomPainter {
  _EdgePainter(this.k);

  /// 숨 0~1.
  final double k;

  static const Color _red = Color(0xFFD8392B);

  @override
  void paint(Canvas canvas, Size size) {
    final edge = _red.withValues(alpha: 0.2 + 0.2 * k);
    final unit = Rect.fromCircle(center: Offset.zero, radius: 1);
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(size.width / 2, size.height / 2)
      ..drawRect(
        unit,
        Paint()
          ..shader = RadialGradient(
            radius: 0.6,
            colors: [_red.withValues(alpha: 0), edge],
            stops: const [0.68, 1],
          ).createShader(unit),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_EdgePainter old) => old.k != k;
}
