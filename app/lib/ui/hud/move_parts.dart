import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';
import 'package:pirate_busters/ui/meta_icons.dart';

/// 누르고 있는 동안 움직이는 둥근 버튼 (A33): 진영색 테, 누르면 작아지며 안쪽이
/// 밝게 빛난다. 잠기면 흐려진다.
class HoldButton extends StatelessWidget {
  const HoldButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.held,
    required this.onDown,
    required this.onUp,
    super.key,
  });

  final String label;

  /// 화면 방향 화살표 그림 (`MetaIcons.moveBack` ← · `moveForward` →).
  final String icon;
  final Color color;
  final bool enabled;

  /// 지금 누르고 있다.
  final bool held;
  final VoidCallback onDown;
  final VoidCallback onUp;

  static const double size = 50;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => onDown(),
    onPointerUp: (_) => onUp(),
    onPointerCancel: (_) => onUp(),
    child: Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: held ? .9 : 1,
            duration: const Duration(milliseconds: 80),
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, -.35),
                  colors: held
                      ? [Color.lerp(color, Colors.white, .45)!, color]
                      : [HudColors.panelHi, const Color(0xFF101217)],
                ),
                border: Border.all(color: color, width: 2.5),
                boxShadow: [
                  if (held)
                    BoxShadow(
                      color: color.withValues(alpha: .7),
                      blurRadius: 10,
                    )
                  else
                    const BoxShadow(
                      color: Color(0x99000000),
                      offset: Offset(0, 2),
                      blurRadius: 2,
                    ),
                ],
              ),
              child: MetaIcons.image(icon, size: 30),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

/// 켜져 있으면 깜빡인다.
class Blink extends StatefulWidget {
  const Blink({required this.on, required this.child, super.key});

  final bool on;
  final Widget child;

  @override
  State<Blink> createState() => _BlinkState();
}

class _BlinkState extends State<Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: 0.2,
  ).animate(_c);

  @override
  void initState() {
    super.initState();
    if (widget.on) unawaited(_c.repeat(reverse: true));
  }

  @override
  void didUpdateWidget(Blink old) {
    super.didUpdateWidget(old);
    if (widget.on && !_c.isAnimating) {
      unawaited(_c.repeat(reverse: true));
    } else if (!widget.on && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: widget.child,
  );
}
