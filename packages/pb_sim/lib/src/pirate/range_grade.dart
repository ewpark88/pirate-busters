/// 해적 최대 사거리 등급 (설계서 §2.8). 순서는 바꾸지 않는다.
///
/// 사거리는 최대 힘·45° 로 쐈을 때 발사 높이에서 해수면까지의 가로 거리(바람 없음)다.
/// 최대 탄속 = √(사거리 × 중력 16칸/초²) 을 미리 계산한 정수 표로 둔다 (§7.1,
/// BALANCE.md A2.8, ADR-043).
enum RangeGrade {
  short(26, 20396),
  medium(36, 24000),
  long(50, 28284),
  veryLong(66, 32496);

  const RangeGrade(this.cells, this.launchSpeed);

  /// 사거리(칸).
  final int cells;

  /// 힘 10000 일 때 탄 속도(1/1000칸/초).
  final int launchSpeed;

  /// 적 선체에 닿는 뱃머리 간격의 대략 상한(1/1000칸): 사거리 − 8칸 (BALANCE.md A2.8
  /// ‘적 선체에 닿는 간격’). 카드의 ‘사거리 밖’ 표시에 쓴다. 발사는 막지 않는다.
  int get hitGap => (cells - 8) * 1000;

  /// 데이터 이름(`short`·`medium`·`long`·`veryLong`)으로 찾는다. 없으면 [FormatException].
  static RangeGrade byName(String name) {
    for (final r in values) {
      if (r.name == name) return r;
    }
    throw FormatException('알 수 없는 사거리 등급: $name');
  }
}
