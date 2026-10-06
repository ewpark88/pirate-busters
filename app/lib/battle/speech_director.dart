import 'package:pb_sim/pb_sim.dart';

/// 말풍선 종류 (설계서 §15.4 전투 중 말풍선).
enum BarkKind {
  /// 내 해적이 쐈다.
  fire,

  /// 내 해적이 맞았다(아직 쓰러지지 않음).
  hurt,

  /// 내 동료가 쓰러졌다(살아 있는 다른 해적이 말한다).
  allyDown,

  /// 상대 선장: 판 시작 도발.
  tauntStart,

  /// 상대 선장: 선체가 낮아졌을 때.
  tauntLow,
}

/// 말풍선 하나. `slot` 이 -1 이면 상대 선장이다. `line` 은 그 종류의 몇 번째 줄.
typedef Bark = ({BarkKind kind, int slot, int line, int turn});

/// 전투 중 말풍선을 고른다 (설계서 §15.4). 렌더 전용: 상태를 읽기만 하고 판정을
/// 바꾸지 않는다. 같은 판 흐름이면 같은 말풍선이 나온다(난수 대신 턴·슬롯으로 고름).
/// 한 턴에 최대 하나: 쓰러짐 > 맞음 > 상대 선체 낮음 > 판 시작 도발 > 발사(3턴에 한 번).
class SpeechDirector {
  SpeechDirector({required this.me, this.captain = false});

  /// 내 진영.
  final int me;

  /// 상대 선장이 말하는 판인가(캠페인). 둘이서·테스트 대전은 해적 말만.
  final bool captain;

  /// 종류마다 줄 수 (ARB `bark_<종류>_1..n`).
  static const int lines = 4;

  /// 상대 선체가 이 비율(%) 아래로 내려가면 한 번 말한다.
  static const int lowHullPercent = 60;

  List<(int hp, PirateStatus status, int cooldown)>? _last;
  int _spokenTurn = -1;
  bool _startDone = false;
  bool _lowDone = false;

  /// [state] 를 지난번과 견줘 이번에 띄울 말풍선을 돌려준다. 없으면 null.
  Bark? observe(MatchState state) {
    final crew = state.sides[me].crew.pirates;
    final now = [for (final p in crew) (p.hp, p.status, p.cooldown)];
    final last = _last;
    _last = now;
    if (last == null || last.length != now.length) return null;
    if (_spokenTurn == state.turn) return null;
    Bark? pick(BarkKind kind, int slot) => (
      kind: kind,
      slot: slot,
      line: _line(state.turn, slot, kind),
      turn: state.turn,
    );

    Bark? bark;
    for (var s = 0; s < now.length && bark == null; s++) {
      if (now[s].$2 == PirateStatus.down && last[s].$2 != PirateStatus.down) {
        final speaker = _firstUp(now, except: s);
        if (speaker >= 0) bark = pick(BarkKind.allyDown, speaker);
      }
    }
    for (var s = 0; s < now.length && bark == null; s++) {
      if (now[s].$1 < last[s].$1 && now[s].$2 == PirateStatus.aboard) {
        bark = pick(BarkKind.hurt, s);
      }
    }
    if (bark == null && captain) {
      final enemy = state.sides[1 - me].grid;
      final low = enemy.totalHp * 100 < enemy.initialTotalHp * lowHullPercent;
      if (low && !_lowDone) {
        _lowDone = true;
        bark = pick(BarkKind.tauntLow, -1);
      } else if (!_startDone && state.activeSide != me) {
        _startDone = true;
        bark = pick(BarkKind.tauntStart, -1);
      }
    }
    for (var s = 0; s < now.length && bark == null; s++) {
      if (now[s].$3 > last[s].$3 && state.turn % 3 == 1) {
        bark = pick(BarkKind.fire, s);
      }
    }
    if (bark != null) _spokenTurn = state.turn;
    return bark;
  }

  static int _firstUp(
    List<(int, PirateStatus, int)> crew, {
    required int except,
  }) {
    for (var s = 0; s < crew.length; s++) {
      if (s != except && crew[s].$2 == PirateStatus.aboard) return s;
    }
    return -1;
  }

  /// 줄 고르기: 턴·슬롯·종류로 정한다(같은 판이면 같은 줄).
  static int _line(int turn, int slot, BarkKind kind) =>
      ((turn * 7 + (slot + 1) * 3 + kind.index * 5) % lines) + 1;
}
