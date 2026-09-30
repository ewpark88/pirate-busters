import 'package:pb_sim/pb_sim.dart';

/// 덱이 선호하는 거리 (설계서 §2.6: 강습·직사 덱은 다가가고, 투척·물수제비 덱은 벌린다).
enum PreferredRange { near, far, mixed }

/// 선원 편성 화면의 덱 평가 (설계서 §13.7): 계열 분포, 사거리 분포, 선호 거리, 코스트.
class DeckEval {
  DeckEval(List<PirateSpec> deck)
    : cost = deck.fold(0, (s, p) => s + p.cost),
      families = {
        for (final f in Family.values)
          if (deck.any((p) => p.family == f))
            f: deck.where((p) => p.family == f).length,
      },
      ranges = {
        for (final r in RangeGrade.values)
          if (deck.any((p) => p.range == r))
            r: deck.where((p) => p.range == r).length,
      },
      preferred = _preferred(deck);

  /// 코스트 합계 (설계서 §4.5).
  final int cost;

  /// 계열별 인원 (계열 순서).
  final Map<Family, int> families;

  /// 사거리 등급별 인원 (짧음 → 매우 긺).
  final Map<RangeGrade, int> ranges;

  final PreferredRange preferred;

  static PreferredRange _preferred(List<PirateSpec> deck) {
    var near = 0;
    var far = 0;
    for (final p in deck) {
      switch (p.family) {
        case Family.direct || Family.assault:
          near++;
        case Family.lob || Family.skip:
          far++;
        case _:
          break;
      }
    }
    if (near > far) return PreferredRange.near;
    if (far > near) return PreferredRange.far;
    return PreferredRange.mixed;
  }
}
