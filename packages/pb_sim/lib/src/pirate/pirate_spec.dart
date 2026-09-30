import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/pirate/ammo.dart';
import 'package:pb_sim/src/pirate/range_grade.dart';
import 'package:pb_sim/src/ship/hull.dart';

/// 해적 등급과 출전 코스트 (설계서 §4.2, §4.5). 순서는 해시에 들어가므로 바꾸지 않는다.
enum Rarity {
  common(3),
  rare(4),
  hero(5),
  legend(6),
  myth(8);

  const Rarity(this.cost);

  /// 출전 코스트. 해적 레벨과 관계없다.
  final int cost;

  /// 등급 단계: 일반 0 … 신화 4 (설계서 §4.8 사다리 칸).
  int get step => index;

  /// 데이터 이름으로 찾는다. 없으면 [FormatException].
  static Rarity byName(String name) {
    for (final r in values) {
      if (r.name == name) return r;
    }
    throw FormatException('알 수 없는 등급: $name');
  }
}

/// 해적 한 명의 전투 수치 (설계서 §4.3). 정수만 쓴다.
///
/// 행동은 탄종([ammo], 설계서 §4.8)이 정하고, 탄종의 등급 수치([ammoValue])는
/// `pb_data` 가 `ammo.json` 사다리에서 등급으로 찾아 정수로 넣는다.
class PirateSpec {
  const PirateSpec({
    required this.id,
    required this.rarity,
    required this.hp,
    required this.cooldownTurns,
    required this.blockDamage,
    required this.pirateDamage,
    this.blastRadius = 0,
    this.range = RangeGrade.medium,
    this.family = Family.lob,
    this.ammo = AmmoType.explosive,
    this.ammoValue = 50,
    this.ammoValue2 = 0,
    this.spreadMdeg = 0,
    this.ammoParam = 0,
  });

  final String id;
  final Rarity rarity;

  /// 최대 체력.
  final int hp;

  /// 쏜 뒤 건너뛰는 내 턴 수(0~2). 0 이면 다음 내 턴에 다시 쏜다 (설계서 §2.3).
  final int cooldownTurns;

  /// 착탄 칸 블록 피해. 폭발 반경 안 나머지 칸은 절반.
  final int blockDamage;

  /// 착탄 칸 해적 피해(공격력). 폭발 반경 안 나머지 칸은 절반.
  final int pirateDamage;

  /// 폭발 반경(칸). 0 이면 착탄 칸만.
  final int blastRadius;

  /// 최대 사거리 등급 (설계서 §2.8). 탄 속도를 정한다.
  final RangeGrade range;

  /// 힘 10000 일 때 탄 속도(1/1000칸/초).
  int get launchSpeed => range.launchSpeed;

  /// 공격 계열 (설계서 §4.1).
  final Family family;

  /// 탄종 (설계서 §4.8).
  final AmmoType ammo;

  /// 탄종 등급 수치(사다리 값). 단위는 탄종마다 다르다: 비율·배율은 %, 개수는 개,
  /// 선회력은 °/초, 설치탄은 지속 턴.
  final int ammoValue;

  /// 탄종의 둘째 수치(설치탄 폭발 때 침수 0.1%p 등). 없으면 0.
  final int ammoValue2;

  /// 탄종 고유 파라미터: 분열·연사 퍼짐 각(밀리도).
  final int spreadMdeg;

  /// 탄종 고유 파라미터 하나 (설계서 §4.3 `ammo`): 지원탄은 수리 칸 수, 다중투하는
  /// 1 이면 다음 내 턴 시작에 투하(펠리). 쓰지 않는 탄종은 0.
  final int ammoParam;

  int get cost => rarity.cost;

  /// 피해·반경만 바꾼 사본 (분열 조각·연사 한 발·소형 폭탄).
  PirateSpec withDamage({
    required int blockDamage,
    required int pirateDamage,
    int? blastRadius,
  }) => PirateSpec(
    id: id,
    rarity: rarity,
    hp: hp,
    cooldownTurns: cooldownTurns,
    blockDamage: blockDamage,
    pirateDamage: pirateDamage,
    blastRadius: blastRadius ?? this.blastRadius,
    range: range,
    family: family,
    ammo: ammo,
    ammoValue: ammoValue,
    ammoValue2: ammoValue2,
    spreadMdeg: spreadMdeg,
    ammoParam: ammoParam,
  );
}

/// 해적 쿨다운 상한(턴) (설계서 §2.3 “쿨다운 해적마다 0~2턴”).
const int maxCooldownTurns = 2;

/// 해적 id → 정의. 매치가 덱 id 를 풀 때 쓴다.
class PirateCatalog {
  /// id 가 겹치면 [ArgumentError].
  PirateCatalog(Iterable<PirateSpec> specs) {
    for (final s in specs) {
      if (_byId.containsKey(s.id)) {
        throw ArgumentError('해적 id 중복: ${s.id}');
      }
      _byId[s.id] = s;
    }
  }

  // id 로 조회만 하고 순회하지 않는다 (결정론 규칙 §2.2).
  final Map<String, PirateSpec> _byId = {};

  /// 없으면 [ArgumentError].
  PirateSpec byId(String id) =>
      _byId[id] ?? (throw ArgumentError('알 수 없는 해적: $id'));
}

/// 출전 명단 검사 (설계서 §3.1, §4.5). 위반이면 [ArgumentError].
///
/// 인원은 1명 이상, 선형 선실 수 이하, 최대 [maxLineup] 명. 코스트 합계는
/// [costLimit](플레이어 레벨로 정해지는 출전 코스트 한도) 이하. 같은 해적은 한 번만.
void checkLineup(HullSpec hull, List<PirateSpec> lineup, int costLimit) {
  if (lineup.isEmpty) throw ArgumentError('출전 해적이 없다');
  if (lineup.length > hull.cabinSlots || lineup.length > maxLineup) {
    throw ArgumentError(
      '출전 인원 초과: ${lineup.length} (선실 ${hull.cabinSlots}, 최대 $maxLineup)',
    );
  }
  var cost = 0;
  for (var i = 0; i < lineup.length; i++) {
    final cd = lineup[i].cooldownTurns;
    if (cd < 0 || cd > maxCooldownTurns) {
      throw ArgumentError('쿨다운은 0~$maxCooldownTurns 턴: ${lineup[i].id} $cd');
    }
    cost += lineup[i].cost;
    for (var j = 0; j < i; j++) {
      if (lineup[j].id == lineup[i].id) {
        throw ArgumentError('같은 해적이 둘: ${lineup[i].id}');
      }
    }
  }
  if (cost > costLimit) {
    throw ArgumentError('출전 코스트 초과: $cost > $costLimit');
  }
}
