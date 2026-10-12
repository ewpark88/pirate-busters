import 'package:pb_sim/pb_sim.dart';

/// [side] 진영 [slot] 해적이 쏠 수 있을 때까지 남은 쉬는 턴 수 (설계서 §2.3·§13.4).
/// 0 이면 쉬지 않는다. 이번 턴에 쏜 해적은 이번 턴을 빼고 센다(ADR-092). 배 위에
/// 없으면 0. HUD 카드와 전장 머리 위 배지가 같은 값을 쓴다 (ADR-102).
int restTurnsOf(SideState side, int slot) {
  final p = side.crew.pirates[slot];
  if (p.status != PirateStatus.aboard) return 0;
  final left = side.crew.firedThisTurn[slot] ? p.cooldown - 1 : p.cooldown;
  return left < 0 ? 0 : left;
}
