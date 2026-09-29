import 'dart:convert';

import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

Command _parse(String s) =>
    Command.fromJson(jsonDecode(s) as Map<String, Object?>);

void main() {
  test('설계서 §7.2 의 커맨드 JSON 을 그대로 읽는다', () {
    final fire = _parse(
      '{ "tick": 1842, "side": 0, "type": "FIRE", "slot": 3, '
      '"angle": 41250, "power": 7800 }',
    );
    expect(fire, isA<FireCommand>());
    fire as FireCommand;
    expect(
      [fire.tick, fire.side, fire.slot, fire.angle, fire.power],
      [1842, 0, 3, 41250, 7800],
    );
    final tap = _parse(
      '{ "tick": 1901, "side": 0, "type": "TAP",  "slot": 3 }',
    );
    expect(tap, isA<TapCommand>());
    expect(
      _parse('{"tick": 5, "side": 1, "type": "SURRENDER"}'),
      isA<SurrenderCommand>(),
    );
    final move = _parse(
      '{ "tick": 2010, "side": 0, "type": "MOVE", "dir": 1 }',
    );
    expect(move, isA<MoveCommand>());
    expect((move as MoveCommand).dir, 1);
  });

  test('커맨드는 JSON 으로 저장했다 읽어도 같다', () {
    const cmds = <Command>[
      FireCommand(tick: 1, side: 1, slot: 2, angle: 1000, power: 5000),
      TapCommand(tick: 2, side: 0, slot: 1),
      MoveCommand(tick: 2, side: 0, dir: -1),
      SurrenderCommand(tick: 3, side: 1),
    ];
    for (final c in cmds) {
      final text = jsonEncode(c.toJson());
      expect(jsonEncode(_parse(text).toJson()), text);
    }
  });

  test('형식이 틀린 커맨드는 FormatException 을 낸다', () {
    for (final bad in [
      '{"tick":1,"side":2,"type":"TAP","slot":0}',
      '{"tick":-1,"side":0,"type":"TAP","slot":0}',
      '{"tick":1,"side":0,"type":"JUMP"}',
      '{"tick":1,"side":0,"type":"MOVE"}',
      '{"tick":1,"side":0,"type":"FIRE","slot":0,"angle":1.5,"power":1}',
    ]) {
      expect(() => _parse(bad), throwsFormatException, reason: bad);
    }
  });

  test('커맨드는 tick → side → 종류(FIRE·TAP·MOVE·SURRENDER) → slot 순으로 정렬된다', () {
    final cmds = <Command>[
      const SurrenderCommand(tick: 1, side: 0),
      const MoveCommand(tick: 1, side: 0, dir: 1),
      const TapCommand(tick: 1, side: 0, slot: 0),
      const FireCommand(tick: 1, side: 1, slot: 0, angle: 0, power: 0),
      const FireCommand(tick: 1, side: 0, slot: 2, angle: 0, power: 0),
      const FireCommand(tick: 1, side: 0, slot: 1, angle: 0, power: 0),
      const TapCommand(tick: 0, side: 1, slot: 3),
    ]..sort(Command.compare);
    expect(
      [for (final c in cmds) jsonEncode(c.toJson())],
      [
        '{"tick":0,"side":1,"type":"TAP","slot":3}',
        '{"tick":1,"side":0,"type":"FIRE","slot":1,"angle":0,"power":0}',
        '{"tick":1,"side":0,"type":"FIRE","slot":2,"angle":0,"power":0}',
        '{"tick":1,"side":0,"type":"TAP","slot":0}',
        '{"tick":1,"side":0,"type":"MOVE","dir":1}',
        '{"tick":1,"side":0,"type":"SURRENDER"}',
        '{"tick":1,"side":1,"type":"FIRE","slot":0,"angle":0,"power":0}',
      ],
    );
  });
}
