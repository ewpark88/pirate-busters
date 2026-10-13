import 'package:pb_sim/src/json_read.dart';
import 'package:pb_sim/src/random/xorshift32.dart';
import 'package:pb_sim/src/world/world.dart';

/// 시뮬레이션 고정 틱 속도(Hz). 턴 안의 탄 비행·붕괴는 틱으로 계산하고,
/// 렌더는 두 틱 사이를 보간한다 (설계서 §7.1).
const int simTickHz = 30;

/// 32비트 시드 섞기 (murmur3 fmix32). 작은 시드끼리도 첫 난수가 고르게 퍼지게 한다.
/// xorshift32 는 작은 시드에서 첫 몇 개 값의 상위 비트가 거의 0 이다.
int mixSeed(int seed) {
  var h = seed & _mask32;
  h ^= h >> 16;
  h = _mul32(h, 0x85EBCA6B);
  h ^= h >> 13;
  h = _mul32(h, 0xC2B2AE35);
  h ^= h >> 16;
  return h;
}

const int _mask32 = 0xFFFFFFFF;

/// 32비트 곱셈의 하위 32비트. 중간값이 2^48 을 넘지 않게 16비트씩 나눠 곱한다.
int _mul32(int a, int b) {
  final lo = a * (b & 0xFFFF);
  final hi = ((a * (b >> 16)) & 0xFFFF) << 16;
  return (lo + hi) & _mask32;
}

/// 한 판에 출전할 수 있는 최대 해적 수: 선실 4 + 망대 1 (설계서 §3.3, §4.5).
const int maxLineup = 5;

/// 판 규칙 수치. 턴 수·턴 시간·바람·파도 수치는 기획과 Remote Config 로 바뀔 수
/// 있어 값으로 받는다 (설계서 §2.3~§2.7, BALANCE.md A2.3~A2.7, ADR-111).
class MatchRules {
  const MatchRules({
    this.maxTurns = 24,
    this.turnTimeMs = 20000,
    this.maxWind = 3,
    this.windAccel = windAccelPerStep,
    this.waveZoneWidth = 5 * cellUnit,
    this.wavePeriodMs = 4000,
    this.waveHeavePerLevel = 150,
    this.waveRollPerLevel = 1000,
    this.calmSea = false,
    this.minGap = 2 * cellUnit,
    this.backRoom = 4 * cellUnit,
    this.breakPauseMs = 600,
    this.limitSlowZone = 500,
  });

  /// [toJson] 결과에서 읽는다. 빠진 키나 범위 밖 값은 [FormatException].
  /// 리플레이는 외부 입력이라 0 나눗셈·무한 루프가 될 값을 막는다.
  factory MatchRules.fromJson(Map<String, Object?> json) {
    final rules = MatchRules(
      maxTurns: readInt(json, 'maxTurns'),
      turnTimeMs: readInt(json, 'turnTimeMs'),
      maxWind: readInt(json, 'maxWind'),
      windAccel: readInt(json, 'windAccel'),
      waveZoneWidth: readInt(json, 'waveZoneWidth'),
      wavePeriodMs: readInt(json, 'wavePeriodMs'),
      waveHeavePerLevel: readInt(json, 'waveHeavePerLevel'),
      waveRollPerLevel: readInt(json, 'waveRollPerLevel'),
      calmSea: json['calmSea'] == true,
      minGap: readInt(json, 'minGap'),
      backRoom: readInt(json, 'backRoom'),
      breakPauseMs: readInt(json, 'breakPauseMs'),
      limitSlowZone: readInt(json, 'limitSlowZone'),
    );
    return rules.._check();
  }

  void _check() {
    void need({required bool ok, required String what}) {
      if (!ok) throw FormatException('규칙 값이 범위 밖: $what');
    }

    need(ok: maxTurns > 0 && maxTurns.isEven, what: 'maxTurns $maxTurns');
    need(ok: turnTimeMs > 0, what: 'turnTimeMs $turnTimeMs');
    need(ok: maxWind >= 0, what: 'maxWind $maxWind');
    need(ok: windAccel >= 0, what: 'windAccel $windAccel');
    need(ok: waveZoneWidth > 0, what: 'waveZoneWidth $waveZoneWidth');
    need(ok: wavePeriodMs > 0, what: 'wavePeriodMs $wavePeriodMs');
    need(
      ok: waveHeavePerLevel >= 0 && waveRollPerLevel >= 0,
      what: '파도 값',
    );
    need(
      ok: minGap >= 0 && minGap < startGap && backRoom >= 0,
      what: '간격 $minGap $backRoom',
    );
    need(ok: breakPauseMs >= 0, what: 'breakPauseMs $breakPauseMs');
    need(
      ok: limitSlowZone >= 0 && limitSlowZone <= backRoom,
      what: 'limitSlowZone $limitSlowZone',
    );
  }

  /// 양쪽 합친 최대 턴 수. 짝수여야 양쪽 턴 수가 같다 (설계서 §2.7).
  final int maxTurns;

  /// 턴 제한 시간(밀리초). 탄 비행 연출 동안은 멈춘다.
  final int turnTimeMs;

  /// 바람 세기 절댓값 상한(−maxWind ~ +maxWind).
  final int maxWind;

  /// 바람 세기 1 당 투사체 가로 가속(속도 단위/틱, 기본 중력의 2.5%, BALANCE.md A2.3).
  final int windAccel;

  /// 파도 구간 폭(1/1000칸). 바다 가운데에서 바깥쪽으로 같은 폭으로 나눈다 (§2.6).
  final int waveZoneWidth;

  /// 파도 주기(밀리초, 고정).
  final int wavePeriodMs;

  /// 파도 세기 1 당 위아래 흔들림 폭(1/1000칸).
  final int waveHeavePerLevel;

  /// 파도 세기 1 당 기울기 폭(밀리도).
  final int waveRollPerLevel;

  /// 바다 전체가 잔잔하다(튜토리얼 첫 판·시험용). 파도 구간을 모두 0 으로 둔다.
  final bool calmSea;

  /// 두 배 뱃머리 사이 최소 간격(1/1000칸). 겹치거나 지나칠 수 없다 (§2.5).
  final int minGap;

  /// 시작 위치에서 뒤로 갈 수 있는 거리(1/1000칸): 바다 끝 (§2.5).
  final int backRoom;

  /// 블록이 부서지거나 무너진 발사는 그 연출만큼 턴 타이머를 더 멈춘다(밀리초).
  final int breakPauseMs;

  /// 이동 한계 앞 이 거리(1/1000칸)부터 감속해 절반 속도로 간다. 연료는 거리만큼만 쓴다.
  final int limitSlowZone;

  /// [turn] 번째 턴(1부터)의 바람 세기. 매치 시드와 턴 번호로만 정해져 양쪽이 항상
  /// 같은 값을 얻는다 (설계서 §7.2). 매치 난수 흐름과는 따로 뽑는다.
  int windForTurn(int seed, int turn) {
    final rng = XorShift32(mixSeed(seed ^ mixSeed(turn)));
    return rng.nextRange(-maxWind, maxWind + 1);
  }

  /// 파도 구간 세기 (설계서 §2.6, BALANCE.md A2.5): 가운데에서 바깥쪽으로 구간 3개에
  /// 잔잔(0)·보통(1)·거침(3)을 판 시드로 하나씩 섞어 둔다. 좌우 대칭이라 목록 순서는
  /// 가운데에서 떨어진 구간 번호다. 매치 난수 흐름과는 따로 뽑는다.
  List<int> waveZonesFor(int seed) {
    if (calmSea) return const [0, 0, 0];
    final levels = [0, 1, 3];
    final rng = XorShift32(mixSeed(seed ^ 0x5EA5));
    for (var i = levels.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final t = levels[i];
      levels[i] = levels[j];
      levels[j] = t;
    }
    return List.unmodifiable(levels);
  }

  Map<String, Object?> toJson() => {
    'maxTurns': maxTurns,
    'turnTimeMs': turnTimeMs,
    'maxWind': maxWind,
    'windAccel': windAccel,
    'waveZoneWidth': waveZoneWidth,
    'wavePeriodMs': wavePeriodMs,
    'waveHeavePerLevel': waveHeavePerLevel,
    'waveRollPerLevel': waveRollPerLevel,
    if (calmSea) 'calmSea': true,
    'minGap': minGap,
    'backRoom': backRoom,
    'breakPauseMs': breakPauseMs,
    'limitSlowZone': limitSlowZone,
  };
}
