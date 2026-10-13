import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pirate_busters/ui/hud/hud_gauge.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 연료 게이지 (설계서 §2.5 “내 턴이 시작될 때 가득 찬다”, BALANCE.md A2.7).
///
/// [HudGauge] 위에 1칸마다 눈금을 그어(연료 60·칸당 10 이면 여섯 칸) 몇 칸 갈 수 있는지
/// 글자 없이 보인다. 턴 시작에 다시 가득 차면 테가 한 번 빛난다.
class FuelGauge extends StatefulWidget {
  const FuelGauge({
    required this.value,
    required this.cells,
    this.preview,
    this.warnAt = 0,
    this.label,
    super.key,
  });

  /// 0~1.
  final double value;

  /// 가득 찼을 때 갈 수 있는 칸 수. 0 이면 눈금이 없다.
  final int cells;
  final double? preview;
  final double warnAt;
  final String? label;

  /// 다시 찰 때 테가 빛나는 시간.
  static const Duration glow = Duration(milliseconds: 450);

  @override
  State<FuelGauge> createState() => _FuelGaugeState();
}

class _FuelGaugeState extends State<FuelGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: FuelGauge.glow,
  );

  @override
  void didUpdateWidget(FuelGauge old) {
    super.didUpdateWidget(old);
    // 크게 다시 찼다(턴 시작): 테를 한 번 빛낸다.
    if (widget.value >= .999 && old.value < .95) {
      unawaited(_glow.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _glow,
    builder: (context, child) {
      final k = _glow.isAnimating ? 1 - _glow.value : 0.0;
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (k > 0)
              BoxShadow(
                color: HudColors.warn.withValues(alpha: .8 * k),
                blurRadius: 10 * k,
                spreadRadius: 1,
              ),
          ],
        ),
        child: child,
      );
    },
    child: Stack(
      children: [
        HudGauge(
          value: widget.value,
          color: HudColors.warn,
          preview: widget.preview,
          warnAt: widget.warnAt,
          jolts: false,
          label: widget.label,
        ),
        if (widget.cells > 1)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _CellTicks(widget.cells)),
            ),
          ),
      ],
    ),
  );
}

/// 칸 경계 눈금: 막대 위아래 끝의 짧은 금.
class _CellTicks extends CustomPainter {
  const _CellTicks(this.cells);

  final int cells;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x99101217)
      ..strokeWidth = 1.5;
    for (var i = 1; i < cells; i++) {
      final x = size.width * i / cells;
      // 가운데 글자를 가리지 않게 위아래 끝에만 짧게 긋는다.
      canvas
        ..drawLine(Offset(x, 1), Offset(x, 4), paint)
        ..drawLine(
          Offset(x, size.height - 4),
          Offset(x, size.height - 1),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_CellTicks old) => old.cells != cells;
}
