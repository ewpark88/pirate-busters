import 'package:pb_sim/pb_sim.dart';
import 'package:sim_runner/src/game.dart';

/// 승·패·무 집계.
class Tally {
  int games = 0;
  int wins = 0;
  int draws = 0;

  /// 승률(%). 무승부는 반으로 센다.
  double get winRate => games == 0 ? 0 : (wins + draws / 2) * 100 / games;

  void add({required bool win, required bool draw}) {
    games++;
    if (win) wins++;
    if (draw) draws++;
  }
}

/// 여러 판 결과의 요약 (개발 계획서 M6 sim_runner 출력).
class Report {
  Report(this.results, this.catalog);

  final List<GameResult> results;
  final PirateCatalog catalog;

  /// 경고 기준: 승률 55% 초과 해적, 시간 판정 25% 초과 (BALANCE.md B10).
  static const double maxWinRate = 55;
  static const double maxTimeDecision = 25;

  /// 해적별 승률을 믿을 최소 출전 수.
  static const int minGames = 30;

  final Map<String, Tally> pirates = {};
  final Map<String, Tally> families = {};
  final Map<String, Tally> ranges = {};
  final Map<String, Tally> levels = {};
  final Map<MatchOutcome, int> outcomes = {};
  final Map<String, int> comboGames = {};
  final Map<String, int> comboTime = {};
  var _turns = 0;
  var _moves = 0;
  var _gapSum = 0;
  var _gapSamples = 0;

  void build() {
    for (final r in results) {
      _turns += r.turns;
      _moves += r.moveCells;
      _gapSum += r.gapSum;
      _gapSamples += r.gapSamples;
      outcomes[r.outcome] = (outcomes[r.outcome] ?? 0) + 1;
      final combo = ([...r.setup.blueprints]..sort()).join('+');
      comboGames[combo] = (comboGames[combo] ?? 0) + 1;
      if (r.outcome == MatchOutcome.timeDecision) {
        comboTime[combo] = (comboTime[combo] ?? 0) + 1;
      }
      for (var side = 0; side < 2; side++) {
        final win = r.winner == side;
        final draw = r.winner == -1;
        (levels[r.setup.levels[side].name] ??= Tally()).add(
          win: win,
          draw: draw,
        );
        for (final id in r.setup.decks[side]) {
          final spec = catalog.byId(id);
          (pirates[id] ??= Tally()).add(win: win, draw: draw);
          (families[spec.family.jsonName] ??= Tally()).add(
            win: win,
            draw: draw,
          );
          (ranges[spec.range.name] ??= Tally()).add(win: win, draw: draw);
        }
      }
    }
  }

  int get games => results.length;
  double get avgTurns => games == 0 ? 0 : _turns / games;
  double get movePerTurn => _turns == 0 ? 0 : _moves / _turns;
  double get avgGap => _gapSamples == 0 ? 0 : _gapSum / _gapSamples;

  double outcomeRate(MatchOutcome o) =>
      games == 0 ? 0 : (outcomes[o] ?? 0) * 100 / games;

  /// 경고 목록.
  List<String> get warnings {
    final out = <String>[];
    for (final e in _sorted(pirates)) {
      if (e.value.games >= minGames && e.value.winRate > maxWinRate) {
        out.add('pirate ${e.key} win ${_pct(e.value.winRate)} > $maxWinRate%');
      }
    }
    final time = outcomeRate(MatchOutcome.timeDecision);
    if (time > maxTimeDecision) {
      out.add('time decision ${_pct(time)} > $maxTimeDecision%');
    }
    for (final e in _sorted(comboGames)) {
      final rate = (comboTime[e.key] ?? 0) * 100 / e.value;
      if (e.value >= minGames && rate > maxTimeDecision) {
        out.add('blueprints ${e.key} time decision ${_pct(rate)}');
      }
    }
    return out;
  }

  static List<MapEntry<String, T>> _sorted<T>(Map<String, T> m) =>
      m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

  static String _pct(double v) => '${v.toStringAsFixed(1)}%';

  /// 사람이 읽는 표.
  String text() {
    final b = StringBuffer()
      ..writeln(
        'games $games  avg turns ${avgTurns.toStringAsFixed(1)}  '
        'move/turn ${movePerTurn.toStringAsFixed(2)} cells  '
        'avg gap ${avgGap.toStringAsFixed(1)} cells',
      )
      ..writeln(
        'outcome: ${[for (final o in MatchOutcome.values)
          if (o != MatchOutcome.ongoing) '${o.name} ${_pct(outcomeRate(o))}'].join('  ')}',
      );
    void table(String title, Map<String, Tally> m) {
      b.writeln('-- $title (win% / games)');
      for (final e in _sorted(m)) {
        b.writeln(
          '  ${e.key.padRight(14)} ${_pct(e.value.winRate).padLeft(6)} / ${e.value.games}',
        );
      }
    }

    table('level', levels);
    table('pirate', pirates);
    table('family', families);
    table('range', ranges);
    final w = warnings;
    b.writeln(w.isEmpty ? 'warnings: none' : 'warnings:\n  ${w.join('\n  ')}');
    return b.toString();
  }

  /// CSV: kind,key,games,wins,draws,win_rate
  String csv() {
    final b = StringBuffer()..writeln('kind,key,games,wins,draws,win_rate');
    void rows(String kind, Map<String, Tally> m) {
      for (final e in _sorted(m)) {
        final t = e.value;
        b.writeln(
          '$kind,${e.key},${t.games},${t.wins},${t.draws},${t.winRate.toStringAsFixed(2)}',
        );
      }
    }

    rows('level', levels);
    rows('pirate', pirates);
    rows('family', families);
    rows('range', ranges);
    for (final o in MatchOutcome.values) {
      if (o == MatchOutcome.ongoing) continue;
      b.writeln(
        'outcome,${o.name},${outcomes[o] ?? 0},,,${outcomeRate(o).toStringAsFixed(2)}',
      );
    }
    b
      ..writeln('summary,avg_turns,$games,,,${avgTurns.toStringAsFixed(2)}')
      ..writeln(
        'summary,move_per_turn,$games,,,${movePerTurn.toStringAsFixed(3)}',
      )
      ..writeln('summary,avg_gap,$games,,,${avgGap.toStringAsFixed(2)}');
    return b.toString();
  }
}
