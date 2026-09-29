import 'package:pb_sim/src/random/xorshift32.dart';

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

/// 한 판에 출전할 수 있는 최대 해적 수 (설계서 §3.1, §4.5).
const int maxLineup = 7;

/// 판 규칙 수치. 턴 수·턴 시간은 기획에서 언제든 바뀔 수 있어 값으로 받는다
/// (설계서 §2.3, §2.4, ADR-013).
class MatchRules {
  const MatchRules({
    this.maxTurns = 30,
    this.turnTimeMs = 25000,
    this.firesPerTurn = 2,
    this.maxWind = 3,
    this.windAccel = 1,
    this.sunkHullPercent = 20,
  });

  /// 양쪽 합친 최대 턴 수. 짝수여야 양쪽 턴 수가 같다.
  final int maxTurns;

  /// 턴 제한 시간(밀리초). 탄 비행 연출 동안은 멈춘다.
  final int turnTimeMs;

  /// 한 턴 최대 발사 수(서로 다른 해적).
  final int firesPerTurn;

  /// 바람 세기 절댓값 상한(−maxWind ~ +maxWind).
  final int maxWind;

  /// 바람 세기 1 당 투사체 가로 가속(1/1000칸/틱²).
  final int windAccel;

  /// 선체 내구도가 시작의 이 비율(%) 미만이면 격침 (설계서 §2.4).
  final int sunkHullPercent;

  /// [turn] 번째 턴(1부터)의 바람 세기. 매치 시드와 턴 번호로만 정해져 양쪽이 항상
  /// 같은 값을 얻는다 (설계서 §7.2). 매치 난수 흐름과는 따로 뽑는다.
  int windForTurn(int seed, int turn) {
    final rng = XorShift32(mixSeed(seed ^ mixSeed(turn)));
    return rng.nextRange(-maxWind, maxWind + 1);
  }

  Map<String, Object?> toJson() => {
    'maxTurns': maxTurns,
    'turnTimeMs': turnTimeMs,
    'firesPerTurn': firesPerTurn,
    'maxWind': maxWind,
    'windAccel': windAccel,
    'sunkHullPercent': sunkHullPercent,
  };
}
