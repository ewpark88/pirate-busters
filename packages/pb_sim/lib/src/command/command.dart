import 'package:pb_sim/src/json_read.dart';

/// 플레이어가 할 수 있는 모든 행동 (설계서 §7.2).
///
/// 사람·AI·네트워크 컨트롤러가 모두 이 커맨드만 낸다. 전투 엔진은 커맨드를
/// 누가 냈는지 모른다.
sealed class Command {
  const Command({required this.tick, required this.side});

  /// JSON 한 줄(§7.2 형식)에서 읽는다. 형식 오류는 [FormatException].
  factory Command.fromJson(Map<String, Object?> json) {
    final tick = readInt(json, 'tick');
    final side = readInt(json, 'side');
    if (tick < 0) throw FormatException('tick 은 0 이상: $tick');
    if (side != 0 && side != 1) throw FormatException('side 는 0 또는 1: $side');
    return switch (readString(json, 'type')) {
      FireCommand.type => FireCommand(
        tick: tick,
        side: side,
        slot: readInt(json, 'slot'),
        angle: readInt(json, 'angle'),
        power: readInt(json, 'power'),
      ),
      TapCommand.type => TapCommand(
        tick: tick,
        side: side,
        slot: readInt(json, 'slot'),
      ),
      SurrenderCommand.type => SurrenderCommand(tick: tick, side: side),
      final other => throw FormatException('알 수 없는 커맨드: $other'),
    };
  }

  /// 실행할 틱 번호.
  final int tick;

  /// 0 = 왼쪽(내 배), 1 = 오른쪽.
  final int side;

  /// 같은 틱 안의 적용 순서(FIRE → TAP → SURRENDER).
  int get kindOrder;

  /// 같은 틱·같은 종류 안의 정렬용 슬롯. 슬롯이 없으면 0.
  int get sortSlot;

  Map<String, Object?> toJson();

  /// 적용 순서: tick → side → 종류 → slot. 같은 입력이면 항상 같은 순서가 된다.
  static int compare(Command a, Command b) {
    if (a.tick != b.tick) return a.tick - b.tick;
    if (a.side != b.side) return a.side - b.side;
    if (a.kindOrder != b.kindOrder) return a.kindOrder - b.kindOrder;
    return a.sortSlot - b.sortSlot;
  }
}

/// 슬롯의 해적을 발사한다. [angle] 은 밀리도, [power] 는 ×1000 정수.
final class FireCommand extends Command {
  const FireCommand({
    required super.tick,
    required super.side,
    required this.slot,
    required this.angle,
    required this.power,
  });

  static const String type = 'FIRE';

  final int slot;
  final int angle;
  final int power;

  @override
  int get kindOrder => 0;

  @override
  int get sortSlot => slot;

  @override
  Map<String, Object?> toJson() => {
    'tick': tick,
    'side': side,
    'type': type,
    'slot': slot,
    'angle': angle,
    'power': power,
  };
}

/// 비행 중 2단 동작 (분열, 급강하 등).
final class TapCommand extends Command {
  const TapCommand({
    required super.tick,
    required super.side,
    required this.slot,
  });

  static const String type = 'TAP';

  final int slot;

  @override
  int get kindOrder => 1;

  @override
  int get sortSlot => slot;

  @override
  Map<String, Object?> toJson() => {
    'tick': tick,
    'side': side,
    'type': type,
    'slot': slot,
  };
}

/// 항복.
final class SurrenderCommand extends Command {
  const SurrenderCommand({required super.tick, required super.side});

  static const String type = 'SURRENDER';

  @override
  int get kindOrder => 2;

  @override
  int get sortSlot => 0;

  @override
  Map<String, Object?> toJson() => {'tick': tick, 'side': side, 'type': type};
}
