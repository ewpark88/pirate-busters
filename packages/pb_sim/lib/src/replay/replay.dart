import 'package:pb_sim/src/command/command.dart';
import 'package:pb_sim/src/json_read.dart';
import 'package:pb_sim/src/match/controller.dart';
import 'package:pb_sim/src/match/match.dart';
import 'package:pb_sim/src/match/rules.dart';
import 'package:pb_sim/src/pirate/pirate_spec.dart';
import 'package:pb_sim/src/ship/blueprint.dart';

/// 매치 파라미터 (설계서 §7.2): 진영별 선체 보정 ‰(§3.5), 켜진 세트(§4.7), 수치 버전.
/// MVP 는 보정 1000·세트 없음이다. 보정·세트는 R4·A3 에서 판에 적용한다.
class MatchParams {
  const MatchParams({
    this.hullPermille = const [1000, 1000],
    this.sets = const [<String>[], <String>[]],
    this.dataVersion = '',
  });

  factory MatchParams.fromJson(Map<String, Object?> json) => MatchParams(
    hullPermille: [
      for (final v in readList(json, 'hullPermille')) asInt(v, '선체 보정'),
    ],
    sets: [
      for (final side in readList(json, 'sets'))
        [
          for (final id in Replay._asList(side, '세트')) asString(id, '세트 id'),
        ],
    ],
    dataVersion: readString(json, 'dataVersion'),
  );

  final List<int> hullPermille;
  final List<List<String>> sets;

  /// 게임 데이터(해적·탄종·BALANCE) 수치 버전.
  final String dataVersion;

  /// 지금 판에 적용할 수 있는가: MVP 는 보정 1000·세트 없음만.
  bool get supported =>
      hullPermille.length == 2 &&
      hullPermille.every((v) => v == 1000) &&
      sets.length == 2 &&
      sets.every((s) => s.isEmpty);

  Map<String, Object?> toJson() => {
    'hullPermille': hullPermille,
    'sets': sets,
    'dataVersion': dataVersion,
  };
}

/// 리플레이 = 시드 + 양쪽 배 설계도 + 덱 + 매치 파라미터 + 턴 묶음 목록
/// (설계서 §7.2, ADR-007).
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
    this.params = const MatchParams(),
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
      params: MatchParams.fromJson(asMap(json['params'], '매치 파라미터')),
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
    MatchParams params = const MatchParams(),
  }) => Replay(
    params: params,
    seed: match.state.seed,
    rules: match.state.rules,
    blueprints: blueprints,
    decks: decks,
    costLimits: costLimits,
    turns: match.turnLog,
  );

  /// 리플레이 JSON 형식 버전. v7: TAP `ticks`·`dir`, 매치 파라미터, 2발로 턴을
  /// 닫지 않음(ADR-042). 이전 버전은 읽지 않는다(배포된 리플레이가 없다).
  static const int formatVersion = 7;

  final int seed;
  final MatchRules rules;
  final MatchParams params;
  final List<Blueprint> blueprints;
  final List<List<String>> decks;
  final List<int> costLimits;

  /// 턴 순서의 턴 묶음(턴 끝 해시 포함).
  final List<TurnBundle> turns;

  Map<String, Object?> toJson() => {
    'version': formatVersion,
    'seed': seed,
    'rules': rules.toJson(),
    'params': params.toJson(),
    'blueprints': [for (final b in blueprints) b.toJson()],
    'decks': decks,
    'costLimits': costLimits,
    'turns': [for (final t in turns) t.toJson()],
  };

  /// 처음부터 다시 돌린다. 턴 해시가 다르면 [TurnHashMismatch].
  Match play({required PirateCatalog pirates}) {
    if (!params.supported) {
      throw ArgumentError('선체 보정·세트가 든 리플레이는 아직 재생할 수 없다(R4·A3)');
    }
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
