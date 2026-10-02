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
  lantern('lantern'),

  // ── R1a-2 해적 고유 동작 (ADR-078) ──

  /// 꽃게 형제: 같은 궤적으로 두 발(여러 발 합계 규칙).
  twin('twin'),

  /// 볼케: 인자 층(블록 칸)을 50% 피해로 뚫고 마지막 칸에서 반경 +1 대폭발.
  drill('drill'),

  /// 본즈: 조준경 모드(조준 중 궤적 표시 50%, 앱 전용). 판정에는 효과가 없다.
  scope('scope'),

  /// 라이언: 지나가는 망사(돛)를 늦춰지지 않고 찢어 없앤다.
  shred('shred'),

  /// 나르: 관통하며 만나는 해적 인자 명까지 해적 피해를 줄이지 않는다.
  skewer('skewer'),

  /// 왈러스: 뚫고 지나간 블록이 ‘구멍’ 단계가 되면 뜯어낸다.
  rip('rip'),

  /// 소오: 처음 맞은 칸의 세로줄 모든 블록에 블록 피해 50%.
  saw('saw'),

  /// 핑구: 맞은 뒤 진행 방향으로 인자 칸만큼 갑판(맨 위 블록)을 미끄러지며 50% 피해.
  slide('slide'),

  /// 셀던: 선체에 맞으면 남은 튕김 수만큼 벽에서 되튄다.
  ricochet('ricochet'),

  /// 돌피: 맞은 세로줄 흘수선 칸을 사다리 횟수 − 1 번 더 50% 로 친다.
  cling('cling'),

  /// 오르카: 침수 +인자(0.1%p), 드러난 갑판 해적을 바다로 쓸어낸다.
  wave('wave'),

  /// 바라: 중력 없이 곧게 날고 수면 아래로 들어가 물속에서 선체를 맞힌다.
  torpedo('torpedo'),

  /// 모레이: 붙은 다음 상대 턴 시작에 붙은 칸과 이웃을 인자만큼 물어뜯고, 그 턴 끝
  /// 펌프를 멈춘다.
  gnaw('gnaw'),

  /// 크라키: 붙어서 사다리 지속 턴 동안 상대 턴 끝마다 사다리 침수를 더한다(촉수
  /// 인자 개는 그림).
  tentacle('tentacle'),

  /// 크래비: 착지 칸에서 가장 가까운 배 위 해적 한 명을 물고 바다로 떨어뜨린다.
  grab('grab'),

  /// 랍: 해적을 쓰러뜨리면 가장 가까운 다음 해적으로 뛰어 다시 벤다(사다리 횟수).
  leap('leap'),

  /// 데비: 해골 선원 인자 명이 다음 상대 턴 시작에 해적 피해 50% 로 물고, 데비는
  /// 한 번 쓰러지면 체력 절반으로 되살아난다.
  summon('summon'),

  /// 코리: 착지한 곳에 산호 방벽을 세운다(인자 = 내 턴 지속 수).
  coral('coral');

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
  Ability.bail ||
  Ability.cooldownCut ||
  Ability.lantern ||
  Ability.coral => AmmoType.support,
  Ability.twin || Ability.drill => AmmoType.explosive,
  Ability.scope => AmmoType.sniper,
  Ability.shred => AmmoType.burst,
  Ability.skewer ||
  Ability.rip ||
  Ability.saw ||
  Ability.torpedo => AmmoType.pierce,
  Ability.slide ||
  Ability.ricochet ||
  Ability.cling ||
  Ability.wave => AmmoType.skip,
  Ability.gnaw || Ability.tentacle => AmmoType.mine,
  Ability.grab || Ability.leap || Ability.summon => AmmoType.assault,
};

/// 방향 전환 탭의 각도(밀리도) (BALANCE.md A4.2 알바, ADR-075).
const int steerTurnMdeg = 45000;
