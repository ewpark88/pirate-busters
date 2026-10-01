import 'package:flutter/material.dart';
import 'package:pirate_busters/shipyard/shipyard_model.dart';
import 'package:pirate_busters/ui/labels.dart';

/// 조선소 격자 (설계서 §13.6): 누르면 설치, 끌면 연속 설치, 길게 누르면 삭제.
/// 용골과 끊긴 블록은 빨간 테두리, 흘수선은 파란 선으로 보인다. y = 0(용골)이 아래.
class ShipGridEditor extends StatelessWidget {
  const ShipGridEditor({required this.model, super.key});

  final ShipyardModel model;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cell = (box.maxWidth / model.width)
          .clamp(0, box.maxHeight / model.height)
          .toDouble();
      final size = Size(cell * model.width, cell * model.height);
      (int, int) at(Offset p) =>
          (p.dx ~/ cell, model.height - 1 - (p.dy ~/ cell));
      return Center(
        child: GestureDetector(
          onTapUp: (d) {
            final (x, y) = at(d.localPosition);
            model.apply(x, y);
          },
          onPanStart: (d) {
            model.beginStroke();
            final (x, y) = at(d.localPosition);
            model.apply(x, y);
          },
          onPanUpdate: (d) {
            final (x, y) = at(d.localPosition);
            model.apply(x, y);
          },
          onPanEnd: (_) => model.endStroke(),
          onPanCancel: model.endStroke,
          onLongPressStart: (d) {
            final (x, y) = at(d.localPosition);
            model.eraseAt(x, y);
          },
          child: ListenableBuilder(
            listenable: model,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: ShipGridPainter(model, cell),
            ),
          ),
        ),
      );
    },
  );
}

/// 설계도 격자 그림: 재질 칸, 선실 번호·사람, 모듈 아이콘, 흘수선. 조선소와 전투 준비
/// 미리보기(`BlueprintPreview`)가 같이 쓴다.
class ShipGridPainter extends CustomPainter {
  ShipGridPainter(this.model, this.cell) : loose = model.loose;

  final ShipyardModel model;
  final double cell;
  final Set<int> loose;

  static final Paint _line = Paint()
    ..color = const Color(0x33FFFFFF)
    ..style = PaintingStyle.stroke;
  static final Paint _red = Paint()
    ..color = const Color(0xFFE0402F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _water = Paint()
    ..color = const Color(0xCC3FA9F5)
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final h = model.height;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < model.width; x++) {
        final r = Rect.fromLTWH(x * cell, (h - 1 - y) * cell, cell, cell);
        canvas.drawRect(r, _line);
        final m = model.materialAt(x, y);
        if (m == null) continue;
        canvas.drawRect(
          r.deflate(1),
          Paint()..color = Labels.materialColor(m),
        );
        if (loose.contains(y * model.width + x)) {
          canvas.drawRect(r.deflate(2), _red);
        }
        _drawMarks(canvas, r, x, y);
      }
    }
    // 흘수선: 무게로 정해지는 잠긴 깊이 (설계서 §3.4).
    final wl = model.stats.waterline / 1000 * cell;
    canvas.drawLine(
      Offset(0, size.height - wl),
      Offset(size.width, size.height - wl),
      _water,
    );
  }

  void _drawMarks(Canvas canvas, Rect r, int x, int y) {
    final slot = model.cabinSlotAt(x, y);
    final module = model.moduleAt(x, y);
    if (slot >= 0) {
      _text(canvas, '${slot + 1}', r.topLeft + const Offset(3, 1));
      _icon(canvas, Icons.person, r, 0.55, const Color(0xFF15171D));
    }
    if (module != null) {
      _icon(
        canvas,
        Labels.moduleIcon(module),
        slot >= 0
            ? Rect.fromLTWH(r.center.dx, r.top, r.width / 2, r.height / 2)
            : r,
        slot >= 0 ? 0.9 : 0.6,
        const Color(0xFF15171D),
      );
    }
  }

  void _icon(Canvas canvas, IconData icon, Rect r, double scale, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: r.height * scale,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
  }

  void _text(Canvas canvas, String text, Offset at) {
    TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: cell * 0.3,
            color: const Color(0xFF15171D),
          ),
        ),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant ShipGridPainter old) => true;
}
