import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/audio/music_director.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/battle/battle_stats.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/dev/practice_bar.dart';
import 'package:pirate_busters/dev/test_battle.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/hit_tag.dart';
import 'package:pirate_busters/input/field_gestures.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/l10n/data_text.dart';
import 'package:pirate_busters/meta/my_ship.dart';
import 'package:pirate_busters/platform/analytics.dart';
import 'package:pirate_busters/platform/remote_values.dart';
import 'package:pirate_busters/ui/hud/battle_hud.dart';
import 'package:pirate_busters/ui/hud/boss_banner.dart';

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
    this.test,
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

  /// 개발용 테스트 대전 (ADR-053). 있으면 고른 덱끼리 코스트 한도 없이 AI 와 붙는다.
  final TestBattle? test;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  late BattleSession _session;
  late BattleGame _game;
  bool _paused = false;
  bool _reported = false;
  PreparedMatch? _prepared;

  /// 테스트 대전 설정. 더미배 연습에서 해적을 바꾸면 새 값이 된다 (ADR-073).
  late TestBattle? _test = widget.test;

  @override
  void initState() {
    super.initState();
    _music = ref.read(musicTrackProvider.notifier);
    _start(widget.seed, hotseat: widget.hotseat);
  }

  void _start(int seed, {required bool hotseat}) {
    final catalog = ref.read(gameCatalogProvider);
    final fleet = ref.read(fleetStoreProvider);
    final stage = widget.stage;
    final setup = BattleSetup(catalog);
    // 캠페인은 지은 확장 단계·레벨의 내 배(설계서 §3.1·§13.6), 둘이서·테스트 대전은
    // 저장한 설계도 그대로.
    final blueprint = stage == null
        ? fleet.blueprint(fleet.activeSlot)
        : myBlueprint(fleet, catalog, ref.read(progressProvider).ship);
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
    final test = _test;
    _session = BattleSession(
      _prepared?.match ??
          test?.start(setup, seed, blueprint: blueprint) ??
          setup.newMatchFor(seed, blueprint: blueprint, deck: fleet.deck),
      humanSides: hotseat ? const {0, 1} : const {0},
      speciesOf: catalog.speciesOf,
      opponent: hotseat
          ? null
          : test?.dummyController ??
                AiController(
                  level: stage?.aiLevel ?? test?.level ?? widget.level,
                  personality:
                      stage?.personality ??
                      Personality.values[seed % Personality.values.length],
                  // AI 다이얼 원격 덮어쓰기 (설계서 §7.4 `ai_*`).
                  dials: AiDials.withOverrides(
                    stage?.aiLevel ?? test?.level ?? widget.level,
                    ref.read(remoteValuesProvider).intOr,
                  ),
                ),
    );
    _reported = false;
    _session
      ..addListener(_checkOver)
      ..addListener(_updateMusic);
    final analytics = ref.read(analyticsProvider);
    _game = BattleGame(_session, sound: ref.read(soundServiceProvider));
    _game.settled.addListener(_checkOver);
    _game.onTurnEnd = (e) {
      if (!_session.humanSides.contains(e.side)) return;
      analytics.log(Events.turnEnd, {
        'turn': e.value,
        'reason': e.cell,
        'ms': _session.turnMs,
        'shots': _game.stats.shots[e.side],
        // 이번 턴에 움직인 거리(칸, 소수). 1/1000칸 단위를 칸으로 바꾼다.
        'moved_cells': _game.stats.lastTurnMoved[e.side] / 1000,
      });
    };
  }

  void _checkOver() {
    // 격침 연출이 끝난 뒤에 결과로 넘어간다 (설계서 §10.4).
    if (_reported || !_session.isOver || !_game.settled.value) return;
    _reported = true;
    // 더미배 연습은 결과 없이 같은 덱으로 다시 시작한다 (ADR-073).
    if (_test?.dummy ?? false) {
      _later(_restart);
      return;
    }
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

  /// 더미배 연습에서 [id] 를 맨 앞에 넣은 새 판 (ADR-073).
  void _practice(String id) {
    _test = _test!.withLead(id);
    _restart();
  }

  /// 세션 알림 도중에 세션을 버리지 않도록 알림이 끝난 뒤로 미룬다.
  void _later(VoidCallback run) => unawaited(
    Future.microtask(() {
      if (mounted) run();
    }),
  );

  void _pause(bool paused) {
    // 일시정지는 AI 전에서만 쓴다 (설계서 §13.4).
    setState(() => _paused = paused);
    // 핫시트는 두 사람이 함께 두므로 창을 열어도 턴 시계를 멈추지 않는다.
    _game.paused = paused && _session.humanSides.length < 2;
  }

  @override
  void dispose() {
    _session.dispose();
    // 전투를 나가면 항구 곡으로 돌아간다(트리 정리 뒤에 바꾼다).
    final music = _music;
    unawaited(Future.microtask(() => music.play(Music.port)));
    super.dispose();
  }

  late final MusicTrackNotifier _music;

  /// 전투 곡, 폭풍 타임에는 빠르게 (설계서 §10.3).
  void _updateMusic() {
    final state = _session.state;
    _music.play(
      Music.battle,
      speed: state.rules.isStorm(state.turn) ? stormMusicSpeed : 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 저사양 모드는 설정에서 바로 전장에 반영한다.
    _game.lowEnd.value = ref.watch(lowEndProvider);
    _game.soundOn.value = ref.watch(soundOnProvider);
    _game.vibrationOn.value = ref.watch(vibrationOnProvider);
    _session.autoEnd.enabled = ref.watch(autoEndTurnProvider);
    final l10n = AppLocalizations.of(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    _game
      ..damageText = ((amount) => l10n.damagePopup(number.format(amount)))
      ..turnsText = number.format
      ..aimAngleText = ((d) => l10n.aimAngle(number.format(d)))
      ..aimPowerText = ((p) => l10n.aimPower(number.format(p)))
      // 명중 이름표 (설계서 §10.4).
      ..tagText = (tag) => switch (tag) {
        HitTag.crit => l10n.hitTagCrit,
        HitTag.pierce => l10n.hitTagPierce,
        HitTag.chain => l10n.hitTagChain,
        HitTag.burn => l10n.hitTagBurn,
        HitTag.mine => l10n.hitTagMine,
        HitTag.bite => l10n.hitTagBite,
        HitTag.repair => l10n.hitTagRepair,
        HitTag.seal => l10n.hitTagSeal,
        HitTag.pull => l10n.hitTagPull,
        HitTag.wind => l10n.hitTagWind,
        HitTag.blind => l10n.hitTagBlind,
        HitTag.bail => l10n.hitTagBail,
        HitTag.boost => l10n.hitTagBoost,
        HitTag.heal => l10n.hitTagHeal,
        HitTag.wall => l10n.hitTagWall,
        HitTag.revive => l10n.hitTagRevive,
        HitTag.intercept => l10n.hitTagIntercept,
      };
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
          child: ValueListenableBuilder<bool>(
            valueListenable: _game.settled,
            builder: (context, settled, _) => BattleHud(
              session: _session,
              overview: _game.overview,
              paused: _paused,
              onPause: _pause,
              onRestart: _restart,
              hint: _hint(AppLocalizations.of(context)),
              settled: settled,
              onClick: () => _game.playSfx(Sfx.click),
            ),
          ),
        ),
        if (widget.stage?.gimmick case final gimmick?)
          BossBanner(gimmick: gimmick),
        if (_test case TestBattle(dummy: true, :final deck))
          PracticeBar(deck: deck, onPick: _practice),
      ],
    ),
  );
}
