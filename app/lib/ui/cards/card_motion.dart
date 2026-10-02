import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// 등급 카드 움직임의 공용 시계 (설계서 §10.5). 앱 루트에 한 번 두면 화면의 모든
/// 카드가 이 시계 하나로 움직인다(카드마다 티커를 만들지 않는다). 이 위젯이 위에
/// 없거나 [enabled] 가 꺼져 있으면(저사양 모드 §12) 카드는 멈춘 그림으로 보인다.
class CardMotion extends StatefulWidget {
  const CardMotion({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  /// 흐른 시간(초). 시계가 없으면 null.
  static ValueListenable<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CardClock>()?.seconds;

  @override
  State<CardMotion> createState() => _CardMotionState();
}

class _CardMotionState extends State<CardMotion>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _seconds = ValueNotifier(0);
  late final Ticker _ticker = createTicker(
    (elapsed) => _seconds.value = elapsed.inMicroseconds / 1e6,
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) unawaited(_ticker.start());
  }

  @override
  void didUpdateWidget(CardMotion old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_ticker.isActive) {
      unawaited(_ticker.start());
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _CardClock(seconds: _seconds, child: widget.child);
}

class _CardClock extends InheritedWidget {
  const _CardClock({required this.seconds, required super.child});

  final ValueListenable<double> seconds;

  @override
  bool updateShouldNotify(_CardClock old) => seconds != old.seconds;
}
