import 'dart:ui' show Offset;

import 'package:flame/components.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 발 위치 [feet] 에서 몸 가운데(키의 절반 위). 잡기·튜토리얼 안내가 같은 점을 쓴다.
Vector2 pirateBody(Vector2 feet) => feet - Vector2(0, Coords.pirateHeight / 2);

/// 카드로 고른 해적 [slot] 의 발 위치(월드 px). 카메라가 그 해적으로 줌인한다
/// (설계서 §2.2, ADR-033). 없으면 null.
Vector2? focusFeetOf(ShipView ship, int? slot) =>
    slot != null && slot < ship.rigs.length
    ? ship.rigs[slot].absolutePosition
    : null;

/// 고른 해적 [slot] 몸 가운데의 화면 좌표 (튜토리얼 당기기 안내, 설계서 §13.1).
Offset? pirateScreen(ShipView ship, int? slot, CameraComponent camera) {
  final feet = focusFeetOf(ship, slot);
  if (feet == null) return null;
  final p = camera.localToGlobal(pirateBody(feet));
  return Offset(p.x, p.y);
}

/// 월드 좌표 [world] 에 가장 가까운 [ship] 해적 슬롯 (설계서 §2.2 “배 위 캐릭터”).
/// 몸 가운데에서 30px 안에 없으면 null.
int? nearestPirate(ShipView ship, Vector2 world) {
  int? best;
  var bestDist = 30.0 * 30.0;
  for (var slot = 0; slot < ship.rigs.length; slot++) {
    final d = pirateBody(
      ship.rigs[slot].absolutePosition,
    ).distanceToSquared(world);
    if (d < bestDist) {
      bestDist = d;
      best = slot;
    }
  }
  return best;
}
