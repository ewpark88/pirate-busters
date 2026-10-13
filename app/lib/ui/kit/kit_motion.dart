import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pirate_busters/ui/kit/kit_sound.dart';

/// 메타 화면 움직임 설정 (설계서 §13 공통 화면 규칙). 저사양 모드(§12)면 줄인다.
class KitMotion extends InheritedWidget {
  const KitMotion({required this.reduced, required super.child, super.key});

  /// true 면 등장·눌림·세어 올리기를 바로 끝낸다.
  final bool reduced;

  /// 앱 루트가 [KitMotion] 을 둔다. 없으면(위젯 테스트) 움직이지 않는다.
  static bool reducedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitMotion>()?.reduced ?? true;

  @override
  bool updateShouldNotify(KitMotion old) => old.reduced != reduced;
}

/// 화면 전환: 이전 화면이 먼저 사라지고 새 화면이 짧게 밀며 나타난다 (설계서 §13 공통).
///
/// 새 화면만 투명에서 나타나게 하면 그동안 아래 화면이 비쳐 두 화면이 겹친 잔상이
/// 생긴다(A42). 이전 화면은 [split] 까지 사라지고, 새 화면은 그 뒤에 나타난다.
/// `fullscreenDialog` 경로는 아래 화면의 secondaryAnimation 이 움직이지 않아
/// 이전 화면이 그대로 남으므로 쓰지 않는다(A58).
class KitPageTransitions extends PageTransitionsBuilder {
  const KitPageTransitions();

  /// 이전 화면이 다 사라지고 새 화면이 나타나기 시작하는 지점(전환 진행 0~1).
  static const double split = 0.4;

  /// 전환 진행 [t] 에서 새 화면·이전 화면의 진하기. 두 값이 함께 0 보다 큰 때가 없다.
  static double incoming(double t) =>
      Curves.easeOut.transform(((t - split) / (1 - split)).clamp(0, 1));
  static double outgoing(double t) =>
      1 - Curves.easeIn.transform((t / split).clamp(0, 1));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (KitMotion.reducedOf(context)) return child;
    final slide = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) => Opacity(
        opacity: incoming(animation.value) * outgoing(secondaryAnimation.value),
        child: FractionalTranslation(
          translation: Offset(0.06 * (1 - slide.value), 0),
          child: child,
        ),
      ),
    );
  }
}

/// 튕기며 나타나는 패널·카드 (설계서 §13 공통). [order] 순서대로 조금씩 늦게 나온다.
class PopIn extends StatefulWidget {
  const PopIn({required this.child, this.order = 0, super.key});

  final Widget child;
  final int order;

  /// 한 칸 늦출 때마다 더하는 시간.
  static const Duration step = Duration(milliseconds: 60);
  static const Duration duration = Duration(milliseconds: 380);

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: PopIn.duration,
  );
  bool _started = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (KitMotion.reducedOf(context)) {
      _c.value = 1;
    } else {
      _timer = Timer(PopIn.step * widget.order, () {
        if (mounted) unawaited(_c.forward());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final t = _c.value;
      return Opacity(
        opacity: Curves.easeOut.transform(t.clamp(0, 1)),
        child: Transform.scale(
          scale: 0.86 + 0.14 * Curves.elasticOut.transform(t),
          child: child,
        ),
      );
    },
  );
}

/// 누르면 살짝 줄었다 돌아오고 누름 소리를 내는 감싸개 (설계서 §13 공통, §10.3).
/// 소리는 위의 [KitSound] 가 낸다(A55).
class Pressable extends StatefulWidget {
  const Pressable({required this.child, required this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: widget.onTap == null
        ? HitTestBehavior.deferToChild
        : HitTestBehavior.opaque,
    onTapDown: (_) => _set(true),
    onTapUp: (_) => _set(false),
    onTapCancel: () => _set(false),
    onTap: widget.onTap == null
        ? null
        : () {
            KitSound.clickOf(context);
            widget.onTap!();
          },
    child: AnimatedScale(
      scale: _down ? 0.93 : 1,
      duration: KitMotion.reducedOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 90),
      child: widget.child,
    ),
  );
}

/// 0 에서 [value] 까지 세어 올라가는 숫자 (설계서 §13 공통, §13.5).
class CountUp extends StatelessWidget {
  const CountUp({
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
    super.key,
  });

  final int value;
  final Duration duration;
  final Widget Function(BuildContext context, int shown) builder;

  @override
  Widget build(BuildContext context) {
    if (KitMotion.reducedOf(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(context, v.round()),
    );
  }
}
