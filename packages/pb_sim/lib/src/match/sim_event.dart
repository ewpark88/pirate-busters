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

  /// 배 이동. [SimEvent.value] = 움직인 거리(1/1000칸, 전진 +), [SimEvent.x] = 새
  /// 뱃머리 x, [SimEvent.y] = 걸린 시간(밀리초).
  move,

  /// 턴 끝 침수. [SimEvent.value] = 늘어난 침수량(0.1%p).
  flood,

  /// 폭풍 타임 시작. [SimEvent.value] = 턴 번호.
  stormStart,

  /// 수면에서 튕김(물수제비). (x, 0), [SimEvent.value] = 발사 후 틱.
  bounce,

  /// 탄이 갈라짐(분열·다중투하). [SimEvent.value] = 조각 수, (x, y) = 갈라진 곳.
  divide,

  /// 설치탄이 배에 붙음. [SimEvent.cell] = 붙은 칸, [SimEvent.side] = 붙은 배.
  mineAttached,

  /// 수리됨. [SimEvent.cell] = 칸, [SimEvent.side] = 고친 배.
  repaired,

  /// 예약된 턴 효과가 터짐(설치탄 폭발·투하·다시 물기). [SimEvent.value] = 효과 종류.
  effectFired,

  /// 모듈이 붙은 블록이 부서졌다 (설계서 §3.3). value = 모듈 종류 index.
  moduleDestroyed,

  /// 블록에 불이 붙었다 (설계서 §2.5). [SimEvent.cell] = 칸.
  ignited,

  /// 불붙은 블록이 턴 끝에 탔다. [SimEvent.cell] = 칸.
  burned,

  /// 연쇄탄이 해적에게 번졌다 (설계서 §4.8). [SimEvent.slot] = 번진 해적.
  chained,

  /// 지속 상태가 걸렸다 (§4.8 고유 효과). [SimEvent.side] = 걸린 진영,
  /// [SimEvent.value] = 고유 능력 index, [SimEvent.slot] = 봉쇄 선실(없으면 −1),
  /// [SimEvent.x] = 끌려간 거리(1/1000칸).
  statusApplied,

  /// 떠 있는 기뢰가 놓였다(젤리). [SimEvent.x] = 월드 x, [SimEvent.side] = 노리는 배.
  mineFloated,

  /// 비행 중 방향을 바꿨다(알바). (x, y) = 위치, [SimEvent.value] = 틱.
  steered,

  /// 지원 효과(배수·쿨다운·연료)가 났다. [SimEvent.value] = 고유 능력 index.
  supported,

  /// 펠리 투하 표시가 상대 탄에 요격됐다. [SimEvent.x] = 표시 x.
  intercepted,

  /// 산호 방벽이 섰다(코리). [SimEvent.x] = 월드 x, [SimEvent.value] = 내구도.
  barrierPlaced,

  /// 산호 방벽이 탄을 막았다. [SimEvent.x] = 월드 x, [SimEvent.value] = 남은 내구도.
  barrierHit,

  /// 해적이 되살아났다(데비). [SimEvent.slot].
  revived,

  /// 해적이 치유됐다(쿡). [SimEvent.slot], [SimEvent.value] = 회복량.
  healed,
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
