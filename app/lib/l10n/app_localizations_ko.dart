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
  String get navBack => '뒤로';

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
  String get emphasisBoom => '콰광!';

  @override
  String get emphasisDoubleHit => '연속 명중!';

  @override
  String get emphasisCabin => '선실 직격!';

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
  String get pirate_p02_name => '불가사리 불꽃병 스타리';

  @override
  String get pirate_p02_desc => '회전하는 불별, 착탄 둘레 화상 지대';

  @override
  String get pirate_p02_lore => '불꽃놀이를 좋아하다 배를 세 척 태웠다.';

  @override
  String get pirate_p03_name => '꽃게 형제';

  @override
  String get pirate_p03_desc => '둘이 한 발씩, 같은 지점에 두 번 터진다';

  @override
  String get pirate_p03_lore => '둘이 늘 말다툼하지만 겨누는 곳은 늘 같다.';

  @override
  String get pirate_p05_name => '화산 소라게 볼케';

  @override
  String get pirate_p05_desc => '초고각 곡사, 3층을 뚫고 크게 폭발';

  @override
  String get pirate_p05_lore => '등의 화산이 식은 적이 없다.';

  @override
  String get pirate_p08_name => '해골 저격수 본즈';

  @override
  String get pirate_p08_desc => '초고속 저격, 빛나는 눈 조준경';

  @override
  String get pirate_p08_lore => '눈구멍에서 빛이 나면 이미 늦었다.';

  @override
  String get pirate_p09_name => '쏠배감펭 가시포 라이언';

  @override
  String get pirate_p09_desc => '가시 부채꼴 연사, 망사를 찢는다';

  @override
  String get pirate_p09_lore => '지느러미 하나하나가 독 가시 대포다.';

  @override
  String get pirate_p10_name => '전기뱀장어 볼트';

  @override
  String get pirate_p10_desc => '맞은 해적에서 번지는 체인 번개';

  @override
  String get pirate_p10_lore => '물이 많은 곳에서는 더 신이 난다.';

  @override
  String get pirate_p12_name => '일각고래 나르';

  @override
  String get pirate_p12_desc => '뿔 창으로 해적 3명까지 일렬로 꿰뚫는다';

  @override
  String get pirate_p12_lore => '북쪽 바다에서 내려온 조용한 창잡이.';

  @override
  String get pirate_p13_name => '바다코끼리 닻잡이 왈러스';

  @override
  String get pirate_p13_desc => '무거운 닻으로 블록을 뚫고 뜯어낸다';

  @override
  String get pirate_p13_lore => '닻을 던지는 것보다 끌어오는 걸 더 좋아한다.';

  @override
  String get pirate_p14_name => '톱상어 소오';

  @override
  String get pirate_p14_desc => '톱날 코로 세로줄을 통째로 자른다';

  @override
  String get pirate_p14_lore => '돛대만 보면 코가 근질거린다.';

  @override
  String get pirate_p15_name => '향유고래 모비';

  @override
  String get pirate_p15_desc => '적 배를 3칸 끌어당기고 다음 턴 묶는다';

  @override
  String get pirate_p15_lore => '바다에서 가장 큰 힘. 느리지만 놓치지 않는다.';

  @override
  String get pirate_p17_name => '펭귄 배썰매 핑구';

  @override
  String get pirate_p17_desc => '튕긴 뒤 갑판을 미끄러지며 연속 피해';

  @override
  String get pirate_p17_lore => '얼음이 없어도 어디서든 미끄러진다.';

  @override
  String get pirate_p18_name => '투구게 셀던';

  @override
  String get pirate_p18_desc => '벽에서 되튀며 여러 번 친다';

  @override
  String get pirate_p18_lore => '삼억 년을 버틴 등껍질은 어디든 튕긴다.';

  @override
  String get pirate_p19_name => '돌고래 서퍼 돌피';

  @override
  String get pirate_p19_desc => '선체에 붙어 흘수선을 연타';

  @override
  String get pirate_p19_lore => '파도 위에서 웃지 않은 적이 없다.';

  @override
  String get pirate_p20_name => '범고래 해일 오르카';

  @override
  String get pirate_p20_desc => '큰 파도로 갑판 해적을 쓸고 침수 +8%p';

  @override
  String get pirate_p20_lore => '오르카가 지나가면 바다가 한 번 기운다.';

  @override
  String get pirate_p22_name => '해파리 기뢰 젤리';

  @override
  String get pirate_p22_desc => '떠 있는 기뢰, 적 배가 지나가면 폭발';

  @override
  String get pirate_p22_lore => '어디 떠 있는지 아무도 모른다. 젤리 자신도.';

  @override
  String get pirate_p23_name => '바라쿠다 어뢰 바라';

  @override
  String get pirate_p23_desc => '곧게 날아 물속으로 파고드는 어뢰';

  @override
  String get pirate_p23_lore => '한 번 정한 방향은 바꾸지 않는다.';

  @override
  String get pirate_p24_name => '곰치 모레이';

  @override
  String get pirate_p24_desc => '붙어서 물어뜯고 펌프를 멈춘다';

  @override
  String get pirate_p24_lore => '틈만 보이면 이빨부터 들이민다.';

  @override
  String get pirate_p25_name => '아기 크라켄 크라키';

  @override
  String get pirate_p25_desc => '촉수로 붙어 턴마다 침수를 올린다';

  @override
  String get pirate_p25_lore => '아직 아기지만 촉수는 벌써 셋이다.';

  @override
  String get pirate_p29_name => '알바트로스 알바';

  @override
  String get pirate_p29_desc => '비행 중 탭으로 방향 전환, 명중 시 바람 역전';

  @override
  String get pirate_p29_lore => '바람을 거슬러 나는 법을 처음 알아낸 새.';

  @override
  String get pirate_p30_name => '폭풍 가오리 만타';

  @override
  String get pirate_p30_desc => '상대 다음 턴 궤적 봉쇄, 무작위 피해';

  @override
  String get pirate_p30_lore => '만타가 지나간 하늘에는 길이 남지 않는다.';

  @override
  String get pirate_p32_name => '농게 로프 크래비';

  @override
  String get pirate_p32_desc => '로프로 넘어가 해적을 물고 바다로';

  @override
  String get pirate_p32_lore => '큰 집게 하나면 충분하다.';

  @override
  String get pirate_p33_name => '대게 방패병 킹';

  @override
  String get pirate_p33_desc => '착지해 선실 하나를 다음 턴 봉쇄';

  @override
  String get pirate_p33_lore => '방패를 내려놓는 법을 모른다.';

  @override
  String get pirate_p34_name => '바닷가재 쌍집게 랍';

  @override
  String get pirate_p34_desc => '쓰러뜨리면 다음 해적으로 점프';

  @override
  String get pirate_p34_lore => '두 집게가 쉬는 걸 본 사람이 없다.';

  @override
  String get pirate_p35_name => '해골 선장 데비';

  @override
  String get pirate_p35_desc => '해골 선원 3명 소환, 한 번 부활';

  @override
  String get pirate_p35_lore => '바다 밑에서 돌아온 선장. 두 번은 안 진다.';

  @override
  String get pirate_p37_name => '아기고래 뿜뿜';

  @override
  String get pirate_p37_desc => '물을 뿜어 침수량 즉시 감소';

  @override
  String get pirate_p37_lore => '숨구멍으로 뿜는 물줄기가 자랑이다.';

  @override
  String get pirate_p38_name => '소라게 요리사 쿡';

  @override
  String get pirate_p38_desc => '주변 아군 치유, 아군 쿨다운 −1';

  @override
  String get pirate_p38_lore => '배고픈 선원은 싸우지 못한다는 게 신조다.';

  @override
  String get pirate_p39_name => '산호 골렘 코리';

  @override
  String get pirate_p39_desc => '원하는 곳에 산호 방벽, 2턴';

  @override
  String get pirate_p39_lore => '천천히 자라지만 무엇이든 막아선다.';

  @override
  String get pirate_p40_name => '아귀 항해사 램프';

  @override
  String get pirate_p40_desc => '다음 내 턴 궤적 확대·바람 무시·연료 +30';

  @override
  String get pirate_p40_lore => '어두운 바다에서도 길을 잃은 적이 없다.';

  @override
  String get blueprint_balanced_name => '밸런스';

  @override
  String get blueprint_balanced_desc =>
      '참나무 용골에 펌프와 목수 공방을 단 기본형. 포문과 망루로 한 명을 키운다.';

  @override
  String get blueprint_armored_name => '철갑';

  @override
  String get blueprint_armored_desc =>
      '선실 양옆을 철판으로 막은 튼튼한 배. 화약고로 화력을 더하지만, 무거워 깊이 잠기니 침수를 조심하자.';

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
  String get aimCancel => '놓으면 취소';

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
  String get moduleMast => '소나무 돛대';

  @override
  String get moduleMastBamboo => '대나무 돛대';

  @override
  String get moduleMastOak => '참나무 돛대';

  @override
  String get moduleMastIron => '철 돛대';

  @override
  String get moduleMastCrow => '망대 돛대';

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

  @override
  String get opponentAi => '컴퓨터 (AI)';

  @override
  String get menuBattleAi => 'AI 와 해전';

  @override
  String get chooseLevel => '난이도';

  @override
  String get levelEasy => '쉬움';

  @override
  String get levelNormal => '보통';

  @override
  String get levelHard => '어려움';

  @override
  String get levelHell => '지옥';

  @override
  String get autoEndTurn => '2발 뒤 자동 턴 종료';

  @override
  String get sea_1_name => '열대 만';

  @override
  String get sea_1_faction => '붉은집게 초계대';

  @override
  String get mission_no_pirate_down => '내 해적이 한 명도 쓰러지지 않고 승리';

  @override
  String mission_flood_below(Object percent) {
    return '내 침수량 $percent% 이하로 승리';
  }

  @override
  String mission_hull_above(Object percent) {
    return '내 선체 내구도 $percent% 이상으로 승리';
  }

  @override
  String get mission_win_by_sink => '격침으로 승리 (전멸·시간 판정 제외)';

  @override
  String mission_turns_within(Object turns) {
    return '$turns턴 안에 승리';
  }

  @override
  String get story_t1_enemy => '초계대 신병: 항구는 봉쇄됐다! 돌아가라, 해적 놈들!';

  @override
  String get story_t1_ally => '옥토: 해적? 우린 그냥 배를 고치던 중인데… 좋아, 폭탄 맛 좀 봐라!';

  @override
  String get story_t2_enemy => '초계대 신병: 이번엔 둘이다. 거리를 벌려서 쏴 주지!';

  @override
  String get story_t2_ally => '톡: 연료를 아껴 두렴. 다가갈 때와 물러날 때를 골라야 해.';

  @override
  String get story_t3_enemy => '초계대 잠수부: 흘수선 아래를 뚫으면 배는 가라앉는 법이지.';

  @override
  String get story_t3_ally => '톡: 구멍은 내가 막을게. 물이 차기 전에 펌프를 돌려!';

  @override
  String get story_s1_1_enemy => '초계대 순찰병: 해적 단속이다. 그 낡은 배로 어딜 가려고?';

  @override
  String get story_s1_1_ally => '옥토: 우리 손으로 지은 배야. 낡았다고 얕보지 마!';

  @override
  String get story_s1_2_enemy => '초계대 순찰병: 작살꾼도 데려왔다. 벽 뒤에 숨어도 소용없어.';

  @override
  String get story_s1_2_ally => '수리: 저 돌팔매 솜씨 좀 보라구. 흘수선을 노리면 되지?';

  @override
  String get story_s1_3_enemy => '초계대 척후병: 앵무새가 너희를 찾아낼 거다. 숨을 곳은 없어.';

  @override
  String get story_s1_3_ally => '옥토: 그럼 물이 새기 전에 끝내자. 빠르게!';

  @override
  String get story_s1_4_enemy => '초계대 포수: 넷이 쏘면 너희 갑판은 남아나지 않는다.';

  @override
  String get story_s1_4_ally => '폴리: 하늘은 내 거야! 위에서 내리꽂아 줄게.';

  @override
  String get story_s1_5_enemy => '꽃게 부대장: 뱃머리 철판을 봐라. 직사탄 따위는 튕겨낸다!';

  @override
  String get story_s1_5_ally => '톡: 정면이 단단하면 위에서, 아래에서 치면 되지.';

  @override
  String get story_s1_12_enemy => '초계선 함장: 심장 조각은 넘길 수 없다. 초계선이 다가간다, 각오해라!';

  @override
  String get story_s1_12_ally => '옥토: 첫 조각은 우리가 가져간다. 다 같이, 쏴!';

  @override
  String portLevel(Object level) {
    return 'Lv $level';
  }

  @override
  String portXp(Object xp, Object next) {
    return '경험치 $xp / $next';
  }

  @override
  String get portSail => '출항';

  @override
  String get portShipyardLocked => '조선소는 4판째부터 열려요';

  @override
  String get soundOn => '효과음';

  @override
  String get vibrationOn => '진동';

  @override
  String get calmShakeOn => '화면 흔들림 줄이기';

  @override
  String get campaignTitle => '캠페인';

  @override
  String get stageLocked => '앞 스테이지를 먼저 깨세요';

  @override
  String stageTutorialName(Object n) {
    return '튜토리얼 $n';
  }

  @override
  String stageNumberName(Object sea, Object number) {
    return '$sea-$number';
  }

  @override
  String get stageKindMidBoss => '중간 보스';

  @override
  String get stageKindBoss => '해역 보스';

  @override
  String get prepTitle => '전투 준비';

  @override
  String prepBlueprintSlot(Object slot) {
    return '설계도 $slot';
  }

  @override
  String get prepBlueprintEmpty => '빈 칸 (추천 밸런스)';

  @override
  String get prepDeck => '출전 해적';

  @override
  String prepCost(Object used, Object limit) {
    return '코스트 $used / $limit';
  }

  @override
  String get prepEnemy => '상대';

  @override
  String prepEnemyCount(Object count) {
    return '적 해적 $count명';
  }

  @override
  String prepWeather(Object wave, Object wind) {
    return '파도 $wave · 바람 최대 $wind';
  }

  @override
  String get prepEditDeck => '덱 수정';

  @override
  String get prepSail => '출항';

  @override
  String get dialogueTap => '탭하여 계속';

  @override
  String get personality_bombard => '포격형';

  @override
  String get personality_hunter => '사냥형';

  @override
  String get personality_sinker => '침몰형';

  @override
  String get personality_rusher => '돌격형';

  @override
  String get gimmick_bow_iron_shield =>
      '뱃머리 철판 방패: 방패가 서 있는 동안 직사 피해 절반. 뱃머리를 먼저 부숴라';

  @override
  String get gimmick_patrol_closing_in => '초계선이 턴마다 한 칸씩 다가오고 쿨다운이 두 배로 빨리 준다';

  @override
  String resultMission(Object text) {
    return '미션: $text';
  }

  @override
  String resultInTurns(Object turns) {
    return '$turns턴 안에 승리';
  }

  @override
  String rewardGold(Object gold) {
    return '골드 +$gold';
  }

  @override
  String rewardXp(Object xp) {
    return '경험치 +$xp';
  }

  @override
  String rewardPirate(Object name) {
    return '새 해적 합류: $name';
  }

  @override
  String get rewardFirstClear => '첫 클리어 보너스';

  @override
  String get resultToPort => '항구로';

  @override
  String get resultMvp => 'MVP';

  @override
  String statTurns(Object turns) {
    return '사용 턴 $turns';
  }

  @override
  String statShots(Object shots) {
    return '발사 $shots발';
  }

  @override
  String statFlood(Object mine, Object enemy) {
    return '침수 나 $mine% · 상대 $enemy%';
  }

  @override
  String get resultDouble => '광고 보고 2배';

  @override
  String levelUpTo(Object level) {
    return '레벨 업! Lv $level';
  }

  @override
  String get storySkip => '건너뛰기';

  @override
  String get story_prologue_1 => '산호 항구의 평화로운 아침. 문어 옥토와 거북 목수 톡이 작은 배를 손본다.';

  @override
  String get story_prologue_2 =>
      '황금 기함이 나타나 골드핀이 바다의 심장을 깨뜨린다. 하늘이 어두워지고 폭풍이 인다.';

  @override
  String get story_prologue_3 => '파도에 우리 배가 부서진다. 톡: “괜찮아. 우리 손으로 다시 짓자!”';

  @override
  String get story_prologue_4 =>
      '붉은집게 초계대가 “해적 단속”을 핑계로 항구를 봉쇄한다. 부서진 심장의 첫 조각이 초계대 기함에서 빛난다.';

  @override
  String get story_prologue_5 =>
      '옥토: “여섯 조각을 되찾아 황금 섬으로 가자!” 먼저 항구를 막은 초계대부터 뚫어야 한다.';

  @override
  String get story_sea_1_intro_1 => '붉은집게 초계대: 열대 만은 우리 바다다. 해적 단속이니 배를 돌려라!';

  @override
  String get story_sea_1_intro_2 =>
      '톡: 저들 기함에서 첫 조각이 빛나. 순찰선을 하나씩 제치고 기함까지 가자.';

  @override
  String get story_s1_5_before =>
      '꽃게 부대장: 여기까지 온 건 칭찬해 주지. 하지만 이 철판 뱃머리는 못 뚫는다!';

  @override
  String get story_s1_5_after => '꽃게 부대장: 크윽… 기함으로 후퇴다! 함장님이 너희를 가만두지 않을 거다!';

  @override
  String get story_s1_12_before_1 =>
      '초계선 함장: 조각의 힘으로 이 초계선은 멈추지 않는다. 다가가서 짓밟아 주마.';

  @override
  String get story_s1_12_before_2 => '옥토: 다가온다면 오히려 좋아. 가까이서 폭탄 맛을 보여 주지!';

  @override
  String get story_s1_12_after_1 =>
      '초계선 함장: 조각이… 빛을 잃었다. 안개 해협의 선단이 너희를 기다릴 것이다.';

  @override
  String get story_s1_12_after_2 => '톡: 첫 조각을 되찾았어! 심장이 조금 따뜻해졌어.';

  @override
  String get story_s1_12_after_3 => '옥토: 다음은 안개 해협이다. 해골들이 조각으로 저주를 풀려 한다고?';

  @override
  String get tutorial_hint_1 => '해적 카드를 누르고, 배 위 해적을 뒤로 당겨서 쏘세요';

  @override
  String get tutorial_hint_2 => '◀ ▶ 버튼을 꾹 누르고 있으면 배가 움직입니다. 연료가 남은 만큼만 갑니다';

  @override
  String get tutorial_hint_3 => '흘수선 아래 구멍은 침수! 톡을 내 배에 쏴서 수리하세요';

  @override
  String get resultDoubleDone => '2배로 받았어요';

  @override
  String get replaySave => '리플레이 저장';

  @override
  String get replaySaved => '리플레이 저장됨';

  @override
  String statDamage(Object damage, Object blocks) {
    return '준 피해 $damage · 부순 블록 $blocks';
  }

  @override
  String statAccuracy(Object percent) {
    return '명중률 $percent%';
  }

  @override
  String get iapRemoveAds => '광고 제거';

  @override
  String get iapBought => '구매 완료';

  @override
  String get iapBuy => '구매';

  @override
  String get devTestBattle => '테스트 대전';

  @override
  String get devMyDeck => '내 덱';

  @override
  String get devEnemyDeck => '상대 덱';

  @override
  String get devRandomEnemy => '상대 덱이 비어 있으면 무작위 4명';

  @override
  String get devStart => '시작';

  @override
  String get devPractice => '더미배 연습';

  @override
  String get devToolsOn => '개발 도구를 켰습니다';

  @override
  String get devToolsOff => '개발 도구를 껐습니다';

  @override
  String get storyReplay => '이야기 다시 보기';

  @override
  String get storyReplayEmpty => '아직 본 이야기가 없습니다';

  @override
  String get storyTitlePrologue => '프롤로그';

  @override
  String get storyTitleSea1Intro => '해역 1 인트로';

  @override
  String get storyTitleMidBossBefore => '중간 보스 앞';

  @override
  String get storyTitleMidBossAfter => '중간 보스 뒤';

  @override
  String get storyTitleBossBefore => '해역 보스 앞';

  @override
  String get storyTitleBossAfter => '해역 보스 뒤';

  @override
  String get prepMyShip => '내 배';

  @override
  String get prepCabins => '선실 배치';

  @override
  String get prepCabinEmpty => '빈 선실';

  @override
  String get hitTagCrit => '치명';

  @override
  String get hitTagPierce => '관통';

  @override
  String get hitTagChain => '연쇄';

  @override
  String get hitTagBurn => '화상';

  @override
  String get hitTagMine => '기뢰';

  @override
  String get hitTagBite => '물어뜯기';

  @override
  String get hitTagRepair => '수리';

  @override
  String get hitTagSeal => '봉쇄';

  @override
  String get hitTagPull => '끌어당김';

  @override
  String get hitTagWind => '바람 역전';

  @override
  String get hitTagBlind => '궤적 봉쇄';

  @override
  String get hitTagBail => '배수';

  @override
  String get hitTagBoost => '등불';

  @override
  String get hitTagHeal => '치유';

  @override
  String get hitTagWall => '방벽';

  @override
  String get hitTagRevive => '부활';

  @override
  String get hitTagIntercept => '요격';

  @override
  String get cabinSealed => '봉쇄';

  @override
  String get moveLocked => '묶임';

  @override
  String get windReversed => '역풍';

  @override
  String get windCalm => '무풍';

  @override
  String aimAngle(String deg) {
    return '$deg°';
  }

  @override
  String aimPower(String pct) {
    return '힘 $pct%';
  }

  @override
  String get musicOn => '배경음악';

  @override
  String get shipUpgrades => '배 업그레이드';

  @override
  String get shipStage1 => '돛단배';

  @override
  String get shipStage2 => '작은 슬루프';

  @override
  String get shipStage3 => '슬루프';

  @override
  String get shipStage4 => '큰 슬루프';

  @override
  String get shipGrowRow => '배 키우기';

  @override
  String shipGrowNeed(Object stage) {
    return '$stage 클리어하면 열린다';
  }

  @override
  String get shipMaxed => '최고 단계';

  @override
  String hullLevelRow(Object level) {
    return '선형 Lv $level';
  }

  @override
  String mastLevelRow(Object name, Object level) {
    return '$name Lv $level';
  }

  @override
  String goldCost(Object gold) {
    return '골드 $gold';
  }

  @override
  String buyAsk(Object name, Object gold) {
    return '$name: 골드 $gold를 쓸까요?';
  }

  @override
  String get notEnoughGold => '골드가 모자라다';

  @override
  String get buy => '사기';

  @override
  String get shipGrown => '배가 커졌다!';

  @override
  String shipGrownBody(Object width, Object height, Object cabins) {
    return '$width×$height칸 · 선실 $cabins칸';
  }

  @override
  String get shipGrowReady => '배를 키울 수 있다! 조선소로 가자';

  @override
  String get devStagePick => '단계 고르기(개발)';

  @override
  String get ok => '확인';

  @override
  String hullPercent(int percent) {
    return '선체 $percent%';
  }

  @override
  String fuelPercent(int percent) {
    return '$percent%';
  }

  @override
  String get bossBanner => '보스 등장!';

  @override
  String get barkFire1 => '받아라!';

  @override
  String get barkFire2 => '정확히 노렸다!';

  @override
  String get barkFire3 => '한 방 더 간다!';

  @override
  String get barkFire4 => '포탄 배달이요!';

  @override
  String get barkHurt1 => '으악, 따끔해!';

  @override
  String get barkHurt2 => '이 정도는 끄떡없어!';

  @override
  String get barkHurt3 => '배가 흔들린다!';

  @override
  String get barkHurt4 => '갚아 주마!';

  @override
  String get barkAllyDown1 => '동료가 쓰러졌다! 버텨!';

  @override
  String get barkAllyDown2 => '너의 몫까지 싸운다!';

  @override
  String get barkAllyDown3 => '정신 차려, 금방 끝낼게!';

  @override
  String get barkAllyDown4 => '가만두지 않겠다!';

  @override
  String get barkTauntStart1 => '해적 단속이다! 항복해라!';

  @override
  String get barkTauntStart2 => '그 조각배로 덤빈다고?';

  @override
  String get barkTauntStart3 => '초계대 앞에선 다 소용없다!';

  @override
  String get barkTauntStart4 => '집게 맛 좀 봐라!';

  @override
  String get barkTauntLow1 => '이, 이럴 리가 없어!';

  @override
  String get barkTauntLow2 => '물이 샌다! 펌프를 돌려!';

  @override
  String get barkTauntLow3 => '제법이군… 하지만 아직이다!';

  @override
  String get barkTauntLow4 => '후퇴는 없다, 버텨라!';

  @override
  String get goalTitle => '다음 목표';

  @override
  String get goalGo => '도전';

  @override
  String goalStars(Object have, Object total) {
    return '별 $have / $total';
  }

  @override
  String goalShipNeed(Object stage) {
    return '배 확장: $stage 클리어';
  }

  @override
  String get goalShipDone => '배를 다 키웠다';

  @override
  String get goalAllClear => '이 해역을 모두 깼다!';

  @override
  String get emphasisMast => '돛대 부러짐!';
}
