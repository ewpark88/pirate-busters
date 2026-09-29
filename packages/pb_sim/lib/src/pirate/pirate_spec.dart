/// 해적 한 명의 전투 수치 (설계서 §4.3). 정수만 쓴다.
///
/// M2 는 포물선 탄 + 착탄 폭발 한 가지 행동만 있다. 행동 모듈 조합(`projectile`,
/// `onHit`, ...)은 M5 에서 `pb_data` 가 JSON 을 읽어 이 정의로 바꾼다.
class PirateSpec {
  const PirateSpec({
    required this.id,
    required this.hp,
    required this.reloadTicks,
    required this.blockDamage,
    required this.pirateDamage,
    this.blastRadius = 0,
    this.launchSpeed = defaultLaunchSpeed,
  });

  /// 힘 10000 으로 쐈을 때 탄 속도 기본값: 40칸/초 (1/1000칸/초).
  static const int defaultLaunchSpeed = 40000;

  final String id;

  /// 최대 체력.
  final int hp;

  /// 재장전 틱 수 (설계서 §2.3: 3~12초 = 90~360틱).
  final int reloadTicks;

  /// 착탄 칸 블록 피해. 폭발 반경 안 나머지 칸은 절반.
  final int blockDamage;

  /// 착탄 칸 해적 피해(공격력). 폭발 반경 안 나머지 칸은 절반.
  final int pirateDamage;

  /// 폭발 반경(칸). 0 이면 착탄 칸만.
  final int blastRadius;

  /// 힘 10000 일 때 탄 속도(1/1000칸/초).
  final int launchSpeed;
}

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
