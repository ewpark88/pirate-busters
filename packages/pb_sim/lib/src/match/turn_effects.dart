import 'package:pb_sim/src/pirate/pirate_spec.dart';

/// 턴 시작에 터지도록 예약한 효과의 종류 (설계서 §4.3 턴 효과). 순서는 해시에 들어간다.
enum EffectKind {
  /// 설치탄: 붙은 칸에서 폭발하고 침수를 더한다(퍼피).
  mineBlast,

  /// 다중투하: 표시한 곳 위에서 소형 폭탄을 떨군다(펠리).
  flockDrop,

  /// 강습탄: 착지한 곳의 해적을 한 번 더 문다(샤키).
  biteAgain,

  /// 떠 있는 기뢰(젤리): 대상 배가 이동하다 [TurnEffect.x] 를 지나가면 터진다.
  /// 지속 턴이 끝나면 터지지 않고 사라진다 (설계서 §4.8, ADR-075).
  floatMine,
}

/// 예약된 턴 효과. [trigger] 진영의 턴이 시작될 때마다 [turnsLeft] 가 1 줄고 0 이
/// 되면 터진다 (설계서 §4.3 “다음 내 턴 시작에”, “다음 상대 턴 시작에”).
class TurnEffect {
  TurnEffect({
    required this.kind,
    required this.owner,
    required this.ownerSlot,
    required this.target,
    required this.trigger,
    required this.turnsLeft,
    required this.spec,
    this.cell = -1,
    this.x = 0,
  });

  final EffectKind kind;

  /// 효과를 건 진영과 해적 슬롯.
  final int owner;
  final int ownerSlot;

  /// 효과를 받는 배의 진영.
  final int target;

  /// 이 진영의 턴이 시작될 때 센다.
  final int trigger;

  int turnsLeft;

  /// 효과를 건 해적의 정의(피해·등급 수치).
  final PirateSpec spec;

  /// 대상 배 로컬 칸 인덱스(설치탄·물기). 없으면 −1.
  final int cell;

  /// 월드 x (투하 위치).
  final int x;
}
