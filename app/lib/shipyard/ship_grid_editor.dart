import 'package:flutter/material.dart';
import 'package:pirate_busters/shipyard/ship_grid_view.dart';
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
            builder: (context, _) => ShipGridView(model: model, cell: cell),
          ),
        ),
      );
    },
  );
}

/// 설계도 격자 그림. 바탕([overlay] 가 아니면)은 칸 선과 재질 색, 겹([overlay])은
/// 끊긴 블록의 빨간 테두리와 흘수선이다. 재질 타일·선실·모듈 그림은 [ShipGridView] 가
/// 그 사이에 겹친다.
class ShipGridPainter extends CustomPainter {
  ShipGridPainter(this.model, this.cell, {this.overlay = false})
    : loose = model.loose;

  final ShipyardModel model;
  final double cell;
  final bool overlay;
  final Set<int> loose;

  static final Paint _line = Paint()
    ..color = const Color(0x33FFFFFF)
    ..style = PaintingStyle.stroke;
  static final Paint _red = Paint()
    ..color = const Color(0xFFE0402F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _pole = Paint()..color = const Color(0xFF8B5A2B);
  static final Paint _water = Paint()
    ..color = const Color(0xCC3FA9F5)
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final h = model.height;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < model.width; x++) {
        // 선체 틀 밖 칸은 그리지 않아 격자가 배 모양으로 보인다 (설계서 §3.4).
        if (!model.hull.inFrame(x, y)) continue;
        final r = Rect.fromLTWH(x * cell, (h - 1 - y) * cell, cell, cell);
        final m = model.materialAt(x, y);
        if (!overlay) {
          canvas.drawRect(r, _line);
          if (m != null) {
            canvas.drawRect(
              r.deflate(1),
              Paint()..color = Labels.materialColor(m),
            );
          }
        } else if (m != null && loose.contains(y * model.width + x)) {
          canvas.drawRect(r.deflate(2), _red);
        }
      }
    }
    if (!overlay) return;
    // 돛대 칸 (설계서 §3.3): 기둥으로 보이고, 블록과 겹치면 빨간 칸, 꼭대기는 돛 자리.
    final seats = model.seatCells;
    for (final (x, y) in model.rigCells) {
      final r = Rect.fromLTWH(x * cell, (h - 1 - y) * cell, cell, cell);
      canvas.drawRect(
        Rect.fromCenter(center: r.center, width: cell * 0.22, height: cell),
        _pole,
      );
      if (model.materialAt(x, y) != null) canvas.drawRect(r.deflate(2), _red);
      if (seats.contains(y * model.width + x)) {
        canvas.drawRect(
          Rect.fromLTRB(
            r.left + 3,
            r.bottom - cell * 0.2,
            r.right - 3,
            r.bottom,
          ),
          _pole,
        );
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

  @override
  bool shouldRepaint(covariant ShipGridPainter old) => true;
}
