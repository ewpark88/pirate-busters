import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart' show facingOf;
import 'package:pirate_busters/battle/battle_session.dart';

/// 튜토리얼 손가락 안내가 가리키는 것 (설계서 §13.1).
enum FingerCue {
  /// 해적 카드를 누른다.
  tapCard,

  /// 배 위 해적을 누른 채 뒤로 당긴다.
  pullBack,

  /// 이동 버튼을 누른다(튜토리얼 2).
  move,
}

/// 튜토리얼 손가락 안내 (설계서 §13.1): 지금 해야 할 조작을 화면에서 가리킨다.
/// 단계마다 한 번 끝까지(첫 발사·첫 이동) 해 보면 사라진다. 그리기만 한다.
class TutorialFinger extends StatefulWidget {
  const TutorialFinger({
    required this.session,
    required this.step,
    this.pullAnchor,
    super.key,
  });

  final BattleSession session;

  /// 튜토리얼 번호 1~3.
  final int step;

  /// 고른 해적 몸 가운데의 화면 좌표. 당기기 안내가 여기서 시작한다. 없으면 안 그린다.
  final Offset? Function()? pullAnchor;

  /// 당기기 안내 길(화면 px): 해적 [from] 에서 뒤(−[facing])·아래로. `PullAim` 의
  /// 당김 방향과 같고 최대 당김(160px)보다 짧다.
  static (Offset, Offset) pullPath(Offset from, int facing) =>
      (from, from + Offset(-facing * 70.0, 55));

  /// [session] 의 지금 상태에서 가리킬 것. 없으면 null.
  static FingerCue? cueOf(BattleSession session, int step) {
    if (!session.isHumanTurn || session.playback != null || session.isOver) {
      return null;
    }
    final me = session.state.sides[session.activeSide];
    // 2판(이동과 바람)·3판(파도 구간)은 먼저 이동 버튼을 가리킨다 (설계서 §13.1).
    if (step >= 2 && me.offset == 0 && me.shotsFired == 0) {
      return FingerCue.move;
    }
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
        (Offset, Offset)? pull;
        if (cue == FingerCue.pullBack) {
          final at = widget.pullAnchor?.call();
          if (at == null) return const SizedBox.shrink();
          final facing = facingOf(widget.session.state.activeSide);
          pull = TutorialFinger.pullPath(at, facing);
        }
        return CustomPaint(
          size: Size.infinite,
          painter: _FingerPainter(cue, _loop.value, pull),
        );
      },
    ),
  );
}

class _FingerPainter extends CustomPainter {
  _FingerPainter(this.cue, this.t, this.pull);

  final FingerCue cue;
  final double t;

  /// 당기기 안내 길(시작·끝 화면 좌표).
  final (Offset, Offset)? pull;

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
        // 꾹 누르기: 손가락 둘레에 채워지는 원호 (A25 점검: 누르기로만 보였다).
        _hold(canvas, _at(size, const Alignment(-0.7, 0.82)));
      case FingerCue.pullBack:
        // 고른 해적 몸에서 뒤·아래로 당기는 길을 따라 점이 움직인다.
        final path = pull;
        if (path == null) return;
        final (from, to) = path;
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

  /// 꾹 누르기: 가운데 점 둘레에 원호가 차오른다.
  void _hold(Canvas canvas, Offset c) {
    canvas
      ..drawArc(
        Rect.fromCircle(center: c, radius: 22),
        -math.pi / 2,
        2 * math.pi * t,
        false,
        Paint()
          ..color = const Color(0xFFFFC24A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(c, 12, _dot)
      ..drawCircle(c, 12, _edge);
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
      old.cue != cue || old.t != t || old.pull != pull;
}
