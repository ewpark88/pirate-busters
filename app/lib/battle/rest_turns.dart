import 'package:pb_sim/pb_sim.dart';

/// [side] 진영 [slot] 해적이 쏠 수 있을 때까지 남은 쉬는 턴 수. 쿨다운이 없어져
/// (설계서 §2.3, ADR-111) 늘 0 이다. HUD 카드와 전장 머리 위 배지가 같은 값을 쓴다.
int restTurnsOf(SideState side, int slot) => 0;
