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

  /// 전투 해적 배율(캐릭터 캔버스 px → 월드 px). 캔버스 240×324 가 약 22×29px,
  /// 키 약 0.9칸이라 선실 한 칸 안에 든다 (설계서 §10.1, ADR-057).
  static const double pirateScale = 0.09;

  /// 해적 발에서 머리 끝까지(월드 px). 캔버스 기준점은 발(120, 315)이다.
  static const double pirateHeight = 315 * pirateScale;

  /// 선실 칸 바닥에서 해적 발까지(월드 px).
  static const double cabinFloor = 3;
}
