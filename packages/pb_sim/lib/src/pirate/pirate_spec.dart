import 'package:pb_sim/src/match/rules.dart';
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
/// M2 는 포물선 탄 + 착탄 폭발 한 가지 행동만 있다. 행동 모듈 조합(`projectile`,
/// `onHit`, ...)은 M5 에서 `pb_data` 가 JSON 을 읽어 이 정의로 바꾼다.
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

  int get cost => rarity.cost;
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
