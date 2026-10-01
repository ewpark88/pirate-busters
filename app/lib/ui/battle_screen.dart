import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/battle/battle_stats.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/input/field_gestures.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/platform/remote_values.dart';
import 'package:pirate_busters/ui/hud/battle_hud.dart';

/// 전투 화면: 전장(Flame) 위에 HUD(Flutter 위젯)를 겹친다 (설계서 §13.4).
/// 전장의 게임 루프가 매 프레임 [BattleSession] 을 진행한다.
class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({
    super.key,
    this.seed = 20260930,
    this.hotseat = false,
    this.level = AiLevel.normal,
    this.stage,
    this.onOver,
  });

  final int seed;

  /// 캠페인 스테이지 (설계서 §6.1). 있으면 적 설계도·덱·난이도·성격·파도·바람을 여기서 쓴다.
  final StageSpec? stage;

  /// 판이 끝났을 때 한 번 부른다(결과 화면, 보상). 없으면 간이 결과 창만 띄운다.
  final void Function(MatchState state, Replay? replay, BattleStats stats)?
  onOver;

  /// AI 상대 난이도 (설계서 §5.2).
  final AiLevel level;

  /// 한 기기에서 두 사람이 번갈아 둔다(개발용, ADR-029).
  final bool hotseat;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  late BattleSession _session;
  late BattleGame _game;
  bool _paused = false;
  bool _reported = false;
  PreparedMatch? _prepared;

  @override
  void initState() {
    super.initState();
    _start(widget.seed, hotseat: widget.hotseat);
  }

  void _start(int seed, {required bool hotseat}) {
    final catalog = ref.read(gameCatalogProvider);
    final fleet = ref.read(fleetStoreProvider);
    final stage = widget.stage;
    final setup = BattleSetup(catalog);
    final blueprint = fleet.blueprint(fleet.activeSlot);
    final remote = ref.read(remoteValuesProvider);
    _prepared = stage == null
        ? null
        : setup.prepareStage(
            seed,
            stage,
            blueprint: blueprint,
            deck: fleet.deck,
            costLimit: ref.read(progressProvider).costLimit,
            tune: (r) => applyRemoteRules(r, remote),
          );
    _session = BattleSession(
      _prepared?.match ??
          setup.newMatchFor(seed, blueprint: blueprint, deck: fleet.deck),
      humanSides: hotseat ? const {0, 1} : const {0},
      speciesOf: catalog.speciesOf,
      opponent: hotseat
          ? null
          : AiController(
              level: stage?.aiLevel ?? widget.level,
              personality:
                  stage?.personality ??
                  Personality.values[seed % Personality.values.length],
            ),
    );
    _reported = false;
    _session.addListener(_checkOver);
    final analytics = ref.read(analyticsProvider);
    _game = BattleGame(_session, sound: ref.read(soundServiceProvider));
    _game.onTurnEnd = (e) {
      if (!_session.humanSides.contains(e.side)) return;
      analytics.log(Events.turnEnd, {
        'turn': e.value,
        'reason': e.cell,
        'ms': _session.turnMs,
        'shots': _game.stats.shots[e.side],
      });
    };
  }

  void _checkOver() {
    if (_reported || !_session.isOver) return;
    _reported = true;
    widget.onOver?.call(_session.state, _prepared?.replay(), _game.stats);
  }

  void _restart({bool? hotseat}) {
    final old = _session;
    setState(() {
      _paused = false;
      _start(
        old.state.seed + 1,
        hotseat: hotseat ?? old.humanSides.length == 2,
      );
    });
    old.dispose();
  }

  void _pause(bool paused) {
    // 일시정지는 AI 전에서만 쓴다 (설계서 §13.4).
    setState(() => _paused = paused);
    // 핫시트는 두 사람이 함께 두므로 창을 열어도 턴 시계를 멈추지 않는다.
    _game.paused = paused && _session.humanSides.length < 2;
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 저사양 모드는 설정에서 바로 전장에 반영한다.
    _game.lowEnd.value = ref.watch(lowEndProvider);
    _session.autoEnd.enabled = ref.watch(autoEndTurnProvider);
    final l10n = AppLocalizations.of(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    _game.damageText = (amount) => l10n.damagePopup(number.format(amount));
    return _scaffold();
  }

  /// 튜토리얼 판이면 안내 한 줄 (설계서 §13.1).
  String? _hint(AppLocalizations l10n) {
    final step = widget.stage?.tutorialStep ?? 0;
    return step == 0 ? null : dataText(l10n, 'tutorial_hint_$step');
  }

  Widget _scaffold() => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        Positioned.fill(
          child: FieldGestures(
            game: _game,
            session: _session,
            child: GameWidget(key: ObjectKey(_game), game: _game),
          ),
        ),
        Positioned.fill(
          child: BattleHud(
            session: _session,
            overview: _game.overview,
            paused: _paused,
            onPause: _pause,
            onRestart: _restart,
            hint: _hint(AppLocalizations.of(context)),
          ),
        ),
      ],
    ),
  );
}
