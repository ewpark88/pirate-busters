import 'package:flutter/widgets.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/game/view/rarity_painter.dart';

/// 등급 별 줄 (설계서 §10.5 ‘색 말고 모양’, A37): 일반 1 ~ 신화 5 개의 별.
/// 작은 HUD 카드처럼 프레임 별이 읽히지 않는 곳에 얹는다.
class RarityStars extends StatelessWidget {
  const RarityStars({required this.rarity, this.radius = 4, super.key});

  final Rarity rarity;
  final double radius;

  int get count => RarityPainter.starsOf(rarity.index);

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(radius * 2.3 * count, radius * 2),
    painter: _StarsPainter(count, radius),
  );
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.count, this.radius);

  final int count;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) =>
      RarityPainter.starRow(canvas, size.center(Offset.zero), count, radius);

  @override
  bool shouldRepaint(_StarsPainter old) =>
      old.count != count || old.radius != radius;
}
