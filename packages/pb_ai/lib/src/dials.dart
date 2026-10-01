/// AI 난이도 (설계서 §5.2). 순서는 쉬움 → 지옥.
enum AiLevel { easy, normal, hard, hell }

/// 지원 해적을 언제 쓰는가 (BALANCE.md A5.2).
enum SupportUse {
  /// 쓰지 않는다.
  never,

  /// 내 침수량이 50% 이상일 때부터.
  fromHalfFlood,

  /// 고칠 구멍이 있으면 바로.
  timely,
}

/// 난이도별 AI 다이얼 (BALANCE.md A5.2·A5.5). 각도는 밀리도, 비율은 %.
class AiDials {
  const AiDials({
    required this.angleErrorMdeg,
    required this.thinkMs,
    required this.pickTopPercent,
    required this.waveTiming,
    required this.support,
    required this.positions,
    required this.combo,
    required this.windCorrectionPercent,
    required this.timeMode,
  });

  /// BALANCE.md A5.2·A5.5 표.
  factory AiDials.of(AiLevel level) => switch (level) {
    AiLevel.easy => const AiDials(
      angleErrorMdeg: 8000,
      thinkMs: 2500,
      pickTopPercent: 50,
      waveTiming: false,
      support: SupportUse.never,
      positions: 0,
      combo: false,
      windCorrectionPercent: 50,
      timeMode: false,
    ),
    AiLevel.normal => const AiDials(
      angleErrorMdeg: 4000,
      thinkMs: 1500,
      pickTopPercent: 20,
      waveTiming: false,
      support: SupportUse.timely,
      positions: 3,
      combo: false,
      windCorrectionPercent: 75,
      timeMode: false,
    ),
    AiLevel.hard => const AiDials(
      angleErrorMdeg: 2000,
      thinkMs: 800,
      pickTopPercent: 5,
      waveTiming: true,
      support: SupportUse.timely,
      positions: 5,
      combo: true,
      windCorrectionPercent: 95,
      timeMode: true,
    ),
    AiLevel.hell => const AiDials(
      angleErrorMdeg: 500,
      thinkMs: 300,
      pickTopPercent: 0,
      waveTiming: true,
      support: SupportUse.timely,
      positions: 7,
      combo: true,
      windCorrectionPercent: 100,
      timeMode: true,
    ),
  };

  /// 원격 값 `ai_<난이도>_<다이얼>` 로 [level] 표를 덮어쓴 다이얼 (설계서 §7.4,
  /// 개발 계획서 A9). bool 은 0/1, `support` 는 [SupportUse] 순번이다. 범위 밖 값은
  /// 무시한다.
  factory AiDials.withOverrides(AiLevel level, int? Function(String) intOr) {
    final base = AiDials.of(level);
    int? at(String name, {int min = 0, int max = 1 << 30}) {
      final v = intOr('ai_${level.name}_$name');
      return v == null || v < min || v > max ? null : v;
    }

    bool? flag(String name) => switch (at(name, max: 1)) {
      0 => false,
      1 => true,
      _ => null,
    };
    final support = at('support', max: SupportUse.values.length - 1);
    return base.copyWith(
      angleErrorMdeg: at('angleErrorMdeg', max: 90000),
      thinkMs: at('thinkMs', max: 25000),
      pickTopPercent: at('pickTopPercent', max: 100),
      waveTiming: flag('waveTiming'),
      support: support == null ? null : SupportUse.values[support],
      positions: at('positions', max: 15),
      combo: flag('combo'),
      windCorrectionPercent: at('windCorrectionPercent', max: 100),
      timeMode: flag('timeMode'),
    );
  }

  /// 일부 다이얼만 바꾼 값.
  AiDials copyWith({
    int? angleErrorMdeg,
    int? thinkMs,
    int? pickTopPercent,
    bool? waveTiming,
    SupportUse? support,
    int? positions,
    bool? combo,
    int? windCorrectionPercent,
    bool? timeMode,
  }) => AiDials(
    angleErrorMdeg: angleErrorMdeg ?? this.angleErrorMdeg,
    thinkMs: thinkMs ?? this.thinkMs,
    pickTopPercent: pickTopPercent ?? this.pickTopPercent,
    waveTiming: waveTiming ?? this.waveTiming,
    support: support ?? this.support,
    positions: positions ?? this.positions,
    combo: combo ?? this.combo,
    windCorrectionPercent: windCorrectionPercent ?? this.windCorrectionPercent,
    timeMode: timeMode ?? this.timeMode,
  );

  /// 쏠 때 섞는 각도 오차(±).
  final int angleErrorMdeg;

  /// 생각 연출 시간: 해적을 고르고 당기는 조준 동작을 보여주는 시간.
  final int thinkMs;

  /// 후보 선택: 점수 상위 [pickTopPercent]% 안에서 무작위. 0 이면 최상만.
  final int pickTopPercent;

  /// 파도 타이밍을 계산해 쏘는 순간을 고르는가.
  final bool waveTiming;

  final SupportUse support;

  /// 위치 후보 수(0 이면 이동하지 않는다). 간격은 [positionStepCells] 칸.
  final int positions;

  /// 2발 콤보를 계획하는가(첫 발이 부순 칸 옆을 두 번째 발로).
  final bool combo;

  /// 바람을 얼마나 계산에 넣는가.
  final int windCorrectionPercent;

  /// 시간 판정 모드를 쓰는가([timeModeTurn] 턴부터).
  final bool timeMode;

  /// 위치 후보 간격 (BALANCE.md A5.5).
  static const int positionStepCells = 2;

  /// 시간 판정 모드 시작 턴 (BALANCE.md A5.5).
  static const int timeModeTurn = 22;

  /// 어려움 이상이 남겨 두는 연료 (BALANCE.md A5.5).
  static const int fuelReserve = 40;

  /// 연패 보정: 3연패마다 각도 오차 +1°, 최대 +3° (BALANCE.md A5.2).
  static int streakBonusMdeg(int losses) {
    final steps = losses ~/ 3;
    return (steps > 3 ? 3 : steps) * 1000;
  }
}

/// AI 성격 (설계서 §5.3). 착탄 가치 점수에 곱하는 배율(%) (BALANCE.md A5.3).
enum Personality {
  bombard(block: 150, pirate: 80, flood: 100, module: 120, rush: 0),
  hunter(block: 70, pirate: 150, flood: 80, module: 80, rush: 0),
  sinker(block: 80, pirate: 70, flood: 200, module: 100, rush: 0),
  rusher(block: 100, pirate: 120, flood: 100, module: 100, rush: 30);

  const Personality({
    required this.block,
    required this.pirate,
    required this.flood,
    required this.module,
    required this.rush,
  });

  final int block;
  final int pirate;
  final int flood;
  final int module;

  /// 돌격형: 짧은 사거리 해적이 닿는 위치에 1명당 더하는 점수.
  final int rush;
}
