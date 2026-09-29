import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/math/trig.dart';

/// 파도 흔들림 (설계서 §2.5, 임시 수치 ADR-025).
///
/// 턴제에서도 배는 계속 흔들린다. 주기는 고정이라 놓는 순간을 고르는 것이 조준
/// 실력이 된다. 위상은 턴 시작 기준 실제 시각(밀리초, 비행 정지 포함)으로 정하고,
/// 오른쪽 배는 반주기 어긋난다. 정수 사인 테이블만 쓴다.
class Wave {
  const Wave(this.rules, this.turn);

  final MatchRules rules;

  /// 지금 턴. 폭풍 타임이면 흔들림이 커진다.
  final int turn;

  int get _percent => rules.isStorm(turn) ? rules.stormWavePercent : 100;

  int _phase(int side, int ms) {
    final period = rules.wavePeriodMs;
    final t = (ms + side * (period ~/ 2)) % period;
    return t * fullTurnMdeg ~/ period;
  }

  /// [side] 배의 위아래 흔들림(1/1000칸, 위가 +) — 턴 시작 후 [ms] 밀리초.
  int heave(int side, int ms) {
    final amp = rules.waveLevel * rules.waveHeavePerLevel * _percent ~/ 100;
    return roundDiv(amp * sinMicro(_phase(side, ms)), trigScale);
  }

  /// [side] 배의 기울기(밀리도, 뱃머리가 들리면 +) — 턴 시작 후 [ms] 밀리초.
  int roll(int side, int ms) {
    final amp = rules.waveLevel * rules.waveRollPerLevel * _percent ~/ 100;
    return roundDiv(amp * cosMicro(_phase(side, ms)), trigScale);
  }
}
