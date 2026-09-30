/// AI 대 AI 대량 시뮬레이션 (설계서 §7.3, 개발 계획서 M6).
///
/// 덱 풀(해적 12명 중 코스트 한도 안 무작위)·설계도 풀(추천 설계도)로 판을 만들고
/// 여러 isolate 로 나눠 둔다. 결과는 표와 CSV 로 낸다. 같은 인자면 같은 결과다.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:pb_ai/pb_ai.dart';
import 'package:pb_data/pb_data.dart';
import 'package:sim_runner/src/game.dart';
import 'package:sim_runner/src/report.dart';

export 'src/game.dart';
export 'src/report.dart';

/// CLI 사용법 문구.
const String usage = '''
사용법: dart run sim_runner [옵션]
  --games N        판 수 (기본 1000)
  --seed S         첫 시드 (기본 1). 판 i 의 시드는 S + i
  --left LEVEL     왼쪽 AI 난이도 easy|normal|hard|hell (기본 normal)
  --right LEVEL    오른쪽 AI 난이도 (기본 --left 와 같음). 다르면 판마다 좌우를 바꾼다
  --jobs J         isolate 수 (기본 CPU 수)
  --csv PATH       CSV 로도 쓴다
  --data DIR       게임 데이터 폴더 (기본 app/assets/game)''';

/// 인자.
class SimOptions {
  SimOptions({
    this.games = 1000,
    this.seed = 1,
    this.left = AiLevel.normal,
    AiLevel? right,
    int? jobs,
    this.csv,
    this.dataDir = 'app/assets/game',
  }) : right = right ?? left,
       jobs = jobs ?? Platform.numberOfProcessors;

  /// 인자를 읽는다. 잘못되면 [FormatException].
  factory SimOptions.parse(List<String> args) {
    final m = <String, String>{};
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (!a.startsWith('--') || i + 1 >= args.length) {
        throw FormatException('알 수 없는 인자: $a');
      }
      m[a.substring(2)] = args[++i];
    }
    AiLevel level(String name) => AiLevel.values.firstWhere(
      (l) => l.name == name,
      orElse: () => throw FormatException('난이도: $name'),
    );
    final left = m.containsKey('left') ? level(m['left']!) : AiLevel.normal;
    return SimOptions(
      games: int.parse(m['games'] ?? '1000'),
      seed: int.parse(m['seed'] ?? '1'),
      left: left,
      right: m.containsKey('right') ? level(m['right']!) : left,
      jobs: m.containsKey('jobs') ? int.parse(m['jobs']!) : null,
      csv: m['csv'],
      dataDir: m['data'] ?? 'app/assets/game',
    );
  }

  final int games;
  final int seed;
  final AiLevel left;
  final AiLevel right;
  final int jobs;
  final String? csv;
  final String dataDir;

  /// 판 [i] 의 [좌, 우] 난이도. 난이도가 다르면 판마다 좌우를 바꾼다.
  List<AiLevel> levelsFor(int i) =>
      i.isOdd && left != right ? [right, left] : [left, right];
}

/// 데이터 파일 본문 (isolate 로 넘긴다).
typedef DataTexts = ({String ammo, String pirates, String blueprints});

DataTexts readData(String dir) => (
  ammo: File('$dir/ammo.json').readAsStringSync(),
  pirates: File('$dir/pirates.json').readAsStringSync(),
  blueprints: File('$dir/blueprints.json').readAsStringSync(),
);

GameFactory factoryFrom(DataTexts t) => GameFactory(
  GameData.parse(ammoJson: t.ammo, piratesJson: t.pirates),
  parsePresets(jsonDecode(t.blueprints)),
);

/// 판 [from] 부터 [to] 전까지 둔다.
List<GameResult> runRange(DataTexts data, SimOptions o, int from, int to) {
  final f = factoryFrom(data);
  return [
    for (var i = from; i < to; i++)
      f.play(f.setupFor(o.seed + i, o.levelsFor(i))),
  ];
}

/// 모든 판을 isolate 로 나눠 두고 요약한다.
Future<Report> runAll(SimOptions o) async {
  final data = readData(o.dataDir);
  final jobs = o.jobs < 1 ? 1 : o.jobs;
  final chunk = (o.games + jobs - 1) ~/ jobs;
  final parts = await Future.wait([
    for (var from = 0; from < o.games; from += chunk)
      Isolate.run(
        () => runRange(
          data,
          o,
          from,
          from + chunk > o.games ? o.games : from + chunk,
        ),
      ),
  ]);
  return Report([for (final p in parts) ...p], factoryFrom(data).catalog)
    ..build();
}
