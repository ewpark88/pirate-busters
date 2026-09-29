import 'package:pb_sim/src/math/fx.dart';
import 'package:pb_sim/src/math/trig_table.dart';

/// 각도 단위: 밀리도(mdeg). 41250 = 41.25° (개발 계획서 §2.2).
const int mdegPerDegree = 1000;

/// 한 바퀴(360°)의 밀리도.
const int fullTurnMdeg = 360000;

const int _quarterMdeg = 90000;
const int _tableStepMdeg = 250;

/// 삼각함수 결과의 스케일(×1,000,000).
const int trigScale = 1000000;

/// 각도를 [0, 360000) 로 정규화한다.
int normalizeMdeg(int mdeg) {
  final r = mdeg % fullTurnMdeg;
  return r < 0 ? r + fullTurnMdeg : r;
}

/// sin(mdeg) × 1,000,000. 테이블(0.25° 간격) 사이는 선형 보간한다.
int sinMicro(int mdeg) {
  final a = normalizeMdeg(mdeg);
  final quadrant = a ~/ _quarterMdeg;
  final r = a % _quarterMdeg;
  return switch (quadrant) {
    0 => _sinFirstQuadrant(r),
    1 => _sinFirstQuadrant(_quarterMdeg - r),
    2 => -_sinFirstQuadrant(r),
    _ => -_sinFirstQuadrant(_quarterMdeg - r),
  };
}

/// cos(mdeg) × 1,000,000.
int cosMicro(int mdeg) => sinMicro(mdeg + _quarterMdeg);

/// sin(mdeg) 를 ×1000 고정소수점으로.
Fx sinFx(int mdeg) => Fx(roundDiv(sinMicro(mdeg), trigScale ~/ Fx.scale));

/// cos(mdeg) 를 ×1000 고정소수점으로.
Fx cosFx(int mdeg) => Fx(roundDiv(cosMicro(mdeg), trigScale ~/ Fx.scale));

/// [r] 은 0..90000.
int _sinFirstQuadrant(int r) {
  final i = r ~/ _tableStepMdeg;
  final frac = r % _tableStepMdeg;
  final lo = sinQuarterTable[i];
  if (frac == 0) return lo;
  final hi = sinQuarterTable[i + 1];
  return lo + roundDiv((hi - lo) * frac, _tableStepMdeg);
}
