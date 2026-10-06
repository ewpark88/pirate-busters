import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pirate_busters/battle/battle_session.dart';

/// 튜토리얼 손가락 안내가 가리키는 것 (설계서 §13.1).
enum FingerCue {
  /// 해적 카드를 누른다.
  tapCard,

  /// 배 위 해적을 누른 채 뒤로 당긴다.
  pullBack,

  /// 이동 버튼을 누른다(튜토리얼 2).
  move,

  /// 침수량을 본다(튜토리얼 3).
  flood,
}

/// 튜토리얼 손가락 안내 (설계서 §13.1): 지금 해야 할 조작을 화면에서 가리킨다.
/// 단계마다 한 번 끝까지(첫 발사·첫 이동) 해 보면 사라진다. 그리기만 한다.
class TutorialFinger extends StatefulWidget {
  const TutorialFinger({required this.session, required this.step, super.key});

  final BattleSession session;

  /// 튜토리얼 번호 1~3.
  final int step;

  /// [session] 의 지금 상태에서 가리킬 것. 없으면 null.
  static FingerCue? cueOf(BattleSession session, int step) {
    if (!session.isHumanTurn || session.playback != null || session.isOver) {
      return null;
    }
    final me = session.state.sides[session.activeSide];
    if (step == 2 && me.offset == 0 && me.shotsFired == 0) {
      return FingerCue.move;
    }
    if (step == 3 && me.flood > 0 && me.shotsFired == 0) return FingerCue.flood;
    if (me.shotsFired > 0 || session.aim != null) return null;
    return session.selected == null ? FingerCue.tapCard : FingerCue.pullBack;
  }

  @override
  State<TutorialFinger> createState() => _TutorialFingerState();
}

class _TutorialFingerState extends State<TutorialFinger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ListenableBuilder(
      listenable: Listenable.merge([widget.session, _loop]),
      builder: (context, _) {
        final cue = TutorialFinger.cueOf(widget.session, widget.step);
        if (cue == null) return const SizedBox.shrink();
        return CustomPaint(
          size: Size.infinite,
          painter: _FingerPainter(cue, _loop.value),
        );
      },
    ),
  );
}

class _FingerPainter extends CustomPainter {
  _FingerPainter(this.cue, this.t);

  final FingerCue cue;
  final double t;

  static final Paint _dot = Paint()..color = const Color(0xEEFFFFFF);
  static final Paint _edge = Paint()
    ..color = const Color(0xFF14161C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  Offset _at(Size s, Alignment a) => a.alongSize(s);

  @override
  void paint(Canvas canvas, Size size) {
    switch (cue) {
      case FingerCue.tapCard:
        _tap(canvas, _at(size, const Alignment(-0.1, 0.78)));
      case FingerCue.move:
        _tap(canvas, _at(size, const Alignment(-0.7, 0.82)));
      case FingerCue.flood:
        _tap(canvas, _at(size, const Alignment(-0.82, -0.78)));
      case FingerCue.pullBack:
        // 해적에서 뒤(왼쪽 아래)로 당기는 길을 따라 점이 움직인다.
        final from = _at(size, const Alignment(-0.12, 0.05));
        final to = _at(size, const Alignment(-0.42, 0.32));
        final p = Offset.lerp(from, to, Curves.easeInOut.transform(t))!;
        canvas
          ..drawLine(
            from,
            to,
            Paint()
              ..color = const Color(0x99FFFFFF)
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round,
          )
          ..drawCircle(p, 13, _dot)
          ..drawCircle(p, 13, _edge);
    }
  }

  /// 누르기: 커졌다 사라지는 고리와 가운데 점.
  void _tap(Canvas canvas, Offset c) {
    final ring = 14 + 22 * t;
    canvas
      ..drawCircle(
        c,
        ring,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, math.max(0, 1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      )
      ..drawCircle(c, 12, _dot)
      ..drawCircle(c, 12, _edge);
  }

  @override
  bool shouldRepaint(covariant _FingerPainter old) =>
      old.cue != cue || old.t != t;
}
