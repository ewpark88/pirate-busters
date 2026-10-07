import 'package:pb_sim/src/pirate/range_grade.dart';

/// 공격 계열 8개 (설계서 §4.1). 순서는 바꾸지 않는다(새 값은 뒤에 붙인다).
enum Family {
  lob('lob', RangeGrade.long),
  direct('direct', RangeGrade.medium),
  pierce('pierce', RangeGrade.medium),
  skip('skip', RangeGrade.long),
  underwater('underwater', RangeGrade.medium),
  air('air', RangeGrade.veryLong),
  assault('assault', RangeGrade.short),
  support('support', RangeGrade.long);

  const Family(this.jsonName, this.defaultRange);

  /// 데이터 이름.
  final String jsonName;

  /// 데이터에 `range` 가 없을 때 쓰는 사거리 등급 (설계서 §2.8 계열 기본 등급).
  final RangeGrade defaultRange;

  /// 데이터 이름으로 찾는다. 없으면 [FormatException].
  static Family byName(String name) {
    for (final f in values) {
      if (f.jsonName == name) return f;
    }
    throw FormatException('알 수 없는 계열: $name');
  }
}

/// 탄종 13개 (설계서 §4.8). 해적마다 하나이고 행동 모듈 묶음 + 등급 수치 1개다.
/// 순서는 바꾸지 않는다(새 값은 뒤에 붙인다).
enum AmmoType {
  /// 폭발탄: 반경 1칸 안 바깥 칸 피해 비율(%).
  explosive('explosive', multiShot: false),

  /// 화염탄: 화상 지대 지속 턴 / 나무 추가 피해(%). R1.
  fire('fire', multiShot: false),

  /// 분열탄: 비행 중 탭 → 조각 수.
  split('split', multiShot: true),

  /// 연사탄: 한 번 당겨 잇달아 쏘는 발수.
  burst('burst', multiShot: true),

  /// 저격탄: 해적 명중 치명 배율(%).
  sniper('sniper', multiShot: false),

  /// 연쇄탄: 명중 해적에서 번지는 수. R1.
  chain('chain', multiShot: false),

  /// 관통탄: 블록 관통 칸.
  pierce('pierce', multiShot: false),

  /// 물수제비탄: 튕김·연타 횟수.
  skip('skip', multiShot: false),

  /// 설치탄: 지속 턴 / 폭발 때 침수(0.1%p).
  mine('mine', multiShot: false),

  /// 다중투하: 급강하 소형 폭탄 수.
  flock('flock', multiShot: true),

  /// 유도탄: 선회력(°/초).
  homing('homing', multiShot: false),

  /// 강습탄: 착지 뒤 추가 행동 횟수.
  assault('assault', multiShot: false),

  /// 지원탄: 효과량 배율(%).
  support('support', multiShot: false);

  const AmmoType(this.jsonName, {required this.multiShot});

  /// 데이터 이름 (`ammo.type`).
  final String jsonName;

  /// 여러 발 탄종: 합계 피해를 조각·발마다 나눈다 (설계서 §4.8).
  final bool multiShot;

  /// 데이터 이름으로 찾는다. 없으면 [FormatException].
  static AmmoType byName(String name) {
    for (final t in values) {
      if (t.jsonName == name) return t;
    }
    throw FormatException('알 수 없는 탄종: $name');
  }
}

/// 여러 발 탄종의 합계 피해 비율(%): 140% + 등급 단계 × 10% (설계서 §4.8).
/// [rarityStep] 은 일반 0 … 신화 4.
int multiShotTotalPercent(int rarityStep) => 140 + rarityStep * 10;

/// 여러 발 탄종에서 한 발(조각)의 피해: 합계를 [count] 발에 고르게 나눈다(버림).
int perShotDamage(int baseDamage, int rarityStep, int count) => count <= 0
    ? 0
    : baseDamage * multiShotTotalPercent(rarityStep) ~/ 100 ~/ count;

/// 특성·세트로 개수형 수치에 더할 때의 상한: 사다리 값 + 2 (설계서 §4.8).
/// MVP 는 Lv1·세트 없음이라 [bonus] 는 0 이다.
int cappedCount(int ladderValue, int bonus) {
  final b = bonus > 2 ? 2 : (bonus < 0 ? 0 : bonus);
  return ladderValue + b;
}

/// 폭발 반경은 특성·세트를 합쳐도 최대 2칸 (설계서 §4.8).
int cappedBlastRadius(int radius) => radius > 2 ? 2 : radius;
