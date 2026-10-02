import 'package:pirate_busters/game/view/backdrop.dart';

/// 컷에 나오는 해적 한 명 (설계서 §15.4 ‘해적 파츠와 해역 배경’): 그림 종족, 표정
/// (설계서 §10.1 6종), 적 쪽(빨강 팀, 오른쪽)인가.
class StoryCast {
  const StoryCast(
    this.species, {
    this.expr = 'default',
    this.enemy = false,
    this.silhouette = false,
  });

  /// 부위 그림 종족 id (`assets/images/characters/<species>/`).
  final String species;
  final String expr;
  final bool enemy;

  /// 정체를 숨긴 검은 실루엣 + 금관 (골드핀, 설계서 §15.4).
  final bool silhouette;
}

/// 컷 하나 (설계서 §15.4): 해역 배경·모드, 등장 해적, 글자 키. 글자는 ARB 에만
/// 있다(§14.3). [narration] 이면 위 가운데 자막으로, 아니면 맨 앞 해적의 말풍선으로
/// 보인다 (에셋 v0.23 `story/cutscenes.json` 형식).
class StoryCut {
  const StoryCut(
    this.textKey, {
    this.cast = const [],
    this.region = 'tropic',
    this.mode = SeaMode.normal,
    this.narration = false,
  });

  final String textKey;
  final List<StoryCast> cast;

  /// 해역 배경 (`bg/<region>/`). 화면 톤은 [mode] 색으로 바꾼다 (§10.2).
  final String region;
  final SeaMode mode;
  final bool narration;

  /// 말하는 해적(맨 앞). 자막 컷이거나 아무도 없으면 null.
  StoryCast? get speaker => narration || cast.isEmpty ? null : cast.first;
}

/// 컷신 목록 (설계서 §15.2 프롤로그, §15.3 해역 1, §15.4 연출 형식). id 로 본 것을 저장한다.
abstract final class StoryData {
  static const String prologue = 'prologue';
  static const String sea1Intro = 'sea_1_intro';

  static String bossBefore(String stageId) =>
      's${stageId.replaceAll('-', '_')}_before';
  static String bossAfter(String stageId) =>
      's${stageId.replaceAll('-', '_')}_after';

  static const StoryCast _octo = StoryCast('octo');
  static const StoryCast _tok = StoryCast('turtle');
  static const StoryCast _crabs = StoryCast('crabs', enemy: true);
  static const StoryCast _lob = StoryCast('lobster', enemy: true);

  /// 프롤로그는 에셋 `story/cutscenes.json` 구성(해역·모드·등장 해적과 표정)을
  /// 따른다. 글자는 앱의 `story_prologue_n` 자막 하나다(에셋 v0.25, ADR-065).
  static const Map<String, List<StoryCut>> cuts = {
    prologue: [
      StoryCut(
        'story_prologue_1',
        narration: true,
        cast: [
          StoryCast('octo', expr: 'win'),
          _tok,
        ],
      ),
      StoryCut(
        'story_prologue_2',
        narration: true,
        region: 'gold',
        mode: SeaMode.hell,
        cast: [StoryCast('shark', enemy: true, silhouette: true)],
      ),
      StoryCut(
        'story_prologue_3',
        narration: true,
        region: 'storm',
        mode: SeaMode.hell,
        cast: [
          StoryCast('turtle', expr: 'aim'),
          StoryCast('octo', expr: 'hit'),
        ],
      ),
      StoryCut(
        'story_prologue_4',
        narration: true,
        mode: SeaMode.hard,
        cast: [
          StoryCast('lobster', expr: 'aim', enemy: true),
          _octo,
          _tok,
        ],
      ),
      StoryCut('story_prologue_5', narration: true, mode: SeaMode.hard),
    ],
    sea1Intro: [
      StoryCut('story_sea_1_intro_1', cast: [_crabs]),
      StoryCut('story_sea_1_intro_2', cast: [_tok]),
    ],
    's1_5_before': [
      StoryCut('story_s1_5_before', cast: [_crabs]),
    ],
    's1_5_after': [
      StoryCut(
        'story_s1_5_after',
        cast: [StoryCast('crabs', expr: 'lose', enemy: true)],
      ),
    ],
    's1_12_before': [
      StoryCut('story_s1_12_before_1', cast: [_lob]),
      StoryCut('story_s1_12_before_2', cast: [_octo]),
    ],
    's1_12_after': [
      StoryCut(
        'story_s1_12_after_1',
        cast: [StoryCast('lobster', expr: 'lose', enemy: true)],
      ),
      StoryCut('story_s1_12_after_2', cast: [StoryCast('turtle', expr: 'win')]),
      StoryCut('story_s1_12_after_3', cast: [StoryCast('octo', expr: 'win')]),
    ],
  };

  static List<StoryCut>? of(String id) => cuts[id];
}
