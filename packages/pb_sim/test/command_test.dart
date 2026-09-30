import 'dart:convert';

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

Map<String, Object?> _map(String s) => jsonDecode(s) as Map<String, Object?>;

void main() {
  test('설계서 §7.2 의 턴 묶음 JSON 을 읽는다 (MOVE 는 M3)', () {
    final b = TurnBundle.fromJson(
      _map('''
{ "turn": 7, "side": 0, "cmds": [
  { "t": 9800,  "type": "FIRE", "slot": 3, "angle": 41250, "power": 7800 },
  { "t": 10900, "type": "TAP",  "slot": 3, "ticks": 25, "dir": 1 },
  { "t": 16400, "type": "FIRE", "slot": 1, "angle": 30500, "power": 6100 },
  { "t": 21000, "type": "END_TURN" }
], "hash": "9f3a1c07" }'''),
    );
    expect([b.turn, b.side, b.hash], [7, 0, 0x9f3a1c07]);
    expect(
      [for (final c in b.commands) c.runtimeType],
      [
        FireCommand,
        TapCommand,
        FireCommand,
        EndTurnCommand,
      ],
    );
    final fire = b.commands.first as FireCommand;
    expect([fire.t, fire.slot, fire.angle, fire.power], [9800, 3, 41250, 7800]);
    final tap = b.commands[1] as TapCommand;
    expect([tap.ticks, tap.dir], [25, 1]);
  });

  test('턴 묶음은 JSON 으로 저장했다 읽어도 같다', () {
    final b = TurnBundle(
      turn: 2,
      side: 1,
      commands: const [
        FireCommand(t: 100, slot: 2, angle: 1000, power: 5000),
        TapCommand(t: 200, slot: 2, ticks: 3),
        SurrenderCommand(t: 300),
      ],
      hash: 0x0000abcd,
    );
    final text = jsonEncode(b.toJson());
    expect(text, contains('"hash":"0000abcd"'));
    expect(jsonEncode(TurnBundle.fromJson(_map(text)).toJson()), text);
  });

  test('형식이 틀린 턴 묶음은 FormatException 을 낸다', () {
    for (final bad in [
      '{"turn":0,"side":0,"cmds":[]}',
      '{"turn":1,"side":2,"cmds":[]}',
      '{"turn":1,"side":0,"cmds":[{"t":-1,"type":"END_TURN"}]}',
      '{"turn":1,"side":0,"cmds":[{"t":1,"type":"JUMP"}]}',
      '{"turn":1,"side":0,"cmds":[{"t":1,"type":"FIRE","slot":0,"angle":1.5,"power":1}]}',
      '{"turn":1,"side":0,"cmds":[{"t":5,"type":"END_TURN"},{"t":4,"type":"END_TURN"}]}',
      '{"turn":1,"side":0,"cmds":[],"hash":7}',
    ]) {
      expect(
        () => TurnBundle.fromJson(_map(bad)),
        throwsFormatException,
        reason: bad,
      );
    }
  });
}
