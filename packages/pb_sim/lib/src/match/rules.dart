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

/// 한 판에 출전할 수 있는 최대 해적 수 (설계서 §3.1, §4.5).
const int maxLineup = 7;

/// 판 규칙 수치. 턴 수·턴 시간·연료·파도·침수 수치는 기획과 Remote Config 로 바뀔 수
/// 있어 값으로 받는다 (설계서 §2.3~§2.7, ADR-013, ADR-025).
class MatchRules {
  const MatchRules({
    this.maxTurns = 30,
    this.turnTimeMs = 25000,
    this.firesPerTurn = 2,
    this.maxWind = 3,
    this.windAccel = windAccelPerStep,
    this.sunkHullPercent = 40,
    this.fuelPerTurn = 30,
    this.stormTurns = 4,
    this.stormTurnTimeMs = 20000,
    this.stormRetreatPull = 6000,
    this.stormFuel = 30,
    this.stormWindPercent = 200,
    this.stormWavePercent = 150,
    this.stormFloodPercent = 150,
    this.waveLevel = 1,
    this.wavePeriodMs = 4000,
    this.waveHeavePerLevel = 150,
    this.waveRollPerLevel = 1000,
    this.floodFullCell = 40,
    this.floodHalfCell = 20,
    this.waterlineDivisor = 4,
    this.sinkAtFullFlood = 2000,
    this.tiltPerCell = 1000,
    this.maxTilt = 6000,
    this.breakPauseMs = 600,
    this.limitSlowZone = 500,
  });

  /// [toJson] 결과에서 읽는다. 빠진 키나 범위 밖 값은 [FormatException].
  /// 리플레이는 외부 입력이라 0 나눗셈·무한 루프가 될 값을 막는다.
  factory MatchRules.fromJson(Map<String, Object?> json) {
    final rules = MatchRules(
      maxTurns: readInt(json, 'maxTurns'),
      turnTimeMs: readInt(json, 'turnTimeMs'),
      firesPerTurn: readInt(json, 'firesPerTurn'),
      maxWind: readInt(json, 'maxWind'),
      windAccel: readInt(json, 'windAccel'),
      sunkHullPercent: readInt(json, 'sunkHullPercent'),
      fuelPerTurn: readInt(json, 'fuelPerTurn'),
      stormTurns: readInt(json, 'stormTurns'),
      stormTurnTimeMs: readInt(json, 'stormTurnTimeMs'),
      stormRetreatPull: readInt(json, 'stormRetreatPull'),
      stormFuel: readInt(json, 'stormFuel'),
      stormWindPercent: readInt(json, 'stormWindPercent'),
      stormWavePercent: readInt(json, 'stormWavePercent'),
      stormFloodPercent: readInt(json, 'stormFloodPercent'),
      waveLevel: readInt(json, 'waveLevel'),
      wavePeriodMs: readInt(json, 'wavePeriodMs'),
      waveHeavePerLevel: readInt(json, 'waveHeavePerLevel'),
      waveRollPerLevel: readInt(json, 'waveRollPerLevel'),
      floodFullCell: readInt(json, 'floodFullCell'),
      floodHalfCell: readInt(json, 'floodHalfCell'),
      waterlineDivisor: readInt(json, 'waterlineDivisor'),
      sinkAtFullFlood: readInt(json, 'sinkAtFullFlood'),
      tiltPerCell: readInt(json, 'tiltPerCell'),
      maxTilt: readInt(json, 'maxTilt'),
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
    need(ok: turnTimeMs > 0 && stormTurnTimeMs > 0, what: '턴 시간');
    need(ok: firesPerTurn > 0, what: 'firesPerTurn $firesPerTurn');
    need(ok: maxWind >= 0, what: 'maxWind $maxWind');
    need(
      ok: stormTurns >= 0 && stormTurns <= maxTurns,
      what: 'stormTurns $stormTurns',
    );
    need(ok: waveLevel >= 0 && waveLevel <= 3, what: 'waveLevel $waveLevel');
    need(ok: wavePeriodMs > 0, what: 'wavePeriodMs $wavePeriodMs');
    need(ok: waterlineDivisor > 0, what: 'waterlineDivisor $waterlineDivisor');
    need(ok: maxTilt >= 0, what: 'maxTilt $maxTilt');
    need(ok: breakPauseMs >= 0, what: 'breakPauseMs $breakPauseMs');
    need(
      ok: limitSlowZone >= 0 && limitSlowZone <= moveRange,
      what: 'limitSlowZone $limitSlowZone',
    );
    need(ok: windAccel >= 0, what: 'windAccel $windAccel');
    need(
      ok: sunkHullPercent >= 0 && sunkHullPercent <= 100,
      what: 'sunkHullPercent $sunkHullPercent',
    );
    // 후퇴 한계를 당겨도 전진 한계를 넘지 않는다 (폭풍 타임, 설계서 §2.6).
    need(
      ok: stormRetreatPull >= 0 && stormRetreatPull <= 2 * moveRange,
      what: 'stormRetreatPull $stormRetreatPull',
    );
    need(
      ok:
          stormWindPercent >= 0 &&
          stormWavePercent >= 0 &&
          stormFloodPercent >= 0,
      what: '폭풍 배율',
    );
    need(
      ok:
          sinkAtFullFlood >= 0 &&
          waveHeavePerLevel >= 0 &&
          waveRollPerLevel >= 0 &&
          tiltPerCell >= 0,
      what: '파도·내려앉기·기울기 값',
    );
    need(
      ok:
          fuelPerTurn >= 0 &&
          stormFuel >= 0 &&
          floodFullCell >= 0 &&
          floodHalfCell >= 0,
      what: '연료·침수 값',
    );
  }

  /// 양쪽 합친 최대 턴 수. 짝수여야 양쪽 턴 수가 같다.
  final int maxTurns;

  /// 턴 제한 시간(밀리초). 탄 비행 연출 동안은 멈춘다.
  final int turnTimeMs;

  /// 한 턴 최대 발사 수(서로 다른 해적).
  final int firesPerTurn;

  /// 바람 세기 절댓값 상한(−maxWind ~ +maxWind).
  final int maxWind;

  /// 바람 세기 1 당 투사체 가로 가속(속도 단위/틱, 기본 중력의 2.5%, BALANCE.md A2.3).
  final int windAccel;

  /// 선체 내구도가 시작의 이 비율(%) 미만이면 격침 (설계서 §2.4).
  final int sunkHullPercent;

  /// 내 턴 시작 연료 회복 (설계서 §2.7).
  final int fuelPerTurn;

  /// 폭풍 타임 턴 수: 마지막 이만큼의 턴 (설계서 §2.4, 27~30턴).
  final int stormTurns;

  /// 폭풍 타임 턴 제한 시간(밀리초).
  final int stormTurnTimeMs;

  /// 폭풍 타임에 후퇴 한계를 당기는 거리(1/1000칸, 최대 간격 36칸).
  final int stormRetreatPull;

  /// 폭풍 타임이 시작될 때 양쪽에 채우는 연료.
  final int stormFuel;

  /// 폭풍 타임 바람 배율(%).
  final int stormWindPercent;

  /// 폭풍 타임 파도 배율(%).
  final int stormWavePercent;

  /// 폭풍 타임 턴 끝 침수 증가 배율(%).
  final int stormFloodPercent;

  /// 스테이지 파도 세기(0~3). 0 이면 흔들리지 않는다 (설계서 §2.5).
  final int waveLevel;

  /// 파도 주기(밀리초, 고정). 임시 값 (ADR-025).
  final int wavePeriodMs;

  /// 파도 세기 1 당 위아래 흔들림 폭(1/1000칸). 임시 값.
  final int waveHeavePerLevel;

  /// 파도 세기 1 당 기울기 폭(밀리도). 임시 값.
  final int waveRollPerLevel;

  /// 완전히 잠긴 구멍 1칸의 턴 끝 침수 증가(0.1%p 단위, 3%p) (설계서 §2.5).
  final int floodFullCell;

  /// 반쯤 잠긴 구멍 1칸의 턴 끝 침수 증가(0.1%p 단위, 1.5%p).
  final int floodHalfCell;

  /// 흘수선 = 무게 ÷ (선형 폭 × 이 값) (설계서 §3.4).
  final int waterlineDivisor;

  /// 침수량 100% 일 때 내려앉는 깊이(1/1000칸). 임시 값.
  final int sinkAtFullFlood;

  /// 앞·뒤 새는 칸 수 차이 1칸당 기울기(밀리도). 임시 값.
  final int tiltPerCell;

  /// 침수 기울기 상한(밀리도). 임시 값.
  final int maxTilt;

  /// 블록이 부서지거나 무너진 발사는 그 연출만큼 턴 타이머를 더 멈춘다(밀리초)
  /// (설계서 §2.3 “배가 부서지는 연출 동안 턴 타이머는 멈춘다”). 임시 값.
  final int breakPauseMs;

  /// 이동 한계선 앞 이 거리(1/1000칸)부터 감속해 절반 속도로 간다 (설계서 §2.6
  /// “한계 0.5칸 앞부터 감속”). 연료는 거리만큼만 쓴다 (§2.7).
  final int limitSlowZone;

  /// 폭풍 타임이 시작되는 턴 번호.
  int get stormStartTurn => maxTurns - stormTurns + 1;

  /// [turn] 이 폭풍 타임인가.
  bool isStorm(int turn) => turn >= stormStartTurn;

  /// [turn] 의 턴 제한 시간(밀리초).
  int turnTimeFor(int turn) => isStorm(turn) ? stormTurnTimeMs : turnTimeMs;

  /// [turn] 번째 턴(1부터)의 바람 세기. 매치 시드와 턴 번호로만 정해져 양쪽이 항상
  /// 같은 값을 얻는다 (설계서 §7.2). 매치 난수 흐름과는 따로 뽑는다. 폭풍 타임에는
  /// [stormWindPercent] 배.
  int windForTurn(int seed, int turn) {
    final rng = XorShift32(mixSeed(seed ^ mixSeed(turn)));
    final wind = rng.nextRange(-maxWind, maxWind + 1);
    return isStorm(turn) ? wind * stormWindPercent ~/ 100 : wind;
  }

  Map<String, Object?> toJson() => {
    'maxTurns': maxTurns,
    'turnTimeMs': turnTimeMs,
    'firesPerTurn': firesPerTurn,
    'maxWind': maxWind,
    'windAccel': windAccel,
    'sunkHullPercent': sunkHullPercent,
    'fuelPerTurn': fuelPerTurn,
    'stormTurns': stormTurns,
    'stormTurnTimeMs': stormTurnTimeMs,
    'stormRetreatPull': stormRetreatPull,
    'stormFuel': stormFuel,
    'stormWindPercent': stormWindPercent,
    'stormWavePercent': stormWavePercent,
    'stormFloodPercent': stormFloodPercent,
    'waveLevel': waveLevel,
    'wavePeriodMs': wavePeriodMs,
    'waveHeavePerLevel': waveHeavePerLevel,
    'waveRollPerLevel': waveRollPerLevel,
    'floodFullCell': floodFullCell,
    'floodHalfCell': floodHalfCell,
    'waterlineDivisor': waterlineDivisor,
    'sinkAtFullFlood': sinkAtFullFlood,
    'tiltPerCell': tiltPerCell,
    'maxTilt': maxTilt,
    'breakPauseMs': breakPauseMs,
    'limitSlowZone': limitSlowZone,
  };
}
