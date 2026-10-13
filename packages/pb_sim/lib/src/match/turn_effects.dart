import 'package:pb_sim/src/pirate/pirate_spec.dart';

/// 턴 시작·끝에 터지도록 예약한 효과의 종류 (설계서 §4.8). 순서는 해시에 들어간다.
enum EffectKind {
  /// 설치탄: 붙은 칸에서 다음 내 턴 시작에 폭발한다.
  mineBlast,

  /// 강습탄: 다음 상대 턴 시작에 적 배 위에서 한 번 더 문다.
  biteAgain,

  /// 크라키 촉수: 대상 배의 턴이 끝날 때마다 붙은 칸 둘레 1칸 블록을 친다.
  /// 턴 시작에는 세지 않는다(trigger −1).
  tentacle,
}

/// 예약된 턴 효과. [trigger] 진영의 턴이 시작될 때마다 [turnsLeft] 가 1 줄고 0 이
/// 되면 터진다.
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

  /// 월드 x(렌더용).
  final int x;
}
