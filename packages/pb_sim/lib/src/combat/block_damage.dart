import 'package:pb_sim/src/match/sim_event.dart';
import 'package:pb_sim/src/ship/ship_grid.dart';

/// [side] 배 [grid] 의 칸 ([x], [y]) 에 [amount] 피해를 준다. 깎인 양을
/// [SimEventKind.blockHit] 으로, 부서지면 [SimEventKind.blockDestroyed] 를 남긴다.
/// 블록이 이번에 파괴됐으면 true. 이벤트는 렌더용이라 판정에는 영향이 없다.
bool damageBlock(
  ShipGrid grid,
  int side,
  int x,
  int y,
  int amount,
  List<SimEvent> events,
) {
  if (!grid.hasBlock(x, y) || amount <= 0) return false;
  final i = grid.indexOf(x, y);
  final hp = grid.hpAt(x, y);
  final broke = grid.damage(x, y, amount);
  final left = broke ? 0 : grid.hpAt(x, y);
  events.add(
    SimEvent(
      SimEventKind.blockHit,
      side: side,
      cell: i,
      y: left,
      value: hp - left,
    ),
  );
  if (broke) {
    events.add(SimEvent(SimEventKind.blockDestroyed, side: side, cell: i));
  }
  return broke;
}
