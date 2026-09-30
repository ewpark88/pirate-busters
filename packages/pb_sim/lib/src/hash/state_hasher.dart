import 'package:pb_sim/src/match/match_state.dart';

/// FNV-1a 32비트 해시 누적기. int 는 64비트 리틀 엔디언 8바이트로 먹인다.
class Fnv1a32 {
  static const int _offsetBasis = 0x811C9DC5;
  static const int _prime = 0x01000193;
  static const int _mask32 = 0xFFFFFFFF;

  int _hash = _offsetBasis;

  /// 현재 해시값 (0 ~ 2^32-1).
  int get value => _hash;

  void addByte(int b) {
    _hash = ((_hash ^ (b & 0xFF)) * _prime) & _mask32;
  }

  void addInt(int v) {
    for (var i = 0; i < 8; i++) {
      addByte(v >> (i * 8));
    }
  }

  /// 길이를 먼저 넣고 UTF-16 코드 유닛을 넣는다.
  void addString(String s) {
    addInt(s.length);
    for (final u in s.codeUnits) {
      addByte(u);
      addByte(u >> 8);
    }
  }

  /// 길이를 먼저 넣고 원소를 순서대로 넣는다.
  void addInts(List<int> values) {
    addInt(values.length);
    values.forEach(addInt);
  }
}

/// 매치 상태 전체를 정해진 순서로 직렬화한 해시 (설계서 §7.1 검증, §7.2 턴 해시).
///
/// 상태에 필드를 추가하면 여기에도 추가한다. 순서를 바꾸면 골든 해시가 바뀐다.
/// 렌더용 이벤트([MatchState.events])는 넣지 않는다. 탭을 기다리는 분열탄
/// (`Match.pendingSlot`)은 상태 밖에 있고 턴 끝 해시 전에 반드시 계산된다
/// (설계서 §7.2). 턴 도중에 부르면 대기 탄은 빠진다.
int hashMatchState(MatchState state) {
  final h = Fnv1a32()
    ..addInt(state.seed)
    ..addInt(state.rng.state)
    ..addInt(state.firstSide)
    ..addInt(state.turn)
    ..addInt(state.wind)
    ..addInt(state.firesThisTurn)
    ..addInt(state.pausedMs)
    ..addInt(state.busyUntilMs)
    ..addInt(state.nextProjectileId)
    ..addInt(state.outcome.index)
    ..addInt(state.winner);
  for (final side in state.sides) {
    final grid = side.grid;
    h
      ..addString(grid.hull.id)
      ..addInts(grid.rawMaterials)
      ..addInts(grid.rawHp)
      ..addInt(side.bowX)
      ..addInt(side.fuel)
      ..addInt(side.flood)
      ..addInt(side.shotsFired)
      ..addInt(side.crew.size);
    for (final p in side.crew.pirates) {
      h
        ..addString(p.spec.id)
        ..addInt(p.hp)
        ..addInt(p.status.index)
        ..addInt(p.cooldown);
    }
    for (final fired in side.crew.firedThisTurn) {
      h.addInt(fired ? 1 : 0);
    }
    h.addInt(side.modules.list.length);
    for (final m in side.modules.list) {
      h
        ..addInt(m.kind.index)
        ..addInt(m.x)
        ..addInt(m.y)
        ..addInt(m.intact ? 1 : 0);
    }
  }
  h.addInt(state.effects.length);
  for (final e in state.effects) {
    h
      ..addInt(e.kind.index)
      ..addInt(e.owner)
      ..addInt(e.ownerSlot)
      ..addInt(e.target)
      ..addInt(e.trigger)
      ..addInt(e.turnsLeft)
      ..addString(e.spec.id)
      ..addInt(e.cell)
      ..addInt(e.x);
  }
  return h.value;
}
