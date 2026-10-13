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

  /// 강습 해적 적 갑판 체류 (설계서 §2.3, ADR-110): 올라탐, 근접 수비 반격, 흔들려
  /// 떨어짐.
  boarded,
  repel,
  shakenOff,

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
    Ability.pull => pull,
    Ability.blindTrail => blind,
    _ => null,
  };

  /// 탄종 [ammo] 로 맞혔을 때 붙는 이름표. 없으면 null.
  static HitTag? ofAmmo(AmmoType ammo) => switch (ammo) {
    AmmoType.sniper => crit,
    AmmoType.pierce => pierce,
    AmmoType.chain => chain,
    AmmoType.fire => burn,
    AmmoType.mine => mine,
    AmmoType.assault => bite,
    _ => null,
  };
}
