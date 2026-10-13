import 'package:pb_sim/pb_sim.dart';

/// 명중 이름표 (설계서 §10.4): 치명·관통·연쇄처럼 특별한 결과를 피해 숫자 아래에
/// 붙인다. 어떤 글자로 보일지는 화면이 l10n 으로 정한다(§14). 판정과 무관하다.
enum HitTag {
  /// 저격탄이 해적을 맞혔다(치명 배율).
  crit,
  pierce,
  chain,
  mine,

  /// 붙은 설치탄이 터졌다 (설계서 §4.8).
  mineBlast,
  bite,

  /// 강습 해적 적 갑판 체류 (설계서 §2.3, ADR-110): 올라탐, 근접 수비 반격, 흔들려
  /// 떨어짐.
  boarded,
  repel,
  shakenOff,

  // 전설 고유 능력 (설계서 §4.8): 모비 끌어당김, 만타 궤적 가림.
  pull,
  blind;

  /// 상대 배에 건 고유 능력 [ability] 의 이름표. 없으면 null.
  static HitTag? ofAbility(Ability ability) => switch (ability) {
    Ability.pull => pull,
    Ability.blindTrail => blind,
    _ => null,
  };

  /// 탄종 [ammo] 로 맞혔을 때 붙는 이름표. 없으면 null. 화염탄은 불이 붙지 않아
  /// 이름표가 없다 (설계서 §4.8).
  static HitTag? ofAmmo(AmmoType ammo) => switch (ammo) {
    AmmoType.sniper => crit,
    AmmoType.pierce => pierce,
    AmmoType.chain => chain,
    AmmoType.mine => mine,
    AmmoType.assault => bite,
    _ => null,
  };
}
