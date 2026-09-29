import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

FireCommand _fire(int t, int slot, {int angle = 45000}) =>
    FireCommand(t: t, slot: slot, angle: angle, power: 6000);

/// 지금 턴에 [commands] 를 적용한다.
Match _play(Match m, List<Command> commands) {
  final s = m.state;
  m.playTurn(TurnBundle(turn: s.turn, side: s.activeSide, commands: commands));
  return m;
}

List<TurnEndReason> _endReasons(MatchState s) => [
  for (final e in s.events)
    if (e.kind == SimEventKind.turnEnd) TurnEndReason.values[e.cell],
];

void main() {
  group('턴 구조 (설계서 §2.3)', () {
    test('선공은 시드로 정하고 턴마다 번갈아 둔다', () {
      final firsts = {
        for (var seed = 0; seed < 40; seed++)
          newSampleMatch(seed).state.firstSide,
      };
      expect(firsts, {0, 1});
      final m = newSampleMatch(3);
      final first = m.state.firstSide;
      expect(m.state.activeSide, first);
      _play(m, const [EndTurnCommand(t: 100)]);
      expect([m.state.turn, m.state.activeSide], [2, 1 - first]);
      _play(m, const [EndTurnCommand(t: 100)]);
      expect(m.state.activeSide, first);
    });

    test('한 턴에 서로 다른 해적 2명까지 쏘고, 2발을 쏘면 턴이 자동으로 끝난다', () {
      final m = newSampleMatch(1);
      final side = m.state.activeSide;
      m
        ..apply(_fire(100, 0))
        ..apply(_fire(200, 0)); // 같은 해적은 같은 턴에 다시 못 쏜다
      expect(m.state.sides[side].shotsFired, 1);
      expect(m.state.turn, 1);
      m.apply(_fire(300, 1));
      expect(m.state.sides[side].shotsFired, 2);
      expect(m.state.turn, 2);
      expect(_endReasons(m.state), [TurnEndReason.firesUsed]);
    });

    test('쿨다운 0턴은 다음 내 턴에, 1턴은 내 턴 하나를 건너뛴 뒤에 다시 쏜다', () {
      final m = newSampleMatch(1); // 슬롯 0 = p01 (0턴), 슬롯 1 = p06 (1턴)
      final me = m.state.activeSide;
      final crew = m.state.sides[me].crew;
      _play(m, [_fire(100, 0), _fire(200, 1)]);
      _play(m, const [EndTurnCommand(t: 100)]); // 상대
      expect([crew.canFire(0), crew.canFire(1)], [true, false]);
      _play(m, const [EndTurnCommand(t: 100)]);
      _play(m, const [EndTurnCommand(t: 100)]);
      expect(crew.canFire(1), isTrue);
    });

    test('턴 제한 시간(탄 비행 시간 제외)이 지난 커맨드는 버리고 턴을 넘긴다', () {
      final m = newSampleMatch(1);
      final side = m.state.activeSide;
      _play(m, [
        _fire(24000, 0),
        // 탄이 날아간 시간만큼 타이머가 멈췄으므로 25초를 조금 넘어도 유효하다.
        _fire(25500, 1),
      ]);
      expect(m.state.sides[side].shotsFired, 2);

      final m2 = newSampleMatch(1);
      _play(m2, [_fire(25001, 0)]);
      expect(m2.state.sides[side].shotsFired, 0);
      expect(_endReasons(m2.state), [TurnEndReason.timeout]);
    });

    test('END_TURN 없이 끝난 묶음은 시간 초과로 넘어간다', () {
      final m = _play(newSampleMatch(1), const []);
      expect(m.state.turn, 2);
      expect(_endReasons(m.state), [TurnEndReason.timeout]);
    });

    test('차례가 아닌 턴 묶음은 받지 않는다', () {
      final m = newSampleMatch(1);
      final other = 1 - m.state.activeSide;
      expect(
        () => m.playTurn(TurnBundle(turn: 1, side: other, commands: const [])),
        throwsArgumentError,
      );
      expect(
        () => m.playTurn(
          TurnBundle(turn: 2, side: m.state.activeSide, commands: const []),
        ),
        throwsArgumentError,
      );
    });

    test('각도·힘이 범위를 벗어난 발사는 무시한다', () {
      final m = newSampleMatch(1);
      final side = m.state.activeSide;
      _play(m, const [
        FireCommand(t: 1, slot: 0, angle: -1, power: 10),
        FireCommand(t: 2, slot: 1, angle: 360000, power: 10),
        FireCommand(t: 3, slot: 2, angle: 0, power: 10001),
        FireCommand(t: 4, slot: 9, angle: 0, power: 10),
      ]);
      expect(m.state.sides[side].shotsFired, 0);
    });

    test('바람은 시드와 턴 번호로만 정해지고 −3~+3 이다', () {
      const rules = MatchRules();
      final winds = [for (var t = 1; t <= 200; t++) rules.windForTurn(99, t)];
      expect(winds.every((w) => w >= -3 && w <= 3), isTrue);
      expect(winds.toSet(), hasLength(7));
      final m = newSampleMatch(99);
      expect(m.state.wind, rules.windForTurn(99, 1));
      _play(m, const [EndTurnCommand(t: 1)]);
      expect(m.state.wind, rules.windForTurn(99, 2));
    });
  });

  group('판 끝', () {
    test('항복하면 상대가 이기고 이후 턴은 두지 않는다', () {
      final m = newSampleMatch(1);
      final side = m.state.activeSide;
      _play(m, const [SurrenderCommand(t: 10), EndTurnCommand(t: 20)]);
      expect(m.state.outcome, MatchOutcome.surrender);
      expect(m.state.winner, 1 - side);
      final turn = m.state.turn;
      m.apply(const EndTurnCommand(t: 1));
      expect(m.state.turn, turn);
    });

    test('양쪽 합쳐 최대 턴 수가 끝나면 턴 제한으로 끝난다', () {
      final m = newSampleMatch(1);
      runMatch(m, passController, passController);
      expect(m.state.outcome, MatchOutcome.turnLimit);
      expect(m.turnLog, hasLength(30));
      expect(m.turnLog.where((b) => b.side == 0), hasLength(15));

      final short = newSampleMatch(1, rules: const MatchRules(maxTurns: 6));
      runMatch(short, passController, passController);
      expect(short.turnLog, hasLength(6));
    });
  });

  group('출전 명단 (설계서 §4.5)', () {
    Match start(List<String> left, {int limit = 15}) => Match.start(
      seed: 1,
      blueprints: [sampleBlueprint(), sampleBlueprint()],
      decks: [left, sampleDecks[1]],
      costLimits: [limit, 15],
      pirates: PirateCatalog([
        for (var i = 0; i < 8; i++) testPirate('c$i'),
        testPirate('h', rarity: Rarity.hero),
        testPirate('m', rarity: Rarity.myth),
        ...[for (final id in sampleDecks[1]) sampleCatalog.byId(id)],
      ]),
    );

    test('등급 코스트는 일반 3·희귀 4·영웅 5·전설 6·신화 8 이다', () {
      expect([for (final r in Rarity.values) r.cost], [3, 4, 5, 6, 8]);
    });

    test('코스트 합계가 한도를 넘으면 출전할 수 없다', () {
      expect(start(['c0', 'c1', 'c2', 'c3']).state.sides[0].crew.size, 4);
      expect(() => start(['m', 'h', 'c0']), throwsArgumentError); // 16 > 15
      expect(start(['m', 'h', 'c0'], limit: 16).state.sides[0].crew.size, 3);
    });

    test('선실 수보다 많거나 같은 해적이 둘이면 출전할 수 없다', () {
      expect(
        () => start(['c0', 'c1', 'c2', 'c3', 'c4'], limit: 40),
        throwsArgumentError,
      );
      expect(() => start(['c0', 'c0']), throwsArgumentError);
      expect(() => start([]), throwsArgumentError);
    });

    test('출전 해적은 모두 처음부터 선실에 타고 교대는 없다', () {
      final m = start(['c0', 'c1']);
      final crew = m.state.sides[0].crew;
      expect(
        [for (final p in crew.pirates) p.status],
        [
          PirateStatus.aboard,
          PirateStatus.aboard,
        ],
      );
      expect(crew.pirateAt(2), isNull);
      expect(maxLineup, 7);
    });
  });
}
