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
  bite,
  repair;

  /// 탄종 [ammo] 로 맞혔을 때 붙는 이름표. 없으면 null.
  static HitTag? ofAmmo(AmmoType ammo) => switch (ammo) {
    AmmoType.sniper => crit,
    AmmoType.pierce => pierce,
    AmmoType.chain => chain,
    AmmoType.fire => burn,
    AmmoType.mine => mine,
    AmmoType.assault => bite,
    AmmoType.support => repair,
    _ => null,
  };
}
