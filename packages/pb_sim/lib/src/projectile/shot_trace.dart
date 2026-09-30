/// 탄 하나가 지나간 틱별 월드 위치 (렌더 전용, 판정·해시와 무관).
///
/// 시뮬레이션이 실제로 계산한 경로라 분열 조각·튕김·유도까지 앱이 그대로 그린다.
class ShotTrace {
  ShotTrace({required this.id, required this.startTick});

  /// 투사체 id.
  final int id;

  /// 발사(또는 효과) 기준 이 탄이 생긴 틱.
  final int startTick;

  /// [startTick] 부터 한 틱마다의 위치(1/1000칸).
  final List<int> xs = [];
  final List<int> ys = [];

  /// 마지막 틱 (발사 기준).
  int get endTick => startTick + xs.length - 1;

  void add(int x, int y) {
    xs.add(x);
    ys.add(y);
  }
}
