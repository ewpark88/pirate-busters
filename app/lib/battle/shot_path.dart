import 'package:pb_sim/pb_sim.dart';

/// 탄 하나의 틱별 월드 위치 (1/1000칸). 렌더와 궤적 미리보기용.
///
/// 시뮬레이션과 같은 발사 계산(`launchShot`)과 같은 적분(`Projectile.advance`)을
/// 쓰므로 그린 궤적이 판정과 어긋나지 않는다. 표적과의 충돌은 보지 않는다.
class ShotPath {
  ShotPath._(this.xs, this.ys);

  /// 발사 전 [state] 에서 [slot] 해적이 [ms](실제 시각)에 쏜 탄의 궤적.
  /// 해수면 아래로 내려가거나 수명이 다할 때까지 담는다.
  factory ShotPath.predict(
    MatchState state, {
    required int slot,
    required int angle,
    required int power,
    required int ms,
  }) {
    final p = launchShot(state, slot: slot, angle: angle, power: power, ms: ms);
    final wind = state.wind * state.rules.windAccel;
    final xs = <int>[p.x];
    final ys = <int>[p.y];
    while (!p.isExpired && p.y >= 0) {
      p.advance(wind);
      xs.add(p.x);
      ys.add(p.y);
    }
    return ShotPath._(xs, ys);
  }

  /// [ShotPath.predict] 와 같지만 상대 배(블록·드러난 해적)에 처음 닿는 곳이나
  /// 해수면에서 끝난다. 시뮬레이션의 비행 판정(`stepShot`)과 같은 격자 추적을 쓴다.
  /// 계산을 미룬 분열탄이 탭 없이 떨어질 틱을 알 때 쓴다(렌더 전용).
  factory ShotPath.predictToHit(
    MatchState state, {
    required int slot,
    required int angle,
    required int power,
    required int ms,
  }) {
    final p = launchShot(state, slot: slot, angle: angle, power: power, ms: ms);
    final wind = state.wind * state.rules.windAccel;
    final target = state.sides[1 - p.side];
    final grid = target.grid;
    final xs = <int>[p.x];
    final ys = <int>[p.y];
    while (!p.isExpired) {
      final x0 = p.x;
      final y0 = p.y;
      p.advance(wind);
      var x1 = p.x;
      var y1 = p.y;
      final sea = y1 < 0;
      if (sea) {
        x1 = y0 <= 0 ? x0 : x0 + roundDiv((x1 - x0) * y0, y0 - y1);
        y1 = 0;
      }
      final at = msAfterTicks(ms, p.age);
      final (lx0, ly0) = toShipLocal(state, target.side, at, x0, y0);
      final (lx1, ly1) = toShipLocal(state, target.side, at, x1, y1);
      final hit = traceCells(
        lx0,
        ly0,
        lx1,
        ly1,
        (cx, cy) => grid.hasBlock(cx, cy) || target.isExposedPirateAt(cx, cy),
      );
      if (hit != null) {
        final (wx, wy) = fromShipLocal(state, target.side, at, hit.x, hit.y);
        xs.add(wx);
        ys.add(wy);
        break;
      }
      xs.add(x1);
      ys.add(y1);
      if (sea) break;
    }
    return ShotPath._(xs, ys);
  }

  /// 틱 0(발사)부터의 위치.
  final List<int> xs;
  final List<int> ys;

  /// 마지막 틱 번호.
  int get lastTick => xs.length - 1;

  /// [ticks] 틱까지만 남기고 끝점을 ([endX], [endY]) 로 바꾼다(착탄·물보라 지점).
  ShotPath truncated(int ticks, int endX, int endY) {
    final n = ticks.clamp(1, lastTick);
    return ShotPath._(
      [...xs.sublist(0, n), endX],
      [...ys.sublist(0, n), endY],
    );
  }

  /// 앞 [percent]% 구간 (궤적 미리보기, 개발 계획서 M4).
  ShotPath head(int percent) {
    final n = (lastTick * percent ~/ 100).clamp(1, lastTick) + 1;
    return ShotPath._(xs.sublist(0, n), ys.sublist(0, n));
  }
}
