/// 렌더용 이벤트 종류 (개발 계획서 M2). 시뮬레이션 결과에는 영향이 없다.
enum SimEventKind {
  /// 턴 시작. [SimEvent.side] = 턴을 두는 진영, [SimEvent.value] = 턴 번호.
  turnStart,

  /// 발사. [SimEvent.slot], [SimEvent.value] = 투사체 id, (x, y) = 발사 위치.
  fire,

  /// 배에 착탄. (x, y) = 착탄 위치, [SimEvent.cell] = 착탄 칸, [SimEvent.side] = 맞은 배,
  /// [SimEvent.value] = 발사 후 틱.
  impact,

  /// 바다에 떨어짐. (x, y) = 물보라 위치, [SimEvent.value] = 발사 후 틱.
  splash,

  /// 블록 파괴. [SimEvent.cell] = 칸 인덱스.
  blockDestroyed,

  /// 지지가 끊겨 무너진 블록 한 칸. [SimEvent.cell] = 칸 인덱스.
  blockCollapsed,

  /// 해적 피격. [SimEvent.value] = 피해량.
  pirateHit,

  /// 해적이 바다로 떨어짐.
  pirateFell,

  /// 바다에 빠졌던 해적이 내 턴 시작에 배로 돌아옴.
  pirateReturned,

  /// 해적 쓰러짐(KO).
  pirateDown,

  /// 턴 끝. [SimEvent.value] = 턴 번호, [SimEvent.cell] = 끝난 이유([TurnEndReason] 순서).
  turnEnd,
}

/// 턴이 끝난 이유. 순서는 이벤트 값으로 쓰인다.
enum TurnEndReason {
  /// `END_TURN`.
  endTurn,

  /// 발사 횟수를 다 써서 마지막 탄이 떨어진 뒤 자동 종료.
  firesUsed,

  /// 턴 제한 시간이 지났다(남은 행동은 버린다).
  timeout,

  /// 판이 끝났다.
  matchOver,
}

/// 한 턴 동안 일어난 일. 턴이 시작될 때 새로 채운다.
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
