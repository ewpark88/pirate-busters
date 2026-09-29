/// 렌더용 이벤트 종류 (개발 계획서 M2). 시뮬레이션 결과에는 영향이 없다.
enum SimEventKind {
  /// 발사. [SimEvent.slot], [SimEvent.value] = 투사체 id, (x, y) = 발사 위치.
  fire,

  /// 배에 착탄. (x, y) = 착탄 위치, [SimEvent.cell] = 착탄 칸, [SimEvent.side] = 맞은 배.
  impact,

  /// 바다에 떨어짐. (x, y) = 물보라 위치.
  splash,

  /// 블록 파괴. [SimEvent.cell] = 칸 인덱스.
  blockDestroyed,

  /// 지지가 끊겨 무너진 블록 한 칸. [SimEvent.cell] = 칸 인덱스.
  blockCollapsed,

  /// 해적 피격. [SimEvent.value] = 피해량.
  pirateHit,

  /// 해적이 바다로 떨어짐.
  pirateFell,

  /// 헤엄쳐 배로 돌아옴.
  pirateReturned,

  /// 해적 쓰러짐.
  pirateDown,

  /// 교대 대기열의 해적이 선실에 들어감. [SimEvent.value] = 덱 번호.
  pirateBoarded,

  /// 이동하다 한계선에 닿아 멈춤.
  moveLimit,
}

/// 한 틱 동안 일어난 일. `Match.step` 이 틱마다 새로 채운다.
class SimEvent {
  const SimEvent(
    this.kind, {
    required this.side,
    this.slot = -1,
    this.cell = -1,
    this.x = 0,
    this.y = 0,
    this.value = 0,
  });

  final SimEventKind kind;

  /// 이벤트가 일어난 진영(맞은 배, 해적의 진영).
  final int side;
  final int slot;
  final int cell;
  final int x;
  final int y;
  final int value;

  @override
  String toString() =>
      'SimEvent(${kind.name}, side $side, slot $slot, cell $cell, '
      '($x, $y), $value)';
}
