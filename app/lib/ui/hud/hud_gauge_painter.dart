import 'package:flutter/rendering.dart';
import 'package:pirate_busters/ui/hud/hud_style.dart';

/// 게이지 그림. [front]·[trail]·[preview] 는 0~1.
class GaugePainter extends CustomPainter {
  GaugePainter({
    required this.front,
    required this.trail,
    required this.color,
    this.preview,
    this.hit = 0,
    this.rising = false,
  });

  final double front;

  /// 잔상이 찬 몫(초록)이다. 아니면 깎인 몫(빨강).
  final bool rising;
  final double trail;
  final double? preview;
  final Color color;

  /// 맞은 번쩍임 0~1.
  final double hit;

  static const Color groove = Color(0xFF0B0C10);
  static const Color loss = Color(0xFFE5483A);
  static const Color gain = Color(0xFF7CE07A);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final outer = RRect.fromRectAndRadius(Offset.zero & size, r);
    final inner = outer.deflate(1.5);
    // 홈: 위가 더 어두운 그라데이션(안쪽 그림자).
    canvas
      ..drawRRect(outer, Paint()..color = const Color(0xFF000000))
      ..drawRRect(
        inner,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [groove, HudColors.panelHi],
          ).createShader(inner.outerRect),
      )
      ..save()
      ..clipRRect(inner);
    final box = inner.outerRect;
    Rect upTo(double v) => Rect.fromLTWH(
      box.left,
      box.top,
      box.width * v.clamp(0.0, 1.0),
      box.height,
    );
    // 잔상: 깎인 몫은 흰빛에서 빨강으로, 찬 몫은 초록.
    if (trail > front) {
      final ghost = Rect.fromLTRB(
        upTo(front).right,
        box.top,
        upTo(trail).right,
        box.bottom,
      );
      canvas.drawRect(
        ghost,
        Paint()
          ..color = rising
              ? gain
              : Color.lerp(loss, const Color(0xFFFFFFFF), hit * .7)!,
      );
    }
    final fill = upTo(front);
    canvas.drawRect(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, const Color(0xFFFFFFFF), .35)!,
            color,
            Color.lerp(color, const Color(0xFF000000), .35)!,
          ],
          stops: const [0, .45, 1],
        ).createShader(box),
    );
    // 줄어들 몫(이동 미리보기)은 어둡게 덮고 끝에 흰 금을 긋는다.
    final p = preview;
    if (p != null && p < front) {
      final cut = Rect.fromLTRB(
        upTo(p).right,
        box.top,
        fill.right,
        box.bottom,
      );
      canvas
        ..drawRect(cut, Paint()..color = const Color(0x8C000000))
        ..drawRect(
          Rect.fromLTWH(cut.left - .75, box.top, 1.5, box.height),
          Paint()..color = const Color(0xFFFFFFFF),
        );
    }
    // 위쪽 하이라이트 줄.
    canvas.drawRect(
      Rect.fromLTWH(box.left, box.top + 1, fill.width, box.height * .22),
      Paint()..color = const Color(0x40FFFFFF),
    );
    // 10% 눈금.
    final tick = Paint()..color = const Color(0x59000000);
    for (var i = 1; i < 10; i++) {
      final x = box.left + box.width * i / 10;
      canvas.drawRect(
        Rect.fromLTWH(x - .5, box.top + box.height * .55, 1, box.height),
        tick,
      );
    }
    // 테두리: 맞으면 하얗게 번쩍인다.
    canvas
      ..restore()
      ..drawRRect(
        outer.deflate(.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Color.lerp(
            const Color(0x99C9962E),
            const Color(0xFFFFFFFF),
            hit,
          )!,
      );
  }

  @override
  bool shouldRepaint(GaugePainter old) =>
      old.front != front ||
      old.trail != trail ||
      old.preview != preview ||
      old.color != color ||
      old.hit != hit ||
      old.rising != rising;
}
