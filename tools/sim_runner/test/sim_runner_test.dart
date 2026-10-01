import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:sim_runner/sim_runner.dart';
import 'package:test/test.dart';

const _dataDir = '../../app/assets/game';

void main() {
  final data = readData(_dataDir);
  final factory = factoryFrom(data);

  test('인자를 읽고, 난이도가 다르면 판마다 좌우를 바꾼다', () {
    final o = SimOptions.parse([
      '--games', '10', '--seed', '5', '--left', 'hard', '--right', 'easy', //
      '--jobs', '2', '--data', _dataDir,
    ]);
    expect([o.games, o.seed, o.jobs], [10, 5, 2]);
    expect(o.levelsFor(0), [AiLevel.hard, AiLevel.easy]);
    expect(o.levelsFor(1), [AiLevel.easy, AiLevel.hard]);
    expect(() => SimOptions.parse(['--left', 'god']), throwsFormatException);
  });

  test('판 구성은 시드로 정해지고 덱은 코스트 한도 안 4명이다 (§4.5)', () {
    for (var seed = 1; seed < 40; seed++) {
      final a = factory.setupFor(seed, const [AiLevel.normal, AiLevel.normal]);
      final b = factory.setupFor(seed, const [AiLevel.normal, AiLevel.normal]);
      expect(a.decks, b.decks);
      expect(a.blueprints, b.blueprints);
      for (final deck in a.decks) {
        expect(deck, hasLength(4));
        expect(
          deckProblem(
            HullSpec.sloop,
            factory.catalog,
            deck,
            costLimitForLevel(1),
          ),
          isNull,
        );
      }
    }
  });

  test('같은 범위를 두 번 두면 결과가 같다(결정론)', () {
    const o = _Opts();
    final a = runRange(data, o.options, 0, 3);
    final b = runRange(data, o.options, 0, 3);
    expect(
      [for (final r in a) (r.outcome, r.winner, r.turns, r.moveCells)],
      [for (final r in b) (r.outcome, r.winner, r.turns, r.moveCells)],
    );
    expect(a.every((r) => r.turns > 0 && r.turns <= 30), isTrue);
  });

  test('요약: 같은 등급 평균보다 5%p 넘게 이기는 해적과 시간 판정 25% 초과를 경고한다', () {
    final setup = factory.setupFor(1, const [AiLevel.normal, AiLevel.normal]);
    GameResult game(MatchOutcome o, int winner) => GameResult(
      setup: setup,
      outcome: o,
      winner: winner,
      turns: 30,
      moveCells: 0,
      gapSum: 28,
      gapSamples: 1,
    );
    final results = [
      for (var i = 0; i < 40; i++)
        game(
          i < 20 ? MatchOutcome.timeDecision : MatchOutcome.sunk,
          0,
        ),
    ];
    final report = Report(results, factory.catalog)..build();
    expect(report.outcomeRate(MatchOutcome.timeDecision), 50);
    expect(report.warnings, contains(startsWith('time decision')));
    // 왼쪽만 이긴 판들이라 왼쪽 덱에만 있는 일반 해적은 승률 100% 로, 같은 등급
    // 평균(오른쪽 덱 해적 0% 와 섞임)보다 5%p 넘게 높아 경고된다.
    final onlyLeft = setup.decks[0].where(
      (id) =>
          !setup.decks[1].contains(id) &&
          factory.catalog.byId(id).rarity == Rarity.common,
    );
    expect(onlyLeft, isNotEmpty);
    for (final id in onlyLeft) {
      expect(report.warnings, contains(startsWith('pirate $id')));
    }
    expect(
      report.csv().split('\n').first,
      'kind,key,games,wins,draws,win_rate',
    );
  });

  test('덱 풀·설계도 풀을 주면 그 안에서만 판을 만든다', () {
    final o = SimOptions.parse([
      '--pirates', 'p01_octo,p06_pang,p16_suri,p36_tok,p27_wing', //
      '--blueprints', 'armored',
      '--data', _dataDir,
    ]);
    final f = factoryFrom(data, pirates: o.pirates, blueprints: o.blueprints);
    for (var seed = 1; seed < 20; seed++) {
      final s = f.setupFor(seed, const [AiLevel.normal, AiLevel.normal]);
      expect(s.blueprints, ['armored', 'armored']);
      for (final deck in s.decks) {
        expect(o.pirates, containsAll(deck));
      }
    }
    expect(
      () => factoryFrom(data, blueprints: const ['nope']),
      throwsArgumentError,
    );
  });
}

class _Opts {
  const _Opts();

  SimOptions get options => SimOptions(games: 3, jobs: 1, dataDir: _dataDir);
}
