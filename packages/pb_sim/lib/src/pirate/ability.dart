import 'package:pb_sim/src/pirate/ammo.dart';

/// 해적 고유 능력 (설계서 §4.8): 전설 등급만 갖는다(ADR-111). 바라의 물속 어뢰는
/// 수중 계열 관통탄의 동작이라 함께 둔다. 인자는 `PirateSpec.abilityValue` 정수 하나다.
/// 순서는 해시에 들어가므로 바꾸지 않는다(새 값은 뒤에).
enum Ability {
  /// 고유 능력 없음.
  none('none'),

  /// 모비: 선체 명중 시 적 배를 인자 칸만큼 끌어당긴다(최소 간격까지).
  pull('pull'),

  /// 만타: 적 배 명중 시 상대의 다음 턴 궤적 표시 봉쇄.
  blindTrail('blindTrail'),

  /// 볼케: 인자 층(블록 칸)을 50% 피해로 뚫고 마지막 칸에서 반경 +1 대폭발.
  drill('drill'),

  /// 오르카: 선체 명중 시 갑판 맨 위 해적들에게 해적 피해 50%, 적 배를 인자 칸 민다.
  wave('wave'),

  /// 바라: 중력 없이 곧게 날고 수면 아래로 들어가 물속에서 선체를 맞힌다.
  torpedo('torpedo'),

  /// 크라키: 붙는 순간 터지고, 인자 턴 동안 상대 턴 끝마다 둘레 1칸 블록을 친다.
  tentacle('tentacle'),

  /// 데비: 착지 때 해골 선원 인자 명이 둘레 해적을 해적 피해 50% 로 함께 문다.
  summon('summon'),

  /// 램프: 충격탄이 상대 배를 인자 칸만큼 민다(일반 충격탄은 사다리 값).
  shove('shove');

  const Ability(this.jsonName);

  /// 데이터 이름 (`ability.type`).
  final String jsonName;

  /// 데이터 이름으로 찾는다. 없으면 [FormatException].
  static Ability byName(String name) {
    for (final a in values) {
      if (a.jsonName == name) return a;
    }
    throw FormatException('알 수 없는 고유 능력: $name');
  }
}

/// 고유 능력이 동작하는 탄종. 없으면 null. 데이터 검사(`pb_data`)가 짝이 맞지 않는
/// 해적을 거부한다.
AmmoType? ammoFor(Ability ability) => switch (ability) {
  Ability.none => null,
  Ability.blindTrail => AmmoType.homing,
  Ability.pull || Ability.torpedo => AmmoType.pierce,
  Ability.drill => AmmoType.explosive,
  Ability.wave => AmmoType.skip,
  Ability.tentacle => AmmoType.mine,
  Ability.summon => AmmoType.assault,
  Ability.shove => AmmoType.shock,
};
