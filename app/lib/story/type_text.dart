import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';

/// 대사 한 자씩 나오기 상태 (설계서 §15.4 컷신, A55). 컷마다 새로 만든다.
class TypeController extends ChangeNotifier {
  bool _done = false;

  /// 끝까지 다 나왔다.
  bool get done => _done;

  /// 남은 글자를 한 번에 보인다(누르면).
  void finish() {
    if (_done) return;
    _done = true;
    notifyListeners();
  }
}

/// [text] 를 한 자씩([perSecond] 자/초) 보여 준다. [controller] 가 끝나면 전부 보인다.
/// 움직임 끄기(저사양)면 처음부터 다 보인다. 글자 칸은 처음부터 전체 크기로 잡아
/// 말풍선이 출렁이지 않는다.
class TypeText extends StatefulWidget {
  const TypeText({
    required this.text,
    required this.controller,
    this.style,
    this.perSecond = 36,
    super.key,
  });

  final String text;
  final TypeController controller;
  final TextStyle? style;
  final double perSecond;

  @override
  State<TypeText> createState() => _TypeTextState();
}

class _TypeTextState extends State<TypeText> {
  Timer? _timer;
  int _shown = 0;

  int get _total => widget.text.characters.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || widget.controller.done) return;
    if (KitMotion.reducedOf(context)) {
      widget.controller.finish();
      return;
    }
    final step = Duration(microseconds: (1e6 / widget.perSecond).round());
    _timer = Timer.periodic(step, (_) {
      if (!mounted) return;
      setState(() => _shown++);
      if (_shown >= _total) widget.controller.finish();
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onDone);
  }

  void _onDone() {
    if (!widget.controller.done) return;
    _timer?.cancel();
    if (mounted) setState(() => _shown = _total);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onDone);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.controller.done ? _total : _shown.clamp(0, _total);
    final visible = widget.text.characters.take(shown).toString();
    final hidden = widget.text.characters.skip(shown).toString();
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          TextSpan(text: visible),
          // 아직 안 나온 글자는 투명하게 둬서 칸 크기가 변하지 않는다.
          TextSpan(
            text: hidden,
            style: const TextStyle(color: Color(0x00000000)),
          ),
        ],
      ),
    );
  }
}

/// 옆에서 미끄러져 들어오는 등장 (컷신 해적, A55). [fromLeft] 면 왼쪽에서.
class SlideIn extends StatelessWidget {
  const SlideIn({required this.child, required this.fromLeft, super.key});

  final Widget child;
  final bool fromLeft;

  static const Duration duration = Duration(milliseconds: 380);

  @override
  Widget build(BuildContext context) {
    if (KitMotion.reducedOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset((fromLeft ? -48 : 48) * (1 - t), 0),
          child: child,
        ),
      ),
    );
  }
}
