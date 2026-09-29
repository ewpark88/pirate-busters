// 골든 리플레이를 다시 만든다: `dart run test/golden/generate.dart` (packages/pb_sim 에서).
// 규칙을 일부러 바꿨을 때만 돌리고, 커밋 메시지에 이유를 적는다.
import 'dart:convert';
import 'dart:io';

import 'golden_scenarios.dart';

void main() {
  const encoder = JsonEncoder.withIndent(' ');
  for (final g in goldenScenarios) {
    final r = g.run();
    final json = {
      'name': g.name,
      'expect': {
        'outcome': r.outcome.name,
        'winner': r.winner,
        'turns': r.turns,
        'hash': r.hash.toRadixString(16).padLeft(8, '0'),
      },
      'replay': r.replay.toJson(),
    };
    File('test/golden/${g.name}.json').writeAsStringSync(
      '${encoder.convert(json)}\n',
    );
    stdout.writeln(
      '${g.name}: ${r.outcome.name} winner ${r.winner} '
      'turns ${r.turns}',
    );
  }
}
