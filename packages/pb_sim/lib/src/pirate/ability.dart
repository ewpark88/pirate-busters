import 'package:pb_sim/src/pirate/ammo.dart';

/// 해적 고유 능력 (설계서 §4.3 `ability`, §4.8 고유 효과, ADR-075). 탄종이 비행·착탄을
/// 정하고, 고유 능력이 비행 중 탭(분열 제외)과 사다리 밖 고유 효과를 정한다.
/// 인자는 `PirateSpec.abilityValue` 정수 하나다. 순서는 바꾸지 않는다(새 값은 뒤에).
enum Ability {
  /// 고유 능력 없음.
  none('none'),

  /// 알바: 비행 중 탭으로 위·아래 45° 방향 전환 1회, 적 배 명중 시 다음 상대 턴
  /// 바람 역전.
  steer('steer'),

  /// 모비: 선체 명중 시 적 배를 인자 칸만큼 끌어당기고 다음 상대 턴 이동 불가.
  pull('pull'),

  /// 킹: 착지 칸에서 가장 가까운 적 선실을 다음 상대 턴 동안 봉쇄.
  sealCabin('sealCabin'),

  /// 만타: 적 배 명중 시 상대의 다음 턴 궤적 표시 봉쇄.
  blindTrail('blindTrail'),

  /// 젤리: 바다에 떨어지면 떠 있는 기뢰가 된다.
  floatMine('floatMine'),

  /// 뿜뿜: 지원탄이 내 배에 닿으면 침수량을 인자(0.1%p) × 지원 배율만큼 줄인다.
  bail('bail'),

  /// 쿡: 지원탄이 내 배에 닿으면 다른 아군 쿨다운을 인자 턴만큼 줄인다.
  cooldownCut('cooldownCut'),

  /// 램프: 지원탄이 내 배에 닿으면 연료 +인자, 다음 내 턴 궤적 100%·바람 무시.
  lantern('lantern');

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

/// 고유 능력이 동작하는 탄종 (설계서 §4.2 해적 표, ADR-075). 없으면 null.
/// 데이터 검사(`pb_data`)가 짝이 맞지 않는 해적을 거부한다.
AmmoType? ammoFor(Ability ability) => switch (ability) {
  Ability.none => null,
  Ability.steer || Ability.blindTrail => AmmoType.homing,
  Ability.pull => AmmoType.pierce,
  Ability.sealCabin => AmmoType.assault,
  Ability.floatMine => AmmoType.mine,
  Ability.bail || Ability.cooldownCut || Ability.lantern => AmmoType.support,
};

/// 방향 전환 탭의 각도(밀리도) (BALANCE.md A4.2 알바, ADR-075).
const int steerTurnMdeg = 45000;
