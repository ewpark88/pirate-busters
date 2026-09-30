import 'package:pb_sim/src/json_read.dart';

/// 턴 안의 행동 하나 (설계서 §7.2).
///
/// 사람·AI·네트워크 컨트롤러가 모두 이 커맨드만 낸다. 전투 엔진은 커맨드를 누가
/// 냈는지 모른다. [t] 는 턴 시작 기준 밀리초로, 턴 제한 시간 판정과 상대 화면
/// 재생에 쓴다.
sealed class Command {
  const Command({required this.t});

  /// JSON 한 개(§7.2 `cmds` 원소)에서 읽는다. 형식 오류는 [FormatException].
  factory Command.fromJson(Map<String, Object?> json) {
    final t = readInt(json, 't');
    if (t < 0) throw FormatException('t 는 0 이상: $t');
    return switch (readString(json, 'type')) {
      FireCommand.type => FireCommand(
        t: t,
        slot: readInt(json, 'slot'),
        angle: readInt(json, 'angle'),
        power: readInt(json, 'power'),
      ),
      TapCommand.type => TapCommand(
        t: t,
        slot: readInt(json, 'slot'),
        ticks: readInt(json, 'ticks'),
        dir: json.containsKey('dir') ? readInt(json, 'dir') : 0,
      ),
      MoveCommand.type => MoveCommand(t: t, dx: readInt(json, 'dx')),
      EndTurnCommand.type => EndTurnCommand(t: t),
      SurrenderCommand.type => SurrenderCommand(t: t),
      final other => throw FormatException('알 수 없는 커맨드: $other'),
    };
  }

  /// 턴 시작 기준 밀리초.
  final int t;

  Map<String, Object?> toJson();
}

/// 슬롯의 해적을 발사한다. [angle] 은 상대 쪽 수평이 0 인 밀리도, [power] 는 0~10000.
final class FireCommand extends Command {
  const FireCommand({
    required super.t,
    required this.slot,
    required this.angle,
    required this.power,
  });

  static const String type = 'FIRE';

  final int slot;
  final int angle;
  final int power;

  @override
  Map<String, Object?> toJson() => {
    't': t,
    'type': type,
    'slot': slot,
    'angle': angle,
    'power': power,
  };
}

/// 비행 중 2단 동작 (설계서 §7.2). 판정은 [t] 가 아니라 발사 뒤 지난 틱 [ticks] 로
/// 한다. MVP 에서는 분열탄만 쓴다. [dir] 은 방향 전환 탄종의 방향(R1, 지금은 무시).
final class TapCommand extends Command {
  const TapCommand({
    required super.t,
    required this.slot,
    required this.ticks,
    this.dir = 0,
  });

  static const String type = 'TAP';

  final int slot;
  final int ticks;
  final int dir;

  @override
  Map<String, Object?> toJson() => {
    't': t,
    'type': type,
    'slot': slot,
    'ticks': ticks,
    if (dir != 0) 'dir': dir,
  };
}

/// 배를 [dx](1/10칸, 전진 +, 후퇴 −)만큼 움직인다 (설계서 §2.6, §7.2). 한계선·연료·
/// 남은 턴 시간 검사는 시뮬레이션이 하고, 모자라면 갈 수 있는 데까지만 간다.
final class MoveCommand extends Command {
  const MoveCommand({required super.t, required this.dx});

  static const String type = 'MOVE';

  final int dx;

  @override
  Map<String, Object?> toJson() => {'t': t, 'type': type, 'dx': dx};
}

/// 턴 종료.
final class EndTurnCommand extends Command {
  const EndTurnCommand({required super.t});

  static const String type = 'END_TURN';

  @override
  Map<String, Object?> toJson() => {'t': t, 'type': type};
}

/// 항복.
final class SurrenderCommand extends Command {
  const SurrenderCommand({required super.t});

  static const String type = 'SURRENDER';

  @override
  Map<String, Object?> toJson() => {'t': t, 'type': type};
}

/// 한 턴의 커맨드 묶음 (설계서 §7.2). 네트워크로는 이 단위로 오간다.
class TurnBundle {
  /// [commands] 의 `t` 가 줄어들면 [ArgumentError].
  TurnBundle({
    required this.turn,
    required this.side,
    required List<Command> commands,
    this.hash,
  }) : commands = List.unmodifiable(commands) {
    if (turn < 1) throw ArgumentError('turn 은 1 이상: $turn');
    if (side != 0 && side != 1) throw ArgumentError('side 는 0 또는 1: $side');
    for (var i = 1; i < commands.length; i++) {
      if (commands[i].t < commands[i - 1].t) {
        throw ArgumentError(
          't 가 줄어든다: ${commands[i - 1].t} → ${commands[i].t}',
        );
      }
    }
  }

  /// 형식 오류는 [FormatException].
  factory TurnBundle.fromJson(Map<String, Object?> json) {
    final raw = json['hash'];
    if (raw != null && raw is! String) {
      throw FormatException('"hash" 는 문자열이어야 한다: $raw');
    }
    final turn = readInt(json, 'turn');
    final side = readInt(json, 'side');
    final commands = [
      for (final c in readList(json, 'cmds')) Command.fromJson(asMap(c, '커맨드')),
    ];
    if (turn < 1 || (side != 0 && side != 1)) {
      throw FormatException('turn·side 가 범위 밖: $turn, $side');
    }
    for (var i = 1; i < commands.length; i++) {
      if (commands[i].t < commands[i - 1].t) {
        throw const FormatException('cmds 의 t 가 줄어든다');
      }
    }
    return TurnBundle(
      turn: turn,
      side: side,
      commands: commands,
      hash: raw == null ? null : int.parse(raw as String, radix: 16),
    );
  }

  /// 1부터 세는 턴 번호(양쪽 합산).
  final int turn;
  final int side;
  final List<Command> commands;

  /// 턴이 끝난 뒤 상태 해시. 재생 결과와 비교한다. 아직 모르면 null.
  final int? hash;

  Map<String, Object?> toJson() => {
    'turn': turn,
    'side': side,
    'cmds': [for (final c in commands) c.toJson()],
    if (hash != null) 'hash': hash!.toRadixString(16).padLeft(8, '0'),
  };
}

/// 턴 묶음 해시가 재생 결과와 다르다(부정 또는 버그, 설계서 §7.2).
class TurnHashMismatch implements Exception {
  const TurnHashMismatch(this.turn, this.expected, this.actual);

  final int turn;
  final int expected;
  final int actual;

  @override
  String toString() => 'TurnHashMismatch(turn $turn: $expected != $actual)';
}
