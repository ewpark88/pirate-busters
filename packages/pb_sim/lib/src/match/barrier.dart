/// 산호 방벽 (설계서 §4.8 고유 효과, 코리, ADR-078). 월드 [x] 의 해수면부터 [top]
/// 높이까지 세로로 서서 상대 탄을 막는다. 내구도 [hp] 가 0 이 되거나 [turnsLeft]
/// (세운 쪽 턴 시작마다 1 감소)가 0 이 되면 사라진다. 모든 값이 해시에 들어간다.
class Barrier {
  Barrier({
    required this.owner,
    required this.x,
    required this.top,
    required this.hp,
    required this.turnsLeft,
  });

  /// 세운 진영. 이 진영의 탄은 막지 않는다.
  final int owner;

  /// 월드 x(1/1000칸).
  final int x;

  /// 꼭대기 월드 y(1/1000칸, 해수면 0).
  final int top;

  int hp;
  int turnsLeft;

  List<int> get hashValues => [owner, x, top, hp, turnsLeft];
}
