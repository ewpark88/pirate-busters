import 'package:pb_sim/src/command/command.dart';
import 'package:pb_sim/src/json_read.dart';
import 'package:pb_sim/src/match/controller.dart';
import 'package:pb_sim/src/match/match.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/ship/blueprint.dart';

/// 리플레이 = 시드 + 양쪽 배 설계도 + 덱 + 턴 묶음 목록 (설계서 §7.2, ADR-007).
///
/// 덱은 해적 id 만 담는다. 재생할 때 같은 해적 정의([PirateCatalog])가 필요하다.
/// 규칙 수치와 코스트 한도도 같이 담아 같은 판을 다시 만든다.
class Replay {
  Replay({
    required this.seed,
    required List<Blueprint> blueprints,
    required List<List<String>> decks,
    required List<int> costLimits,
    required List<TurnBundle> turns,
    this.rules = const MatchRules(),
  }) : blueprints = List.unmodifiable(blueprints),
       decks = List<List<String>>.unmodifiable([
         for (final d in decks) List<String>.unmodifiable(d),
       ]),
       costLimits = List.unmodifiable(costLimits),
       turns = List.unmodifiable(turns) {
    if (blueprints.length != 2 || decks.length != 2 || costLimits.length != 2) {
      throw ArgumentError('설계도·덱·코스트 한도는 진영마다 하나씩 2개여야 한다');
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
      rules: MatchRules.fromJson(asMap(json['rules'], '규칙')),
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
      costLimits: [
        for (final c in readList(json, 'costLimits')) asInt(c, '코스트 한도'),
      ],
      turns: [
        for (final t in readList(json, 'turns'))
          TurnBundle.fromJson(asMap(t, '턴 묶음')),
      ],
    );
  }

  /// 판을 끝까지(또는 진행한 만큼) 돌린 [match] 로 리플레이를 만든다.
  factory Replay.fromMatch({
    required List<Blueprint> blueprints,
    required List<List<String>> decks,
    required List<int> costLimits,
    required Match match,
  }) => Replay(
    seed: match.state.seed,
    rules: match.state.rules,
    blueprints: blueprints,
    decks: decks,
    costLimits: costLimits,
    turns: match.turnLog,
  );

  /// 리플레이 JSON 형식 버전. v5: 부서짐 정지 시간·한계 감속 구간 규칙 값(M3 재점검).
  /// 이전 버전은 읽지 않는다(배포된 리플레이가 없다).
  static const int formatVersion = 5;

  final int seed;
  final MatchRules rules;
  final List<Blueprint> blueprints;
  final List<List<String>> decks;
  final List<int> costLimits;

  /// 턴 순서의 턴 묶음(턴 끝 해시 포함).
  final List<TurnBundle> turns;

  Map<String, Object?> toJson() => {
    'version': formatVersion,
    'seed': seed,
    'rules': rules.toJson(),
    'blueprints': [for (final b in blueprints) b.toJson()],
    'decks': decks,
    'costLimits': costLimits,
    'turns': [for (final t in turns) t.toJson()],
  };

  /// 처음부터 다시 돌린다. 턴 해시가 다르면 [TurnHashMismatch].
  Match play({required PirateCatalog pirates}) {
    final match = Match.start(
      seed: seed,
      rules: rules,
      blueprints: blueprints,
      decks: decks,
      costLimits: costLimits,
      pirates: pirates,
    );
    final script = ScriptedController(turns);
    runMatch(match, script, script, maxTurns: turns.length);
    return match;
  }

  static List<Object?> _asList(Object? v, String what) {
    if (v is List<Object?>) return v;
    throw FormatException('$what 는 배열이어야 한다: $v');
  }
}
