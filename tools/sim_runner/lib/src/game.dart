import 'package:pb_ai/pb_ai.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';

/// 한 판의 구성: 양쪽 덱·설계도·난이도·성격.
class GameSetup {
  const GameSetup({
    required this.seed,
    required this.decks,
    required this.blueprints,
    required this.levels,
    required this.personalities,
  });

  final int seed;
  final List<List<String>> decks;
  final List<String> blueprints;
  final List<AiLevel> levels;
  final List<Personality> personalities;
}

/// 한 판의 결과 (집계용).
class GameResult {
  const GameResult({
    required this.setup,
    required this.outcome,
    required this.winner,
    required this.turns,
    required this.moveCells,
    required this.gapSum,
    required this.gapSamples,
  });

  final GameSetup setup;
  final MatchOutcome outcome;

  /// 이긴 진영, 무승부 −1.
  final int winner;
  final int turns;

  /// 두 배가 움직인 거리 합(칸).
  final int moveCells;

  /// 턴 끝마다 잰 뱃머리 간격(칸)의 합과 횟수.
  final int gapSum;
  final int gapSamples;
}

/// 게임 데이터로 판을 만들고 두는 도구.
class GameFactory {
  GameFactory(this.data, this.presets) : catalog = data.catalog;

  final GameData data;
  final List<BlueprintPreset> presets;
  final PirateCatalog catalog;

  /// [seed] 로 덱(코스트 한도 안 4명)·설계도·성격을 고른다. 난이도는 [levels].
  GameSetup setupFor(int seed, List<AiLevel> levels) {
    final rng = XorShift32(seed * 2654435761);
    List<String> deck() {
      final ids = [for (final p in data.pirates) p.id];
      // 선실 4칸을 코스트 한도 안에서 채운다(덱 크기가 승률을 흐리지 않게).
      const size = 4;
      final out = <String>[];
      var guard = 0;
      while (out.length < size && guard++ < 200) {
        final id = ids[rng.nextInt(ids.length)];
        if (out.contains(id)) continue;
        final next = [...out, id];
        if (deckProblem(HullSpec.sloop, catalog, next, costLimitForLevel(1)) ==
            null) {
          out.add(id);
        }
      }
      return out;
    }

    return GameSetup(
      seed: seed,
      decks: [deck(), deck()],
      blueprints: [
        presets[rng.nextInt(presets.length)].id,
        presets[rng.nextInt(presets.length)].id,
      ],
      levels: levels,
      personalities: [
        Personality.values[rng.nextInt(Personality.values.length)],
        Personality.values[rng.nextInt(Personality.values.length)],
      ],
    );
  }

  Blueprint _blueprint(String id) =>
      presets.firstWhere((p) => p.id == id).blueprint;

  /// 한 판을 끝까지 둔다.
  GameResult play(GameSetup s) {
    final match = Match.start(
      seed: s.seed,
      blueprints: [for (final b in s.blueprints) _blueprint(b)],
      decks: s.decks,
      costLimits: [costLimitForLevel(1), costLimitForLevel(1)],
      pirates: catalog,
    );
    final ais = [
      for (var i = 0; i < 2; i++)
        AiController(level: s.levels[i], personality: s.personalities[i]),
    ];
    var moved = 0;
    var gapSum = 0;
    var samples = 0;
    while (!match.isOver) {
      final state = match.state;
      final bundle = ais[state.activeSide].turnFor(state);
      for (final c in bundle.commands) {
        if (c is MoveCommand) moved += c.dx.abs();
      }
      match.playTurn(bundle);
      gapSum += (state.sides[0].bowX - state.sides[1].bowX).abs() ~/ cellUnit;
      samples++;
    }
    final state = match.state;
    return GameResult(
      setup: s,
      outcome: state.outcome,
      winner: state.winner,
      turns: match.turnLog.length,
      moveCells: moved ~/ 10,
      gapSum: gapSum,
      gapSamples: samples,
    );
  }
}
