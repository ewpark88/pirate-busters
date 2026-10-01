/// 컷 하나 (설계서 §15.4): 말하는 캐릭터의 그림 종족과 대사 키. 글자는 ARB 에만 있다(§14.3).
class StoryCut {
  const StoryCut(this.textKey, {this.species, this.enemy = false});

  final String textKey;

  /// 초상 종족 id (`assets/images/ui/portraits/<species>_<team>.png`). 없으면 그림 없이.
  final String? species;

  /// 적 쪽(빨강 팀, 오른쪽)인가.
  final bool enemy;
}

/// 컷신 목록 (설계서 §15.2 프롤로그, §15.3 해역 1, §15.4 연출 형식). id 로 본 것을 저장한다.
abstract final class StoryData {
  static const String prologue = 'prologue';
  static const String sea1Intro = 'sea_1_intro';

  static String bossBefore(String stageId) =>
      's${stageId.replaceAll('-', '_')}_before';
  static String bossAfter(String stageId) =>
      's${stageId.replaceAll('-', '_')}_after';

  static const Map<String, List<StoryCut>> cuts = {
    prologue: [
      StoryCut('story_prologue_1', species: 'octo'),
      StoryCut('story_prologue_2', species: 'crabs', enemy: true),
      StoryCut('story_prologue_3', species: 'turtle'),
      StoryCut('story_prologue_4', species: 'crabs', enemy: true),
      StoryCut('story_prologue_5', species: 'octo'),
    ],
    sea1Intro: [
      StoryCut('story_sea_1_intro_1', species: 'crabs', enemy: true),
      StoryCut('story_sea_1_intro_2', species: 'turtle'),
    ],
    's1_5_before': [
      StoryCut('story_s1_5_before', species: 'crabs', enemy: true),
    ],
    's1_5_after': [StoryCut('story_s1_5_after', species: 'crabs', enemy: true)],
    's1_12_before': [
      StoryCut('story_s1_12_before_1', species: 'lob', enemy: true),
      StoryCut('story_s1_12_before_2', species: 'octo'),
    ],
    's1_12_after': [
      StoryCut('story_s1_12_after_1', species: 'lob', enemy: true),
      StoryCut('story_s1_12_after_2', species: 'turtle'),
      StoryCut('story_s1_12_after_3', species: 'octo'),
    ],
  };

  static List<StoryCut>? of(String id) => cuts[id];
}
