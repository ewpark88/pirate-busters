import 'package:pb_sim/pb_sim.dart';

/// 선원 편성 화면의 덱 평가 (설계서 §13.7): 계열 분포와 코스트. 사거리 등급과
/// 거리 상성은 없다 (설계서 §4.1, ADR-111).
class DeckEval {
  DeckEval(List<PirateSpec> deck)
    : cost = deck.fold(0, (s, p) => s + p.cost),
      families = {
        for (final f in Family.values)
          if (deck.any((p) => p.family == f))
            f: deck.where((p) => p.family == f).length,
      };

  /// 코스트 합계 (설계서 §4.5).
  final int cost;

  /// 계열별 인원 (계열 순서).
  final Map<Family, int> families;
}
