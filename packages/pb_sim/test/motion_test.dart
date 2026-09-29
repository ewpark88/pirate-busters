import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

const int _fuel = SideState.fuelUnit;

Match _calm({MatchRules rules = const MatchRules(waveLevel: 0)}) =>
    newSampleMatch(3, rules: rules);

SideState _me(Match m) => m.state.sides[m.state.activeSide];

void main() {
  group('이동 (설계서 §2.6)', () {
    test('시작 간격은 뱃머리 사이 28칸이다', () {
      final m = _calm();
      final gap = (m.state.sides[1].bowX - m.state.sides[0].bowX).abs();
      expect(gap, 28 * cellUnit);
    });

    test('MOVE 는 1/10칸 단위로 전진하고, 전진하면 상대와 가까워진다', () {
      final m = _calm();
      final me = _me(m);
      final before = me.bowX;
      m.apply(const MoveCommand(t: 100, dx: 25));
      expect(me.offset, 2500);
      expect((me.bowX - before).abs(), 2500);
      final gap = (m.state.sides[1].bowX - m.state.sides[0].bowX).abs();
      expect(gap, 28 * cellUnit - 2500);
    });

    test('전진·후퇴 한계선(±10칸)에서 멈추고, 막힌 거리는 연료를 쓰지 않는다', () {
      final m = _calm();
      final me = _me(m);
      final fuel = me.fuel;
      m.apply(const MoveCommand(t: 100, dx: 150));
      expect(me.offset, 10 * cellUnit);
      expect(me.fuel, fuel - 10 * 4 * _fuel);
    });

    test('연료가 모자라면 갈 수 있는 데까지만 간다', () {
      final m = _calm()..apply(const MoveCommand(t: 10, dx: 0)); // 턴 시작
      final me = _me(m)..fuel = 10 * _fuel; // 2.5칸 분량
      m.apply(const MoveCommand(t: 100, dx: -80));
      expect(me.offset, -2500);
      expect(me.fuel, 0);
      m.apply(const MoveCommand(t: 5000, dx: -10));
      expect(me.offset, -2500);
    });

    test('이동은 거리 ÷ 속도만큼 턴 시간을 쓰고, 그동안 온 커맨드는 이동 뒤에 처리한다', () {
      // 2.8칸 ÷ 2.8칸/초 = 1초.
      final m = _calm()..apply(const MoveCommand(t: 1000, dx: 28));
      expect(m.state.busyUntilMs, 2000);
      expect(effectiveMs(m.state, 1500), 2000);
      expect(effectiveMs(m.state, 2500), 2500);
    });

    test('남은 턴 시간만큼만 움직이고, 시간이 넘으면 턴이 넘어간다', () {
      final m = _calm();
      final me = _me(m);
      final turn = m.state.turn;
      m.apply(const MoveCommand(t: 24000, dx: 50)); // 1초 = 2.8칸만
      expect(me.offset, 2800);
      m.apply(const MoveCommand(t: 24500, dx: 10)); // 이동이 25초에 끝났다
      expect(m.state.turn, turn);
      m.apply(const EndTurnCommand(t: 24600));
      expect(m.state.turn, turn + 1);
    });

    test('침수량만큼 이동 속도가 줄어든다: × (1 − 침수량 × 0.6)', () {
      final m = _calm();
      final me = _me(m);
      expect(moveSpeedOf(me), 2800);
      me.flood = 500;
      expect(moveSpeedOf(me), 2800 * 700 ~/ 1000);
      me.flood = fullFlood;
      expect(moveSpeedOf(me), 2800 * 400 ~/ 1000);
    });

    test('이동 이벤트에 거리·새 뱃머리 위치·걸린 시간이 담긴다', () {
      final m = _calm()..apply(const MoveCommand(t: 100, dx: -14));
      final e = m.state.events.lastWhere((e) => e.kind == SimEventKind.move);
      expect([e.value, e.x, e.y], [-1400, _me(m).bowX, 500]);
    });
  });

  group('연료 (설계서 §2.7)', () {
    test('판 시작 때 탱크가 가득 차 있다 (슬루프 80)', () {
      final m = _calm();
      for (final s in m.state.sides) {
        expect(s.fuel, 80 * _fuel);
      }
    });

    test('내 턴이 시작될 때 +30, 탱크 상한까지만 찬다', () {
      final m = _calm()..apply(const MoveCommand(t: 10, dx: 0)); // 턴 시작
      final me = _me(m)..fuel = 0;
      m
        ..apply(const EndTurnCommand(t: 10))
        ..apply(const EndTurnCommand(t: 10)); // 상대 턴
      expect(me.fuel, 0);
      m.apply(const EndTurnCommand(t: 10)); // 내 턴 시작 → +30
      expect(me.fuel, 30 * _fuel);
      me.fuel = 70 * _fuel;
      m
        ..apply(const EndTurnCommand(t: 10))
        ..apply(const EndTurnCommand(t: 10));
      expect(me.fuel, 80 * _fuel);
    });
  });

  group('폭풍 타임 (설계서 §2.4, §2.6)', () {
    const rules = MatchRules(waveLevel: 0, maxTurns: 8);

    test('폭풍 타임이 시작되면 양쪽 연료 +30, 후퇴 한계 밖의 배는 한계선으로 오고 이동 이벤트가 나온다', () {
      final m = _calm(rules: rules);
      final a = m.state.sides[m.state.activeSide];
      m.apply(const MoveCommand(t: 10, dx: -100));
      expect(a.offset, -10 * cellUnit);
      for (var i = 0; i < 3; i++) {
        m.apply(const EndTurnCommand(t: 10));
      }
      m.apply(const MoveCommand(t: 10, dx: 0)); // 4턴 시작
      expect(m.state.turn, 4);
      final b = m.state.sides[1 - a.side];
      a.fuel = 0;
      b.fuel = 0;
      m
        ..apply(const EndTurnCommand(t: 10))
        ..apply(const EndTurnCommand(t: 10)); // 5턴(폭풍) 시작·끝
      expect(
        m.state.events.map((e) => e.kind),
        contains(SimEventKind.stormStart),
      );
      expect(a.offset, -4 * cellUnit);
      final snap = m.state.events.firstWhere(
        (e) => e.kind == SimEventKind.move && e.side == a.side,
      );
      expect([snap.value, snap.x], [6 * cellUnit, a.bowX]);
      expect(a.fuel, 60 * _fuel, reason: '폭풍 +30, 내 턴 시작 +30');
      expect(b.fuel, 30 * _fuel, reason: '폭풍 +30');
    });

    test('폭풍 타임 최대 간격은 36칸이다', () {
      final m = _calm(rules: rules);
      for (var i = 0; i < 4; i++) {
        m.apply(const EndTurnCommand(t: 10));
      }
      m
        ..apply(const MoveCommand(t: 10, dx: -100))
        ..apply(const EndTurnCommand(t: 3000))
        ..apply(const MoveCommand(t: 10, dx: -100));
      final gap = (m.state.sides[1].bowX - m.state.sides[0].bowX).abs();
      expect(gap, 36 * cellUnit);
    });

    test('폭풍 타임 턴 제한 시간은 20초다', () {
      expect(rules.turnTimeFor(4), 25000);
      expect(rules.turnTimeFor(5), 20000);
      final m = _calm(rules: rules);
      for (var i = 0; i < 4; i++) {
        m.apply(const EndTurnCommand(t: 10));
      }
      m.apply(const MoveCommand(t: 20500, dx: 10));
      expect(m.state.turn, 6);
    });
  });
}
