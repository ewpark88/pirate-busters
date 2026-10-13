/// AI 난이도 (설계서 §5.2). 순서는 쉬움 → 지옥.
enum AiLevel { easy, normal, hard, hell }

/// 난이도별 AI 다이얼 (BALANCE.md A5.2·A5.5). 각도는 밀리도, 비율은 %.
class AiDials {
  const AiDials({
    required this.angleErrorMdeg,
    required this.thinkMs,
    required this.pickTopPercent,
    required this.waveTiming,
    required this.positions,
    required this.windCorrectionPercent,
    required this.waveZones,
    this.goalMoves = false,
    this.stepCells = positionStepCells,
  });

  /// BALANCE.md A5.2·A5.5 표.
  factory AiDials.of(AiLevel level) => switch (level) {
    AiLevel.easy => const AiDials(
      angleErrorMdeg: 8000,
      thinkMs: 2500,
      pickTopPercent: 50,
      waveTiming: false,
      positions: 0,
      windCorrectionPercent: 50,
      waveZones: false,
    ),
    AiLevel.normal => const AiDials(
      angleErrorMdeg: 4000,
      thinkMs: 1500,
      pickTopPercent: 20,
      waveTiming: false,
      positions: 3,
      windCorrectionPercent: 75,
      waveZones: false,
    ),
    AiLevel.hard => const AiDials(
      angleErrorMdeg: 2000,
      thinkMs: 800,
      pickTopPercent: 5,
      waveTiming: true,
      positions: 5,
      windCorrectionPercent: 95,
      waveZones: true,
    ),
    AiLevel.hell => const AiDials(
      angleErrorMdeg: 500,
      thinkMs: 300,
      pickTopPercent: 0,
      waveTiming: true,
      positions: 7,
      windCorrectionPercent: 100,
      waveZones: true,
    ),
  };

  /// 원격 값 `ai_<난이도>_<다이얼>` 로 [level] 표를 덮어쓴 다이얼 (설계서 §7.4,
  /// 개발 계획서 A9). bool 은 0/1 이다. 범위 밖 값은 무시한다.
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
    return base.copyWith(
      angleErrorMdeg: at('angleErrorMdeg', max: 90000),
      thinkMs: at('thinkMs', max: 20000),
      pickTopPercent: at('pickTopPercent', max: 100),
      waveTiming: flag('waveTiming'),
      positions: at('positions', max: 15),
      windCorrectionPercent: at('windCorrectionPercent', max: 100),
      waveZones: flag('waveZones'),
    );
  }

  /// 일부 다이얼만 바꾼 값.
  AiDials copyWith({
    int? angleErrorMdeg,
    int? thinkMs,
    int? pickTopPercent,
    bool? waveTiming,
    int? positions,
    int? windCorrectionPercent,
    bool? waveZones,
    bool? goalMoves,
    int? stepCells,
  }) => AiDials(
    angleErrorMdeg: angleErrorMdeg ?? this.angleErrorMdeg,
    thinkMs: thinkMs ?? this.thinkMs,
    pickTopPercent: pickTopPercent ?? this.pickTopPercent,
    waveTiming: waveTiming ?? this.waveTiming,
    positions: positions ?? this.positions,
    windCorrectionPercent: windCorrectionPercent ?? this.windCorrectionPercent,
    waveZones: waveZones ?? this.waveZones,
    goalMoves: goalMoves ?? this.goalMoves,
    stepCells: stepCells ?? this.stepCells,
  );

  /// 쏠 때 섞는 각도 오차(±).
  final int angleErrorMdeg;

  /// 생각 연출 시간: 해적을 고르고 당기는 조준 동작을 보여주는 시간.
  final int thinkMs;

  /// 후보 선택: 점수 상위 [pickTopPercent]% 안에서 무작위. 0 이면 최상만.
  final int pickTopPercent;

  /// 파도 타이밍을 계산해 쏘는 순간을 고르는가.
  final bool waveTiming;

  /// 위치 후보 수(0 이면 이동하지 않는다). 간격은 [stepCells] 칸.
  final int positions;

  /// 바람을 얼마나 계산에 넣는가.
  final int windCorrectionPercent;

  /// 위치를 고를 때 파도 구간 세기를 보는가 (BALANCE.md A5.5 파도 구간 고려).
  final bool waveZones;

  /// 실험: 위치 후보에 이동 목표(가장 잔잔한 구간, `MoveGoal`)를 하나 더 넣는다.
  /// BALANCE.md A5.5 에 없는 값이라 기본은 끈다(S5 제안서에서 잰다).
  final bool goalMoves;

  /// 위치 후보 간격(칸). 기본은 BALANCE.md A5.5 의 [positionStepCells]. S5 제안서의
  /// 실험에서만 바꾼다.
  final int stepCells;

  /// 위치 후보 간격 (BALANCE.md A5.5).
  static const int positionStepCells = 1;

  /// 위치의 파도 세기 1당 빼는 점수 (BALANCE.md A5.5).
  static const int wavePenaltyPerLevel = 20;

  /// 연패 보정: 3연패마다 각도 오차 +1°, 최대 +3° (BALANCE.md A5.2).
  static int streakBonusMdeg(int losses) {
    final steps = losses ~/ 3;
    return (steps > 3 ? 3 : steps) * 1000;
  }
}

/// AI 성격 (설계서 §5.3). 착탄 가치 점수에 곱하는 배율(%)과 위치 점수
/// (BALANCE.md A5.3). 순서는 저장·데이터 이름에 쓰이므로 새 값은 뒤에 붙인다.
enum Personality {
  /// 포격형: 블록과 선장실.
  bombard(block: 150, pirate: 80, captain: 150),

  /// 사냥형: 해적.
  hunter(block: 70, pirate: 150, captain: 80),

  /// 밀치기형: 충격탄으로 상대를 거친 구간에 넣고 자기는 잔잔한 구간에 선다.
  shover(block: 100, pirate: 100, captain: 100, pushRough: 80, calmStand: 40),

  /// 돌격형: 상대 가까이 다가간다.
  rusher(block: 100, pirate: 120, captain: 100, rush: 30);

  const Personality({
    required this.block,
    required this.pirate,
    required this.captain,
    this.rush = 0,
    this.pushRough = 0,
    this.calmStand = 0,
  });

  final int block;
  final int pirate;
  final int captain;

  /// 돌격형: 상대와 간격 [rushGapCells] 칸 이내 위치에 더하는 점수.
  final int rush;

  /// 밀치기형: 이번 발이 상대를 거친 구간(세기 3)으로 밀면 더하는 점수.
  final int pushRough;

  /// 밀치기형: 내가 잔잔한 구간(세기 0)에 서면 더하는 점수.
  final int calmStand;

  /// 돌격형이 노리는 간격 (BALANCE.md A5.3).
  static const int rushGapCells = 8;
}
