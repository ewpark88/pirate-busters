import 'package:pb_sim/pb_sim.dart';

/// 명중 이름표 (설계서 §10.4): 치명·관통·연쇄처럼 특별한 결과를 피해 숫자 아래에
/// 붙인다. 어떤 글자로 보일지는 화면이 l10n 으로 정한다(§14). 판정과 무관하다.
enum HitTag {
  /// 저격탄이 해적을 맞혔다(치명 배율).
  crit,
  pierce,
  chain,
  burn,
  mine,

  /// 붙은 설치탄·떠 있는 기뢰가 터졌다 (설계서 §4.8).
  mineBlast,
  bite,
  repair,

  // 고유 효과 (설계서 §4.8, ADR-075·078).
  seal,
  pull,
  wind,
  blind,
  bail,
  boost,
  heal,
  wall,
  revive,
  intercept,

  /// 보급탄(수리)이 맞았지만 내 배에 고칠 ‘구멍’이 없었다 (ADR-092).
  noRepair,

  /// 보스 뱃머리 방패가 서 있어 블록 피해가 줄었다 / 마지막 방패 칸이 깨졌다
  /// (설계서 §5.4, A43 점검 제안 3, A57).
  shield,
  shieldBroken;

  /// 상대 배에 건 고유 능력 [ability] 의 이름표. 없으면 null.
  static HitTag? ofAbility(Ability ability) => switch (ability) {
    Ability.sealCabin => seal,
    Ability.pull => pull,
    Ability.steer => wind,
    Ability.blindTrail => blind,
    Ability.bail => bail,
    Ability.lantern => boost,
    Ability.cooldownCut => heal,
    _ => null,
  };

  /// 수리 보급탄(톡·램프)이 맞은 묶음 [cues] 의 결과 이름표: 고쳤으면 [repair], 고칠
  /// 구멍이 없었으면 [noRepair]. 수리하지 않는 해적이면 null (ADR-092).
  static HitTag? ofSupply(PirateSpec spec, List<SimEvent> cues) {
    if (spec.ammo != AmmoType.support || spec.ammoParam <= 0) return null;
    final fixed = cues.any((e) => e.kind == SimEventKind.repaired);
    return fixed ? repair : noRepair;
  }

  /// 탄종 [ammo] 로 맞혔을 때 붙는 이름표. 없으면 null.
  static HitTag? ofAmmo(AmmoType ammo) => switch (ammo) {
    AmmoType.sniper => crit,
    AmmoType.pierce => pierce,
    AmmoType.chain => chain,
    AmmoType.fire => burn,
    AmmoType.mine => mine,
    AmmoType.assault => bite,
    // 보급탄의 ‘수리’ 이름표는 내 배의 repaired 이벤트가 붙인다 (ADR-090).
    _ => null,
  };
}
