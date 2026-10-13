# 문구 검수와 용어표 — ko·en ARB (2026-10-13)

> 게임 정리(S1~S6) 뒤 `app/lib/l10n/app_ko.arb`·`app_en.arb` 전체(488키)를 새 규칙 기준으로 읽었다. 값(문구)만 고치고 키 이름과 코드는 그대로 두었다.
> 기준: 설계서 2~6장·§13·§15, BALANCE A2.x·A4.3·A4.8. 해적 설명의 숫자(폭발 반경 1칸, 분열 4갈래, 연사 3발, 관통 2칸, 투하 3·4개, 밀기 1·2칸, 끌기 3칸)는 A4.8 과 맞는다. 피해 숫자는 설명에 없어 1.5배 밸런스 변경과 무관하다.

## 1. 고친 문구

| 키 | 무엇이 문제였나 | 고친 뒤 (ko / en) |
| --- | --- | --- |
| `outcomeTimeDecision` | 옛 ‘시간 판정’ 규칙 이름 | 턴 제한 판정 / Turn limit |
| `autoEndTurn` | 옛 ‘2발’ 규칙 | 쏜 뒤 자동 턴 종료 / Auto end turn after firing |
| `crewHint` | 망대 자리가 빠짐 | 선실이나 망대로 / into a cabin or the crow's nest |
| `story_s1_2_ally` | 사라진 ‘흘수선’ | 배 아래쪽을 노리면 / Aim low on the hull |
| `story_s1_3_ally` | 사라진 침수(‘물이 새기 전’) | 찾아내기 전에 끝내자 / before it finds us |
| `story_s1_5_enemy` | 없는 규칙(‘반은 튕겨낸다’) | 흠집도 안 난다 / won't even scratch it |
| `story_s1_11_enemy` | 격침(‘가라앉혀’) | 쓰러뜨려 / take you all down |
| `barkTauntLow2` | 침수·펌프 | 선체가 버티질 못한다 / The hull can't take much more |
| `timeVerdictByHull`·`bannerCaptainLost`·`captainPercent` (en) | ‘cabin’ 이 선실과 섞임 | captain's cabin, 좁은 곳은 Captain (배너 ‘Captain down!’) |
| `story_t3_ally`·`story_s1_7_ally`·`story_s1_11_ally` (en) | 망대가 ‘lookout’ 과 ‘crow's nest’ 로 갈림 | crow's nest 로 통일 |
| `pirate_p36~p40_desc`·`p20_desc` (en) | ko 는 ‘적 배’, en 은 ‘the ship’ | the enemy ship |
| `pirate_p21·p22·p24_desc` (en) | ‘blows at my next turn’ 어색함 | blows at the start of your next turn |
| `pirate_p23_desc` (en) | 사라진 흘수선(‘under the waterline’) | dives into the water |
| `pirate_p28_desc` | ‘꼭대기’ 가 무엇의 꼭대기인지 모호 | 궤적 꼭대기 / at the top of its arc |
| `pirate_p17_desc` (ko) | ‘배로’ 가 배(船)로 읽힘 | 배 썰매로 수면을 튕겨 |
| `portShipyardLocked` (en) | ‘opens from’ 번역투 | opens at your 4th battle |
| `notEnoughGold` (ko) | 혼자 반말체 | 골드가 모자라요 |

골든: HUD(en)·선원·설정 화면을 다시 만들었다. 넘치는 글자는 없다(선원 안내 한 줄은 ko·en 모두 패널 안에 든다).

## 2. 코드 정리가 필요한 옛 규칙 키 (값은 그대로 둠)

다른 세션이 앱 코드를 점검 중이라 키는 지우지 않았다. 쓰이는 곳이 없으면 S3 후속 정리에서 지운다.
- `hitTagRepair`·`hitTagNoRepair`·`hitTagShield`·`hitTagShieldBroken`·`hitTagSeal`·`hitTagWind`·`hitTagBail`·`hitTagBoost`·`hitTagHeal`·`hitTagWall`·`hitTagRevive`·`hitTagIntercept`·`hitTagBurn` — 사라진 지원·화재·방벽 효과
- `moveLocked`(묶임)·`windReversed`(역풍) — 사라진 상태 효과
- `noPirateCanFire` — 옛 ‘쏠 해적 없음 자동 넘김’ 안내
- `hull`(선체) — HUD 가 해적 체력·선장실로 바뀜

## 3. 용어표

| 한국어 | English | 쓰는 곳·메모 |
| --- | --- | --- |
| 선장실 | captain's cabin (좁은 칸: Captain) | 판정·배너·HUD. ‘Cabin’ 만 쓰지 않는다 |
| 선실 | cabin | 해적이 타는 칸 |
| 망대 | crow's nest | 돛대 꼭대기 5번 자리. ‘lookout’ 쓰지 않는다 |
| 돛대 | mast | |
| 파도 구간 | wave zone | 잔잔 calm · 보통 normal · 거침 rough |
| 바람 | wind | 무풍 calm |
| 연료 | fuel | 내 턴마다 가득 |
| 전진 / 후퇴 | Ahead / Back | 이동 버튼 |
| 전멸 | wiped out / Crew wiped out | 승리 방식 |
| 선장실 파괴 | captain's cabin lost / down | 승리 방식 |
| 턴 제한 (판정) | turn limit | 24턴 뒤 해적 체력 비교. ‘시간 판정’ 쓰지 않는다 |
| 해적 체력 | crew HP | |
| 충격 (계열) / 충격탄 | Shock / shock shot | 상대 배를 민다(push) |
| 밀기 / 끌어당김 | push / pull | |
| 강습 | assault (탄 수치: Raid) | 적 갑판에 오른다(board) |
| 투척·직사·관통·물수제비·수중·공중 | Lob·Direct·Pierce·Skip·Underwater·Air | 계열 |
| 폭발·화염·분열·연사·저격·연쇄·관통·튕김·설치·투하·유도 | Blast·Fire·Split·Burst·Sniper·Chain·Pierce·Skip·Mine·Drop·Homing | 탄종 |
| 쓰러짐 / KO | Down / KO | |
| 일반·희귀·영웅·전설·신화 | Common·Rare·Hero·Legend·Myth | 등급. ★ 는 전설 고유 능력 |
| 코스트 | cost | 출전 한도 |
| 조선소 / 선원 / 항구 | Shipyard / Crew / Port | |
| 설계도 / 추천 | blueprint (좁은 칸: Plan) / preset | |
| 소나무·참나무·철판 | Pine·Oak·Iron | 재질 |
