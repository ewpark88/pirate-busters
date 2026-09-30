import 'dart:ui';

/// 블록 손상 3단계(금간·구멍·파괴)를 재질 타일 위에 코드로 덧그린다
/// (설계서 §10.2, ADR-030). 칸마다 `seed` 로 모양을 조금씩 바꾼다.
abstract final class DamagePainter {
  static final Paint _crack = Paint()
    ..color = const Color(0xE0140C08)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  static final Paint _hole = Paint()..color = const Color(0xF0120A06);
  static final Paint _rim = Paint()
    ..color = const Color(0xFF6A4128)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  static final Paint _broken = Paint()..color = const Color(0x8C120A06);

  /// 금간: 가장자리에서 들어오는 갈라진 금 두 줄.
  static void cracked(Canvas canvas, Rect r, int seed) {
    final o = (seed % 5) / 10;
    canvas
      ..drawPath(
        Path()
          ..moveTo(r.left + r.width * (0.1 + o), r.top)
          ..lineTo(r.left + r.width * 0.35, r.top + r.height * 0.3)
          ..lineTo(r.left + r.width * 0.3, r.top + r.height * 0.55)
          ..lineTo(r.left + r.width * 0.5, r.top + r.height * 0.7),
        _crack,
      )
      ..drawPath(
        Path()
          ..moveTo(r.right, r.top + r.height * (0.4 + o))
          ..lineTo(r.left + r.width * 0.7, r.top + r.height * 0.5)
          ..lineTo(r.left + r.width * 0.6, r.top + r.height * 0.8),
        _crack,
      );
  }

  /// 구멍: 금 + 가운데 뚫린 구멍.
  static void holed(Canvas canvas, Rect r, int seed) {
    cracked(canvas, r, seed);
    final c = r.center.translate((seed % 3 - 1) * 3.0, (seed % 4 - 1.5) * 2);
    final w = r.width * 0.26;
    final hole = Path()
      ..moveTo(c.dx - w, c.dy - w * 0.4)
      ..lineTo(c.dx - w * 0.3, c.dy - w)
      ..lineTo(c.dx + w * 0.8, c.dy - w * 0.6)
      ..lineTo(c.dx + w, c.dy + w * 0.3)
      ..lineTo(c.dx + w * 0.2, c.dy + w)
      ..lineTo(c.dx - w * 0.9, c.dy + w * 0.6)
      ..close();
    canvas
      ..drawPath(hole, _hole)
      ..drawPath(hole, _rim);
  }

  /// 파괴: 블록이 없어진 칸. 부서진 가장자리 그림자만 남긴다.
  static void broken(Canvas canvas, Rect r, int seed) {
    final j = (seed % 4) * 1.5;
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left, r.top + r.height * 0.6 + j)
        ..lineTo(r.left + r.width * 0.3, r.top + r.height * 0.75)
        ..lineTo(r.left + r.width * 0.55, r.top + r.height * 0.55 - j)
        ..lineTo(r.right, r.top + r.height * 0.7)
        ..lineTo(r.right, r.bottom)
        ..close(),
      _broken,
    );
  }
}
