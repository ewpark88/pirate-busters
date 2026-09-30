// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Pirate Busters';

  @override
  String turnsLeft(int count) {
    return '남은 턴 $count';
  }

  @override
  String get yourTurn => '내 턴';

  @override
  String get enemyTurn => '상대 턴';

  @override
  String playerTurn(int side) {
    return '플레이어 $side 턴';
  }

  @override
  String get hull => '선체';

  @override
  String flood(String percent) {
    return '침수 $percent%';
  }

  @override
  String crewAlive(int alive, int total) {
    return '선원 $alive/$total';
  }

  @override
  String get endTurn => '턴 종료';

  @override
  String get retreat => '후퇴';

  @override
  String get advance => '전진';

  @override
  String get fuel => '연료';

  @override
  String firesLeft(int count) {
    return '남은 발사 $count';
  }

  @override
  String cooldown(int count) {
    return '쉬는 턴 $count';
  }

  @override
  String get cabinFlooded => '잠김';

  @override
  String get pirateDown => '쓰러짐';

  @override
  String get pirateSwimming => '헤엄 중';

  @override
  String get wind => '바람';

  @override
  String get stormTime => '폭풍 타임!';

  @override
  String get overview => '전체 보기';

  @override
  String gapCells(int cells) {
    return '간격 $cells칸';
  }

  @override
  String get pause => '일시정지';

  @override
  String get resume => '계속하기';

  @override
  String get surrender => '항복';

  @override
  String get surrenderConfirm => '이번 해전을 포기할까요?';

  @override
  String get cancel => '취소';

  @override
  String get settings => '설정';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get opponent => '상대';

  @override
  String get opponentDummy => '허수아비';

  @override
  String get opponentHotseat => '두 사람 (한 기기)';

  @override
  String get resultWin => '승리!';

  @override
  String get resultLose => '패배';

  @override
  String get resultDraw => '무승부';

  @override
  String get outcomeSunk => '격침';

  @override
  String get outcomeFloodSunk => '침몰';

  @override
  String get outcomeAnnihilation => '전멸';

  @override
  String get outcomeTimeDecision => '시간 판정';

  @override
  String get outcomeSurrender => '항복';

  @override
  String get playAgain => '다시 하기';

  @override
  String playerWins(int side) {
    return '플레이어 $side 승리!';
  }

  @override
  String get lowEndMode => '저사양 모드';

  @override
  String damagePopup(String amount) {
    return '-$amount';
  }

  @override
  String get sunkBanner => '격침!';

  @override
  String get surrenderQueued => '내 턴이 오면 항복합니다';

  @override
  String get pirate_p01_name => '문어 폭탄병 옥토';

  @override
  String get pirate_p01_desc => '포물선 폭탄, 착탄 반경 1칸';

  @override
  String get pirate_p01_lore => '산호 항구에서 자란 문어. 여덟 팔로 폭탄을 한꺼번에 굴린다.';

  @override
  String get pirate_p04_name => '성게 폭탄 우니';

  @override
  String get pirate_p04_desc => '비행 중 탭 → 가시 4갈래 분열';

  @override
  String get pirate_p04_lore => '가시만큼 성미도 뾰족하다. 터질 때를 스스로 고른다.';

  @override
  String get pirate_p06_name => '딱총새우 팡';

  @override
  String get pirate_p06_desc => '집게로 쏜 물방울 총알, 해적 명중 시 치명';

  @override
  String get pirate_p06_lore => '집게를 딱 튕기면 물방울 총알이 날아간다.';

  @override
  String get pirate_p07_name => '해마 쌍권총 히포';

  @override
  String get pirate_p07_desc => '짧은 사거리 3연사';

  @override
  String get pirate_p07_lore => '꼬리로 몸을 지탱하고 쌍권총을 쏜다.';

  @override
  String get pirate_p11_name => '황새치 작살꾼 핀';

  @override
  String get pirate_p11_desc => '코 작살로 돌진, 블록 2칸 관통';

  @override
  String get pirate_p11_lore => '긴 코가 곧 작살이다. 벽 뒤에 숨어도 소용없다.';

  @override
  String get pirate_p16_name => '해달 돌팔매 수리';

  @override
  String get pirate_p16_desc => '돌이 수면 2회 튕겨 흘수선 명중';

  @override
  String get pirate_p16_lore => '배 위에서 조개를 깨던 솜씨로 돌을 튕긴다.';

  @override
  String get pirate_p21_name => '복어 자폭병 퍼피';

  @override
  String get pirate_p21_desc => '흘수선 아래에 붙어 다음 내 턴 시작에 폭발';

  @override
  String get pirate_p21_lore => '잔뜩 부풀어 배 밑에 달라붙는다. 그다음은 펑.';

  @override
  String get pirate_p26_name => '앵무새 폴리';

  @override
  String get pirate_p26_desc => '가장 가까운 해적을 자동으로 쫓아 쪼기';

  @override
  String get pirate_p26_lore => '선장의 어깨를 떠나 적 선원을 쫓는다.';

  @override
  String get pirate_p27_name => '갈매기 폭격수 윙';

  @override
  String get pirate_p27_desc => '급강하하며 소형 폭탄 3개';

  @override
  String get pirate_p27_lore => '바다 위를 맴돌다 한순간에 내리꽂힌다.';

  @override
  String get pirate_p28_name => '펠리컨 수송대 펠리';

  @override
  String get pirate_p28_desc => '다음 내 턴 시작에 부리 주머니에서 소형 폭탄 4개';

  @override
  String get pirate_p28_lore => '부리 주머니에 무엇이 들었는지는 아무도 모른다.';

  @override
  String get pirate_p31_name => '상어 난동꾼 샤키';

  @override
  String get pirate_p31_desc => '적 갑판에 뛰어들어 반경 1칸 해적을 물어뜯음';

  @override
  String get pirate_p31_lore => '적 배에 뛰어드는 것을 무엇보다 좋아한다.';

  @override
  String get pirate_p36_name => '거북 목수 톡';

  @override
  String get pirate_p36_desc => '아군 배에 쏘면 구멍 난 블록 3칸 수리';

  @override
  String get pirate_p36_lore => '느리지만 꼼꼼하다. 배는 그가 지킨다.';
}
