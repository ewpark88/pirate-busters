import 'package:pb_sim/pb_sim.dart';

/// 한 방 크기의 단계 (설계서 §10.4).
enum HitLevel { light, medium, heavy }

/// 한 방 크기 (설계서 §10.4, A32): 한 착탄 묶음의 피해 합·부순 칸·해적 피해·치명·유폭
/// 으로 0~1000 점을 매긴다. 멈춤·흔들림·줌·숫자·진동이 모두 이 점수에 비례하고 상한이
/// 있다. 화면용이라 판정과 무관하고, 같은 이벤트면 같은 점수다.
class HitWeight {
  const HitWeight(this.score);

  /// [batch] 한 묶음의 한 방 크기. 배에 맞은 착탄이 없으면 [none].
  /// [critHit] 는 쏜 해적이 치명 계열(저격)인가.
  factory HitWeight.of(Iterable<SimEvent> batch, {bool critHit = false}) {
    var hit = false;
    var s = base;
    var pirate = 0;
    for (final e in batch) {
      switch (e.kind) {
        case SimEventKind.impact:
          hit = true;
        case SimEventKind.blockDestroyed:
          s += perDestroyed;
        case SimEventKind.blockCollapsed:
          s += perCollapsed;
        case SimEventKind.pirateHit:
          pirate += e.value;
        case SimEventKind.pirateFell:
          s += perFell;
        case SimEventKind.pirateDown:
          s += perDown;
        // 화약고·연료통 유폭만 크다(다른 모듈은 블록 파괴로 이미 셌다).
        case SimEventKind.moduleDestroyed
            when ModuleKind.values[e.value] == ModuleKind.magazine ||
                ModuleKind.values[e.value] == ModuleKind.fuelTank:
          hit = true;
          s += perBlast;
        case _:
          break;
      }
    }
    if (!hit) return none;
    s += pirate * perPirateDamage;
    if (critHit && pirate > 0) s += crit;
    return HitWeight(s > max ? max : s);
  }

  /// 착탄이 없는 묶음.
  static const HitWeight none = HitWeight(0);

  /// 0~1000.
  final int score;

  // 점수표. 기준 한 발(블록 총피해 ≈ 120, 해적 직격 ≈ 80, BALANCE.md 계열 기준)이 중간
  // 아래에 오고, 여러 칸을 부수거나 해적을 맞히면 묵직으로 올라간다.
  static const int base = 150;
  static const int perDestroyed = 140;
  static const int perCollapsed = 40;
  static const int perPirateDamage = 3;
  static const int perFell = 150;
  static const int perDown = 300;
  static const int perBlast = 400;
  static const int crit = 150;
  static const int max = 1000;

  /// 이보다 작으면 가벼움, [heavyFrom] 부터 묵직.
  static const int mediumFrom = 350;
  static const int heavyFrom = 650;

  HitLevel get level => score >= heavyFrom
      ? HitLevel.heavy
      : score >= mediumFrom
      ? HitLevel.medium
      : HitLevel.light;

  bool get isHeavy => level == HitLevel.heavy;

  /// 0~1.
  double get unit => score / max;

  /// 히트스톱 길이(초): 0.05~0.16.
  double get hitStopSec => 0.05 + 0.11 * unit;

  /// 흔들림에 더할 충격량(0~1, `ScreenTrauma`).
  double get trauma => 0.35 + 0.55 * unit;

  /// 당기는 줌 세기(화면 폭을 좁히는 비율): 4~12%.
  double get punch => 0.04 + 0.08 * unit;
}
