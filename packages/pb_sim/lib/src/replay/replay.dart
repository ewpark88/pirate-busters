import 'package:pb_sim/src/command/command.dart';
import 'package:pb_sim/src/json_read.dart';
import 'package:pb_sim/src/match/controller.dart';
import 'package:pb_sim/src/match/match.dart';
import 'package:pb_sim/src/match/match_state.dart';
import 'package:pb_sim/src/ship/blueprint.dart';

/// 리플레이 = 시드 + 양쪽 설계도 + 덱 + 커맨드 목록 (설계서 §7.2, ADR-007).
class Replay {
  Replay({
    required this.seed,
    required List<Blueprint> blueprints,
    required List<List<String>> decks,
    required List<Command> commands,
  }) : blueprints = List.unmodifiable(blueprints),
       decks = List<List<String>>.unmodifiable([
         for (final d in decks) List<String>.unmodifiable(d),
       ]),
       commands = List.unmodifiable(commands.toList()..sort(Command.compare)) {
    if (blueprints.length != 2 || decks.length != 2) {
      throw ArgumentError('설계도와 덱은 진영마다 하나씩 2개여야 한다');
    }
  }

  /// 형식 오류는 [FormatException], 규칙 위반은 [ArgumentError].
  factory Replay.fromJson(Map<String, Object?> json) {
    final version = readInt(json, 'version');
    if (version != formatVersion) {
      throw FormatException('지원하지 않는 리플레이 버전: $version');
    }
    return Replay(
      seed: readInt(json, 'seed'),
      blueprints: [
        for (final b in readList(json, 'blueprints'))
          Blueprint.fromJson(asMap(b, '설계도')),
      ],
      decks: [
        for (final d in readList(json, 'decks'))
          [
            for (final id in _asList(d, '덱')) asString(id, '해적 id'),
          ],
      ],
      commands: [
        for (final c in readList(json, 'commands'))
          Command.fromJson(asMap(c, '커맨드')),
      ],
    );
  }

  /// 판을 끝까지(또는 진행한 만큼) 돌린 [match] 로 리플레이를 만든다.
  factory Replay.fromMatch({
    required int seed,
    required List<Blueprint> blueprints,
    required List<List<String>> decks,
    required Match match,
  }) => Replay(
    seed: seed,
    blueprints: blueprints,
    decks: decks,
    commands: match.commandLog,
  );

  /// 리플레이 JSON 형식 버전. 형식을 바꾸면 올린다.
  static const int formatVersion = 1;

  final int seed;
  final List<Blueprint> blueprints;
  final List<List<String>> decks;

  /// 적용 순서로 정렬된 커맨드.
  final List<Command> commands;

  Map<String, Object?> toJson() => {
    'version': formatVersion,
    'seed': seed,
    'blueprints': [for (final b in blueprints) b.toJson()],
    'decks': decks,
    'commands': [for (final c in commands) c.toJson()],
  };

  /// 처음부터 다시 돌린다. [ticks] 를 주지 않으면 판이 끝날 때까지 돌린다.
  Match play({int ticks = matchDurationTicks}) {
    final match = Match.start(seed: seed, blueprints: blueprints, decks: decks);
    final script = ScriptedController(commands);
    runMatch(match, script, script, ticks: ticks);
    return match;
  }

  static List<Object?> _asList(Object? v, String what) {
    if (v is List<Object?>) return v;
    throw FormatException('$what 는 배열이어야 한다: $v');
  }
}
