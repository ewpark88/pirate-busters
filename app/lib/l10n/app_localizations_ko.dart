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

  @override
  String get blueprint_balanced_name => '밸런스';

  @override
  String get blueprint_balanced_desc =>
      '참나무 용골에 펌프와 목수 공방을 단 기본형. 포문과 망루로 한 명을 키운다.';

  @override
  String get blueprint_armored_name => '철갑';

  @override
  String get blueprint_armored_desc =>
      '선실 양옆을 철판으로 막은 튼튼한 배. 무거워서 깊이 잠기니 펌프로 버틴다.';

  @override
  String get blueprint_fast_name => '고속';

  @override
  String get blueprint_fast_desc =>
      '소나무와 코르크로 가볍게 띄우고 연료통 둘로 멀리 움직인다. 대신 잘 부서진다.';

  @override
  String ammoExplosive(int n) {
    return '폭발 $n%';
  }

  @override
  String ammoFire(int n) {
    return '화염 $n턴';
  }

  @override
  String ammoSplit(int n) {
    return '분열 ×$n';
  }

  @override
  String ammoBurst(int n) {
    return '연사 ×$n';
  }

  @override
  String ammoSniper(String rate) {
    return '치명 ×$rate';
  }

  @override
  String ammoChain(int n) {
    return '연쇄 $n';
  }

  @override
  String ammoPierce(int n) {
    return '관통 $n칸';
  }

  @override
  String ammoSkip(int n) {
    return '튕김 $n회';
  }

  @override
  String ammoMine(int n) {
    return '설치 $n턴';
  }

  @override
  String ammoFlock(int n) {
    return '투하 ×$n';
  }

  @override
  String ammoHoming(int n) {
    return '유도 $n°';
  }

  @override
  String ammoAssault(int n) {
    return '강습 +$n';
  }

  @override
  String ammoSupport(int n) {
    return '수리 $n%';
  }

  @override
  String get rangeShort => '짧음';

  @override
  String get rangeMedium => '보통';

  @override
  String get rangeLong => '긺';

  @override
  String get rangeVeryLong => '매우 긺';

  @override
  String get outOfRange => '사거리 밖';

  @override
  String get tapToSplit => '탭해서 분열!';

  @override
  String get menuBattle => '허수아비와 해전';

  @override
  String get menuHotseat => '둘이서 해전';

  @override
  String get menuShipyard => '조선소';

  @override
  String get menuCrew => '선원';

  @override
  String statPoints(int used, int max) {
    return '포인트 $used/$max';
  }

  @override
  String statWaterline(String cells) {
    return '흘수선 $cells칸';
  }

  @override
  String statFuelPerCell(String fuel) {
    return '1칸 연료 $fuel';
  }

  @override
  String statTank(int n) {
    return '탱크 $n';
  }

  @override
  String statSpeed(String speed) {
    return '속도 $speed칸/초';
  }

  @override
  String statCabins(int n, int max) {
    return '선실 $n/$max';
  }

  @override
  String statModules(int n, int max) {
    return '모듈 $n/$max';
  }

  @override
  String statCaptain(int n) {
    return '선장실 $n/1';
  }

  @override
  String get materialPine => '소나무';

  @override
  String get materialOak => '참나무';

  @override
  String get materialIron => '철판';

  @override
  String get materialCork => '코르크';

  @override
  String get materialNet => '망사';

  @override
  String get toolCabin => '선실';

  @override
  String get toolErase => '지우기';

  @override
  String get moduleGunPort => '포문';

  @override
  String get moduleMagazine => '화약고';

  @override
  String get modulePump => '펌프';

  @override
  String get moduleWorkshop => '목수 공방';

  @override
  String get moduleMast => '돛대';

  @override
  String get moduleLookout => '망루';

  @override
  String get moduleCaptain => '선장실';

  @override
  String get moduleFuelTank => '연료통';

  @override
  String get undo => '되돌리기';

  @override
  String get save => '저장';

  @override
  String get saved => '저장했어요';

  @override
  String get cannotSave => '빨간 칸과 수치를 확인하세요';

  @override
  String get sailWithThis => '이 배로 출전';

  @override
  String get sailing => '출전 중';

  @override
  String get loadPreset => '추천 불러오기';

  @override
  String planSlot(int n) {
    return '설계도 $n';
  }

  @override
  String crewCost(int used, int max) {
    return '코스트 $used/$max';
  }

  @override
  String get crewHint => '해적을 선실로 끌어다 놓으세요';

  @override
  String get deckFamilies => '계열';

  @override
  String get deckRanges => '사거리';

  @override
  String get preferNear => '가까이 싸움';

  @override
  String get preferFar => '멀리 싸움';

  @override
  String get preferMixed => '거리 균형';

  @override
  String get familyLob => '투척';

  @override
  String get familyDirect => '직사';

  @override
  String get familyPierce => '관통';

  @override
  String get familySkip => '물수제비';

  @override
  String get familyUnderwater => '수중';

  @override
  String get familyAir => '공중';

  @override
  String get familyAssault => '강습';

  @override
  String get familySupport => '지원';

  @override
  String get rarityCommon => '일반';

  @override
  String get rarityRare => '희귀';

  @override
  String get rarityHero => '영웅';

  @override
  String get rarityLegend => '전설';

  @override
  String get rarityMyth => '신화';
}
