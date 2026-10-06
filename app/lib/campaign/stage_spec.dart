import 'package:pb_ai/pb_ai.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';

/// 스테이지 종류 (설계서 §6.1, §13.1).
enum StageKind {
  /// 튜토리얼 전투 (§13.1). 캠페인 지도에는 없다.
  tutorial,
  normal,
  midBoss,
  boss;

  static StageKind parse(String name, String path) => values.firstWhere(
    (k) => k.name == name,
    orElse: () => throw DataFormatError(path, '모르는 종류 $name'),
  );
}

/// 별 3개째 미션 (설계서 §6.1). [type] 마다 [params] 가 다르다. 글자는 ARB
/// `mission_<type>` 키에 있다(§14.3).
class MissionSpec {
  const MissionSpec({required this.type, required this.params});

  factory MissionSpec.fromJson(JsonReader r) {
    final type = r.string('type');
    if (!knownTypes.contains(type)) {
      throw DataFormatError('${r.path}.type', '모르는 미션 $type');
    }
    return MissionSpec(
      type: type,
      params: {
        for (final key in r.keys)
          if (key != 'type') key: r.integer(key),
      },
    );
  }

  /// MVP 미션 5종. 판정은 `StarRules`.
  static const Set<String> knownTypes = {
    'no_pirate_down',
    'flood_below',
    'hull_above',
    'win_by_sink',
    'turns_within',
  };

  final String type;

  /// 정수 파라미터 (`percent`, `turns`).
  final Map<String, int> params;

  int param(String key) =>
      params[key] ?? (throw ArgumentError('미션 $type: $key 없음'));

  /// ARB 키.
  String get textKey => 'mission_$type';
}

/// 스테이지 한 판 (설계서 §6.1 캠페인, mozzi `stage_table` 구조). JSON 은
/// `assets/stages/sea<n>.json`. 대사는 키만 둔다(§15.4).
class StageSpec {
  const StageSpec({
    required this.id,
    required this.sea,
    required this.number,
    required this.kind,
    required this.enemyPreset,
    required this.enemyDeck,
    required this.aiLevel,
    required this.personality,
    required this.waveLevel,
    required this.maxWind,
    required this.starTurns,
    required this.mission,
    required this.dialogueKeys,
    required this.rewardGold,
    required this.rewardPirate,
    required this.tutorialStep,
    this.gimmick,
    this.enemyStage = HullSpec.maxStage,
    this.enemyMastLevel = 1,
  });

  factory StageSpec.fromJson(JsonReader r, {required int sea}) {
    final id = r.string('id');
    final kind = StageKind.parse(r.string('kind'), '${r.path}.kind');
    final parts = id.split('-');
    final number = parts.length == 2 ? int.tryParse(parts[1]) : null;
    final prefix = kind == StageKind.tutorial ? 't' : '$sea';
    if (number == null || parts[0] != prefix) {
      throw DataFormatError('${r.path}.id', '"$id" 가 해역 $sea 와 맞지 않는다');
    }
    final reward = r.objectOr('reward');
    return StageSpec(
      id: id,
      sea: sea,
      number: number,
      kind: kind,
      enemyPreset: r.string('enemyPreset'),
      enemyDeck: r.stringList('enemyDeck'),
      aiLevel: _enumOf(
        AiLevel.values,
        r.string('aiLevel'),
        '${r.path}.aiLevel',
      ),
      personality: _enumOf(
        Personality.values,
        r.string('personality'),
        '${r.path}.personality',
      ),
      waveLevel: r.integerOr('waveLevel', 1),
      maxWind: r.integerOr('maxWind', 3),
      starTurns: r.integer('starTurns'),
      mission: MissionSpec.fromJson(r.object('mission')),
      dialogueKeys: r.stringList('dialogueKeys'),
      rewardGold: reward.integerOr('gold', 0),
      rewardPirate: reward.stringOrNull('pirate'),
      tutorialStep: r.integerOr('tutorialStep', 0),
      gimmick: r.stringOrNull('gimmick'),
      enemyStage: r.integerOr('enemyStage', HullSpec.maxStage),
      enemyMastLevel: r.integerOr('enemyMastLevel', 1),
    );
  }

  static T _enumOf<T extends Enum>(List<T> values, String name, String path) =>
      values.firstWhere(
        (v) => v.name == name,
        orElse: () => throw DataFormatError(path, '모르는 값 $name'),
      );

  /// `1-5` 형식. 튜토리얼은 `t-1`.
  final String id;
  final int sea;
  final int number;
  final StageKind kind;

  /// 적 설계도(추천 설계도 id)와 덱.
  final String enemyPreset;

  /// 적 배 확장 단계(설계서 §3.1, BALANCE.md A3.1)와 돛대 레벨(A3.2).
  final int enemyStage;
  final int enemyMastLevel;
  final List<String> enemyDeck;
  final AiLevel aiLevel;
  final Personality personality;

  /// 파도 세기와 바람 최대 단계 (설계서 §2.1 스테이지 파라미터).
  final int waveLevel;
  final int maxWind;

  /// 별 2개째: 이 턴 수 이내 승리 (BALANCE.md A6.1).
  final int starTurns;

  /// 별 3개째 미션.
  final MissionSpec mission;

  /// 전투 준비 화면 대사 키 (§15.4).
  final List<String> dialogueKeys;

  final int rewardGold;

  /// 확정 보상 해적 id (§4.6). 없으면 null.
  final String? rewardPirate;

  /// 튜토리얼 판 번호 1~3 (§13.1). 캠페인 스테이지는 0.
  final int tutorialStep;

  /// 보스 기믹 id (§5.4). 글자는 ARB `gimmick_<id>`, 판정은 `BossGimmick`(해역 1 은 A29).
  final String? gimmick;

  bool get isBoss => kind == StageKind.boss || kind == StageKind.midBoss;

  /// 원격 설정으로 바꿀 수 있는 값만 바꾼 스테이지 (설계서 §7.4 `campaign_*`).
  StageSpec copyWith({
    AiLevel? aiLevel,
    int? waveLevel,
    int? maxWind,
    int? starTurns,
    int? rewardGold,
  }) => StageSpec(
    id: id,
    sea: sea,
    number: number,
    kind: kind,
    enemyPreset: enemyPreset,
    enemyDeck: enemyDeck,
    enemyStage: enemyStage,
    enemyMastLevel: enemyMastLevel,
    aiLevel: aiLevel ?? this.aiLevel,
    personality: personality,
    waveLevel: waveLevel ?? this.waveLevel,
    maxWind: maxWind ?? this.maxWind,
    starTurns: starTurns ?? this.starTurns,
    mission: mission,
    dialogueKeys: dialogueKeys,
    rewardGold: rewardGold ?? this.rewardGold,
    rewardPirate: rewardPirate,
    tutorialStep: tutorialStep,
    gimmick: gimmick,
  );
}

/// 해역 하나의 스테이지 목록.
class SeaSpec {
  const SeaSpec({required this.sea, required this.stages});

  factory SeaSpec.fromJson(Object? json) {
    final r = JsonReader(json);
    final sea = r.integer('sea');
    final stages = [
      for (final (i, s) in r.list('stages').indexed)
        StageSpec.fromJson(
          JsonReader(
            s,
            path:
                r'$.stages'
                '[$i]',
          ),
          sea: sea,
        ),
    ];
    final ids = stages.map((s) => s.id).toSet();
    if (ids.length != stages.length) {
      throw const DataFormatError(r'$.stages', '스테이지 id 가 겹친다');
    }
    return SeaSpec(sea: sea, stages: stages);
  }

  final int sea;
  final List<StageSpec> stages;

  /// 캠페인 지도에 나오는 스테이지(튜토리얼 제외), 번호 순.
  List<StageSpec> get campaign =>
      stages.where((s) => s.kind != StageKind.tutorial).toList()
        ..sort((a, b) => a.number - b.number);

  List<StageSpec> get tutorial =>
      stages.where((s) => s.kind == StageKind.tutorial).toList()
        ..sort((a, b) => a.tutorialStep - b.tutorialStep);

  StageSpec byId(String id) => stages.firstWhere(
    (s) => s.id == id,
    orElse: () => throw ArgumentError('스테이지 없음: $id'),
  );

  /// 데이터가 게임 데이터와 맞는지 검사한다. 문제가 없으면 빈 목록(개발자용 메시지).
  List<String> problems({
    required bool Function(String pirateId) hasPirate,
    required bool Function(String presetId, int stage) hasPreset,
  }) => [
    for (final s in stages) ...[
      if (!hasPreset(s.enemyPreset, s.enemyStage))
        '${s.id}: unknown preset ${s.enemyPreset} stage ${s.enemyStage}',
      for (final p in s.enemyDeck)
        if (!hasPirate(p)) '${s.id}: unknown enemy pirate $p',
      if (s.rewardPirate != null && !hasPirate(s.rewardPirate!))
        '${s.id}: unknown reward pirate ${s.rewardPirate}',
      if (s.enemyDeck.isEmpty) '${s.id}: empty enemy deck',
      if (s.enemyDeck.length >
          HullSpec.byId('sloop', stage: s.enemyStage).cabinSlots)
        '${s.id}: enemy deck larger than stage ${s.enemyStage} cabins',
      if (s.kind == StageKind.tutorial &&
          (s.tutorialStep < 1 || s.tutorialStep > 3))
        '${s.id}: tutorial step ${s.tutorialStep} out of range',
    ],
    if (!stages.any((s) => s.kind == StageKind.boss)) 'no boss stage',
  ];
}
