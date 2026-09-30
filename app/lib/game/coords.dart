import 'package:flame/components.dart';
import 'package:pb_sim/pb_sim.dart';

/// 시뮬레이션 좌표(1/1000칸, 위가 +) → 화면 월드 px(1칸 32px, 아래가 +).
/// 해수면이 y = 0 이다. 에셋은 @2x 라 이미지 px ÷ 2 가 월드 px 다 (docs/ASSETS.md).
abstract final class Coords {
  /// 1칸의 월드 px (에셋 tokens.json `design.cell`).
  static const double cell = 32;

  static double x(num simX) => simX * cell / cellUnit;

  static double y(num simY) => -simY * cell / cellUnit;

  static Vector2 point(num simX, num simY) => Vector2(x(simX), y(simY));

  /// 이미지 px(@2x) → 월드 px.
  static double image(num px) => px / 2;
}
