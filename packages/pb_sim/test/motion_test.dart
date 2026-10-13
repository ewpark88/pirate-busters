import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

const int _fuel = SideState.fuelUnit;

Match _calm({MatchRules rules = const MatchRules(calmSea: true)}) =>
    newSampleMatch(3, rules: rules);

SideState _me(Match m) => m.state.sides[m.state.activeSide];

SideState _foe(Match m) => m.state.sides[1 - m.state.activeSide];

int _gap(Match m) => (m.state.sides[1].bowX - m.state.sides[0].bowX).abs();

void main() {
  group('이동 (설계서 §2.5)', () {
    test('시작 간격은 뱃머리 사이 22칸이다 (BALANCE.md A2.6)', () {
      expect(_gap(_calm()), 22 * cellUnit);
    });

    test('MOVE 는 1/10칸 단위로 전진하고, 전진하면 상대와 가까워진다', () {
      final m = _calm();
      final me = _me(m);
      final before = me.bowX;
      m.apply(const MoveCommand(t: 100, dx: 25));
      expect(me.offset, 2500);
      expect((me.bowX - before).abs(), 2500);
      expect(_gap(m), 22 * cellUnit - 2500);
    });

    test('가운데 선 없이 적진 앞까지 가고, 상대와 최소 간격 2칸에서 멈춘다', () {
      final m = _calm()..apply(const MoveCommand(t: 10, dx: 0)); // 턴 시작
      final me = _me(m);
      // 한계만 본다: 30칸 분량 연료를 채운다(가득 찬 탱크는 6칸).
      me.fuel = 30 * me.fuelPerCell;
      final fuel = me.fuel;
      m.apply(const MoveCommand(t: 100, dx: 300));
      expect(_gap(m), 2 * cellUnit);
      expect(me.offset, 20 * cellUnit, reason: '가운데(11칸)를 넘어 간다');
      expect(me.fuel, fuel - 20 * me.fuelPerCell, reason: '막힌 거리는 안 쓴다');
    });

    test('상대 배가 다가와 있으면 그만큼 덜 간다', () {
      final m = _calm()..apply(const MoveCommand(t: 10, dx: 0));
      final me = _me(m)..fuel = 30 * SideState.fuelUnit * 10;
      _foe(m).offset = 15 * cellUnit;
      m.apply(const MoveCommand(t: 100, dx: 300));
      expect(me.offset, 5 * cellUnit);
      expect(_gap(m), 2 * cellUnit);
    });

    test('뒤로는 시작 위치에서 4칸(바다 끝)까지만 간다', () {
      final m = _calm()..apply(const MoveCommand(t: 10, dx: 0));
      final me = _me(m)..fuel = 30 * SideState.fuelUnit * 10;
      m.apply(const MoveCommand(t: 100, dx: -100));
      expect(me.offset, -4 * cellUnit);
    });

    test('연료가 모자라면 갈 수 있는 데까지만 간다', () {
      final m = _calm()..apply(const MoveCommand(t: 10, dx: 0));
      final me = _me(m);
      me.fuel = me.fuelPerCell * 5 ~/ 2; // 2.5칸 분량
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
      m.apply(const MoveCommand(t: 19000, dx: 50)); // 1초 = 2.8칸만
      expect(me.offset, 2800);
      m.apply(const MoveCommand(t: 19500, dx: 10)); // 이동이 20초에 끝났다
      expect(m.state.turn, turn);
      m.apply(const EndTurnCommand(t: 19600));
      expect(m.state.turn, turn + 1);
    });

    test('이동 이벤트에 거리·새 뱃머리 위치·걸린 시간이 담긴다', () {
      final m = _calm()..apply(const MoveCommand(t: 100, dx: -14));
      final e = m.state.events.lastWhere((e) => e.kind == SimEventKind.move);
      expect([e.value, e.x, e.y], [-1400, _me(m).bowX, 500]);
    });
  });

  group('연료 (설계서 §2.5, BALANCE.md A2.7)', () {
    test('판 시작 때 탱크가 가득 차 있다 (60, 한 턴 최대 6칸)', () {
      final m = _calm();
      for (final s in m.state.sides) {
        expect(s.fuel, 60 * _fuel);
        expect(s.fuel * cellUnit ~/ s.fuelPerCell, 6 * cellUnit);
      }
    });

    test('내 턴이 시작될 때 가득 채우고, 남은 연료는 이어지지 않는다', () {
      final m = _calm()..apply(const MoveCommand(t: 10, dx: 0)); // 턴 시작
      final me = _me(m);
      m.apply(const MoveCommand(t: 100, dx: 30));
      expect(me.fuel, 30 * _fuel);
      m
        ..apply(const EndTurnCommand(t: 3000))
        ..apply(const EndTurnCommand(t: 10)); // 상대 턴
      expect(me.fuel, 30 * _fuel, reason: '상대 턴에는 그대로');
      m.apply(const MoveCommand(t: 10, dx: 0)); // 내 턴 시작
      expect(me.fuel, 60 * _fuel);
    });
  });

  group('파도 구간 (설계서 §2.6, BALANCE.md A2.5)', () {
    test('구간은 가운데에서 바깥쪽으로 잔잔·보통·거침을 시드로 하나씩 섞어 둔다', () {
      const rules = MatchRules();
      final seen = <String>{};
      for (var seed = 1; seed <= 40; seed++) {
        final zones = rules.waveZonesFor(seed);
        expect([...zones]..sort(), [0, 1, 3]);
        seen.add(zones.join());
      }
      expect(seen.length, greaterThan(1), reason: '판마다 달라진다');
      expect(const MatchRules(calmSea: true).waveZonesFor(5), [0, 0, 0]);
    });

    test('구간 번호는 가운데에서 떨어진 정도로 정하고 좌우 대칭이다', () {
      final s = _calm().state;
      final w = s.rules.waveZoneWidth;
      expect(waveZoneIndex(s, 0), 0);
      expect(waveZoneIndex(s, w - 1), 0);
      expect(waveZoneIndex(s, -w), 1);
      expect(waveZoneIndex(s, w), 1);
      expect(waveZoneIndex(s, 99 * cellUnit), 2, reason: '바깥 너머는 마지막');
    });

    test('배는 뱃머리가 선 구간의 세기만큼 흔들리고, 잔잔하면 흔들리지 않는다', () {
      final m = newSampleMatch(3);
      final s = m.state;
      final calmZone = s.waveZones.indexOf(0);
      final roughZone = s.waveZones.indexOf(3);
      final me = s.sides[0];
      int heaveAt(int zone) {
        // 왼쪽 배의 뱃머리 칸 중심을 그 구간 가운데(가운데 선 왼쪽)에 둔다.
        final w = s.rules.waveZoneWidth;
        final center = -(zone * w + w ~/ 2);
        final start = me.bowX - me.offset;
        me.offset = center + cellUnit ~/ 2 - start;
        var most = 0;
        for (var ms = 0; ms < s.rules.wavePeriodMs; ms += 100) {
          final h = Wave(s).heave(0, ms).abs();
          if (h > most) most = h;
        }
        return most;
      }

      expect(heaveAt(calmZone), 0);
      expect(heaveAt(roughZone), 3 * s.rules.waveHeavePerLevel);
    });
  });
}
