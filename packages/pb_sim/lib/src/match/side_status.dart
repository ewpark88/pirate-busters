/// 한 진영에 걸린 지속 상태 (설계서 §4.8 전설 고유 능력).
///
/// 값마다 효과가 걸리는 턴 번호를 둔다(0 = 없음). ‘다음 상대 턴’ 효과는 건 턴 + 1
/// 이고, 그 턴이 끝나면 저절로 풀린다(번호가 지난다). 모든 값이 해시에 들어간다.
class SideStatus {
  /// 이 턴에는 궤적 점선이 봉쇄된다(만타, 0%). 판정과 무관하다.
  int trailBlockTurn = 0;

  /// 이번 자기 턴에 움직인 거리 합(1/1000칸, 앞뒤 모두 더함). 배에 선 상대 강습
  /// 해적을 흔드는 데 쓴다 (설계서 §2.3, ADR-110). 턴 시작에 0 이 된다. 상대 강습
  /// 해적이 서 있을 때만 해시에 들어간다([hashValues] 밖).
  int shakeMoved = 0;

  /// 해시용 값 목록(순서 고정).
  List<int> get hashValues => [trailBlockTurn];

  /// [turn] 의 궤적 표시 비율(%): 봉쇄 0, 없으면 −1.
  int trailPercentAt(int turn) => trailBlockTurn == turn ? 0 : -1;
}
