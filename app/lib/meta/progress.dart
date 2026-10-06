import 'dart:convert';

import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';

/// 플레이어 진행 상태 (개발 계획서 M7, 설계서 §4.5 플레이어 레벨, §6.1 별, §4.6 해적 획득,
/// §13.1 프롤로그·튜토리얼). 불변 값이고 바꾸면 새 객체를 돌려준다. 저장은 `ProgressStore`.
class PlayerProgress {
  const PlayerProgress({
    this.level = 1,
    this.xp = 0,
    this.gold = 0,
    this.ownedPirates = const [],
    this.stars = const {},
    this.prologueSeen = false,
    this.tutorialDone = 0,
    this.matchesPlayed = 0,
    this.seenStories = const [],
    this.ship = const ShipUpgrades(),
  });

  /// JSON 에서 읽는다. 모르는 값·깨진 값은 기본값으로 본다.
  factory PlayerProgress.fromJson(Map<String, Object?> json) {
    int readInt(String key, int fallback) {
      final v = json[key];
      return v is int ? v : fallback;
    }

    final owned = json['ownedPirates'];
    final seen = json['seenStories'];
    final starsRaw = json['stars'];
    return PlayerProgress(
      level: readInt('level', 1).clamp(1, maxLevel),
      xp: readInt('xp', 0),
      gold: readInt('gold', 0),
      ownedPirates: owned is List
          ? owned.whereType<String>().toList(growable: false)
          : const [],
      stars: starsRaw is Map
          ? {
              for (final e in starsRaw.entries)
                if (e.key is String && e.value is int)
                  e.key as String: (e.value! as int).clamp(0, 3),
            }
          : const {},
      prologueSeen: json['prologueSeen'] == true,
      tutorialDone: readInt('tutorialDone', 0).clamp(0, tutorialMatches),
      matchesPlayed: readInt('matchesPlayed', 0),
      seenStories: seen is List
          ? seen.whereType<String>().toList(growable: false)
          : const [],
      // 배 업그레이드 전 저장: 깬 스테이지만큼 확장 단계를 골드 없이 준다 (A28).
      ship: json['ship'] == null
          ? ShipUpgrades(
              stage: ShipUpgrades.openedStage(
                (id) => starsRaw is Map && starsRaw.containsKey(id),
                (id) => id != '1-8',
              ),
            )
          : ShipUpgrades.fromJson(json['ship']),
    );
  }

  /// 저장 문자열에서 읽는다. 비었거나 깨졌으면 새 진행.
  factory PlayerProgress.parse(String? text) {
    if (text == null || text.isEmpty) return const PlayerProgress();
    try {
      final json = jsonDecode(text);
      if (json is Map<String, Object?>) return PlayerProgress.fromJson(json);
    } on FormatException {
      // 깨진 저장은 새 진행으로 본다.
    }
    return const PlayerProgress();
  }

  /// 플레이어 레벨 상한 (설계서 §4.5).
  static const int maxLevel = 20;

  /// 튜토리얼 전투 수 (설계서 §13.1).
  static const int tutorialMatches = 3;

  /// 조선소가 열리는 판 수: 4판째부터 (설계서 §13.1).
  static const int shipyardUnlockMatch = 4;

  /// 플레이어 레벨 1~[maxLevel].
  final int level;

  /// 현재 레벨에서 모은 경험치.
  final int xp;

  final int gold;

  /// 보유 해적 id (얻은 순서).
  final List<String> ownedPirates;

  /// 스테이지 id(예: `1-5`) → 별 수 0~3. 클리어한 스테이지만 들어 있다.
  final Map<String, int> stars;

  final bool prologueSeen;

  /// 끝낸 튜토리얼 판 수 0~[tutorialMatches].
  final int tutorialDone;

  /// 지금까지 한 판 수(튜토리얼 포함).
  final int matchesPlayed;

  /// 본 컷신 id (설계서 §15.4). 캠페인 지도에서 다시 볼 수 있다.
  final List<String> seenStories;

  /// 배 업그레이드 (설계서 §3.1·§3.3·§13.6).
  final ShipUpgrades ship;

  /// 다음 레벨까지 필요한 경험치 (수치: BALANCE.md A4.5).
  int get xpToNext => xpToNextFor(level);

  static int xpToNextFor(int level) => 100 * level;

  /// 출전 코스트 한도 (설계서 §4.5).
  int get costLimit => costLimitForLevel(level);

  bool get tutorialFinished => tutorialDone >= tutorialMatches;

  /// 조선소 해금 (설계서 §13.1): 4판째부터.
  bool get shipyardUnlocked => matchesPlayed >= shipyardUnlockMatch - 1;

  bool hasCleared(String stageId) => stars.containsKey(stageId);

  int starsOf(String stageId) => stars[stageId] ?? 0;

  /// 경험치를 더하고 레벨업을 처리한다. 최고 레벨이면 경험치는 그대로 쌓인다.
  PlayerProgress addXp(int amount) {
    var lv = level;
    var pool = xp + amount;
    while (lv < maxLevel && pool >= xpToNextFor(lv)) {
      pool -= xpToNextFor(lv);
      lv++;
    }
    return copyWith(level: lv, xp: pool);
  }

  PlayerProgress addGold(int amount) => copyWith(gold: gold + amount);

  /// 해적을 얻는다. 이미 있으면 그대로(중복 카드는 R4 성장에서 다룬다).
  PlayerProgress addPirate(String id) => ownedPirates.contains(id)
      ? this
      : copyWith(ownedPirates: [...ownedPirates, id]);

  /// 스테이지 결과를 남긴다. 별은 지금까지의 최고치를 유지한다.
  PlayerProgress recordStage(String stageId, int newStars) {
    final best = newStars.clamp(0, 3);
    if ((stars[stageId] ?? -1) >= best) return this;
    return copyWith(stars: {...stars, stageId: best});
  }

  PlayerProgress countMatch() => copyWith(matchesPlayed: matchesPlayed + 1);

  PlayerProgress finishTutorial(int step) => step <= tutorialDone
      ? this
      : copyWith(tutorialDone: step.clamp(0, tutorialMatches));

  PlayerProgress seePrologue() => copyWith(prologueSeen: true);

  bool hasSeen(String storyId) => seenStories.contains(storyId);

  PlayerProgress seeStory(String storyId) => hasSeen(storyId)
      ? this
      : copyWith(seenStories: [...seenStories, storyId]);

  PlayerProgress copyWith({
    int? level,
    int? xp,
    int? gold,
    List<String>? ownedPirates,
    Map<String, int>? stars,
    bool? prologueSeen,
    int? tutorialDone,
    int? matchesPlayed,
    List<String>? seenStories,
    ShipUpgrades? ship,
  }) => PlayerProgress(
    level: level ?? this.level,
    xp: xp ?? this.xp,
    gold: gold ?? this.gold,
    ownedPirates: ownedPirates ?? this.ownedPirates,
    stars: stars ?? this.stars,
    prologueSeen: prologueSeen ?? this.prologueSeen,
    tutorialDone: tutorialDone ?? this.tutorialDone,
    matchesPlayed: matchesPlayed ?? this.matchesPlayed,
    seenStories: seenStories ?? this.seenStories,
    ship: ship ?? this.ship,
  );

  Map<String, Object?> toJson() => {
    'level': level,
    'xp': xp,
    'gold': gold,
    'ownedPirates': ownedPirates,
    'stars': stars,
    'prologueSeen': prologueSeen,
    'tutorialDone': tutorialDone,
    'matchesPlayed': matchesPlayed,
    'seenStories': seenStories,
    'ship': ship.toJson(),
  };

  String encode() => jsonEncode(toJson());
}
