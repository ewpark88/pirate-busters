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

/// 매치 상태 전체를 정해진 순서로 직렬화한 해시 (설계서 §7.1 검증, §8.2 동기 확인).
///
/// 상태에 필드를 추가하면 여기에도 추가한다. 순서를 바꾸면 골든 해시가 바뀐다.
/// 렌더용 이벤트([MatchState.events])는 넣지 않는다.
int hashMatchState(MatchState state) {
  final h = Fnv1a32()
    ..addInt(state.tick)
    ..addInt(state.rng.state)
    ..addInt(state.outcome.index)
    ..addInt(state.winner)
    ..addInt(state.wind)
    ..addInt(state.nextProjectileId);
  for (final side in state.sides) {
    final grid = side.grid;
    final motion = side.motion;
    h
      ..addString(grid.hull.id)
      ..addInts(grid.rawMaterials)
      ..addInts(grid.rawHp)
      ..addInt(motion.offset)
      ..addInt(motion.velocity)
      ..addInt(motion.dir)
      ..addInt(motion.backLimit)
      ..addInt(motion.frontLimit)
      ..addInt(side.shotsFired);
    final crew = side.crew;
    for (var slot = 0; slot < crew.slotCount; slot++) {
      h.addInt(crew.pirateIndexAt(slot));
    }
    h.addInt(crew.pirates.length);
    for (final p in crew.pirates) {
      h
        ..addString(p.spec.id)
        ..addInt(p.hp)
        ..addInt(p.status.index)
        ..addInt(p.slot)
        ..addInt(p.reload)
        ..addInt(p.swim);
    }
  }
  h.addInt(state.projectiles.length);
  for (final p in state.projectiles) {
    h
      ..addInt(p.id)
      ..addInt(p.side)
      ..addInt(p.slot)
      ..addString(p.spec.id)
      ..addInt(p.x)
      ..addInt(p.y)
      ..addInt(p.vx)
      ..addInt(p.vy)
      ..addInt(p.age);
  }
  return h.value;
}
