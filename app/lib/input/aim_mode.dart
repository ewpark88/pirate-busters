import 'package:pb_sim/pb_sim.dart';

/// 해적별 조준 각도 범위(밀리도, 위가 +, 아래쪽은 음수) (설계서 §2.2, §4.8).
/// 보통은 0~85°(보급탄도 상대에 쏜다, ADR-090), 어뢰(바라)는 물속으로 들어가도록
/// 아래 85° 부터.
(int min, int max) aimRangeFor(PirateSpec spec) {
  if (spec.ability == Ability.torpedo) return (-85000, 85000);
  return (0, 85000);
}

/// 조준 점선이 보여주는 궤적 비율(%) (설계서 §2.2, §3.3, §4.8, BALANCE.md A3.3·A4.2).
/// 지속 상태(만타 봉쇄 0%, 램프 100%)가 앞서고, 다음으로 망루·본즈 조준경 50%,
/// 그 밖에는 [base]%.
int trailPercentFor(SideState side, int slot, {required int base}) {
  final forced = side.trailOverride;
  if (forced >= 0) return forced;
  final spec = side.crew.pirates[slot].spec;
  if (side.hasLookout(slot) || spec.ability == Ability.scope) return 50;
  return base;
}

/// 화면에 보일 각도(도): 아래쪽(어뢰)은 음수로 쓴다.
int shownDegrees(int angleMdeg) {
  final a = angleMdeg > 180000 ? angleMdeg - 360000 : angleMdeg;
  return (a / 1000).round();
}
