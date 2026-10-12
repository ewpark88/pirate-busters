import 'package:flutter/material.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 턴 타이머 숫자 (설계서 §2.3 “10초 남으면 경고, 5초부터 카운트다운”, §13.4, A34).
/// 10초부터 노랑, 5초부터 빨강이고, [pulse] 면 5초부터 초가 넘어갈 때마다 크게
/// 튀었다가 돌아오며 뒤에 붉은 빛이 번진다. 흔들림 줄이기([calm])면 튀지 않는다.
class TurnTimer extends StatelessWidget {
  const TurnTimer({
    required this.seconds,
    this.pulse = false,
    this.calm = false,
    super.key,
  });

  final int seconds;
  final bool pulse;
  final bool calm;

  /// 맥박을 시작하는 남은 초.
  static const int pulseFrom = 5;

  /// 튀는 크기와 길이.
  static const double pop = 1.45;
  static const Duration popTime = Duration(milliseconds: 450);

  Color get color => seconds <= pulseFrom
      ? HudColors.danger
      : (seconds <= 10 ? HudColors.warn : HudColors.text);

  @override
  Widget build(BuildContext context) {
    final text = Text('$seconds', style: TextStyle(color: color, fontSize: 22));
    if (!pulse || seconds > pulseFrom || seconds < 1) return text;
    return TweenAnimationBuilder<double>(
      key: ValueKey('timer-pulse-$seconds'),
      tween: Tween(begin: calm ? 1 : pop, end: 1),
      duration: popTime,
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: HudColors.danger.withValues(
                alpha: calm ? .25 : .25 + .5 * (v - 1) / (pop - 1),
              ),
              blurRadius: 14,
            ),
          ],
        ),
        child: Transform.scale(scale: v, child: child),
      ),
      child: text,
    );
  }
}
