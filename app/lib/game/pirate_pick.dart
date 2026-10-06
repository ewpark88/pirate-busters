import 'package:flame/components.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/ship_view.dart';

/// 월드 좌표 [world] 에 가장 가까운 [ship] 해적 슬롯 (설계서 §2.2 “배 위 캐릭터”).
/// 몸 가운데에서 30px 안에 없으면 null.
int? nearestPirate(ShipView ship, Vector2 world) {
  int? best;
  var bestDist = 30.0 * 30.0;
  for (var slot = 0; slot < ship.rigs.length; slot++) {
    // 발 위치에서 몸 가운데(키의 절반 위)를 잡는다.
    final body =
        ship.rigs[slot].absolutePosition - Vector2(0, Coords.pirateHeight / 2);
    final d = body.distanceToSquared(world);
    if (d < bestDist) {
      bestDist = d;
      best = slot;
    }
  }
  return best;
}
