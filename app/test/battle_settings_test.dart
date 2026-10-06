import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_stats.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/sea_view.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/ui/hud/hud_gauge.dart';
import 'package:pirate_busters/ui/hud/move_controls.dart';

import 'test_catalog.dart';

BattleSession _session(int seed) => BattleSession(
  testSetup.newMatch(seed),
  humanSides: const {0},
  speciesOf: testCatalog.speciesOf,
  opponent: const AiController(level: AiLevel.easy),
);

void main() {
  group('설정의 효과음·진동이 전투에 반영된다 (설계서 §13.8)', () {
    test('효과음을 끄면 전장이 소리를 내지 않고, 켜면 낸다', () {
      final session = _session(1);
      final sound = _RecordingSound();
      final game = BattleGame(session, sound: sound);
      game.soundOn.value = false;
      game.playSfx(Sfx.cannon);
      expect(sound.played, isEmpty);
      game.soundOn.value = true;
      game.playSfx(Sfx.wood, volume: 0.5);
      expect(sound.played, [Sfx.wood]);
      session.dispose();
    });

    testWidgets('진동을 끄면 착탄 햅틱을 부르지 않고, 켜면 한 착탄에 한 번만 운다', (tester) async {
      var vibrations = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') vibrations++;
          return null;
        },
      );
      final sprites = await _FakeSprites.make();
      final vibration = ValueNotifier(false);
      const weight = HitWeight(500);
      FxLayer(sprites: sprites, vibration: vibration)
        ..splash(Vector2.zero())
        ..explosion(Vector2.zero())
        ..jolt(weight);
      await tester.pump();
      expect(vibrations, 0);
      vibration.value = true;
      FxLayer(sprites: sprites, vibration: vibration)
        ..explosion(Vector2.zero())
        ..splash(Vector2.zero())
        ..jolt(weight);
      await tester.pump();
      expect(vibrations, 1, reason: '폭발·물보라 그림은 진동을 따로 내지 않는다');
    });
  });

  testWidgets('연료 게이지 상한은 pb_sim 의 탱크이고 1 을 넘지 않는다 (설계서 §2.7)', (
    tester,
  ) async {
    final session = BattleSession(
      testSetup.newMatch(3),
      humanSides: const {0, 1},
      speciesOf: testCatalog.speciesOf,
    );
    final me = session.state.sides[0];
    Future<double?> gauge() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
          ],
          child: MaterialApp(
            supportedLocales: supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: MoveControls(session: session, side: 0)),
          ),
        ),
      );
      await tester.pump();
      return tester.widget<HudGauge>(find.byType(HudGauge)).value;
    }

    // 연료가 탱크를 넘는 상태(연료통이 부서지기 직전 등)에서도 게이지는 가득 찬 것으로.
    me.fuel = me.tank + SideState.fuelUnit;
    expect(await gauge(), 1.0);
    me.fuel = me.tank ~/ 2;
    expect(await gauge(), closeTo(0.5, 0.01));
    session.dispose();
  });

  test('무승부는 pb_sim 의 winner 로 판정한다 (설계서 §2.4, §13.5)', () {
    final state = testSetup.newMatch(4).state
      ..outcome = MatchOutcome.timeDecision
      ..winner = -1;
    final draw = MatchSummary.fromState(state, 0);
    expect(draw.draw, isTrue);
    expect(draw.won, isFalse);
    state.winner = 0;
    final won = MatchSummary.fromState(state, 0);
    expect(won.draw, isFalse);
    expect(won.won, isTrue);
    // 양쪽이 같은 턴에 격침돼도 무승부다(판정은 pb_sim judge).
    state
      ..outcome = MatchOutcome.sunk
      ..winner = -1;
    expect(MatchSummary.fromState(state, 1).draw, isTrue);
  });

  test('저사양 모드에서는 바다 포말이 절반이다 (설계서 §12)', () {
    final lowEnd = ValueNotifier(false);
    final sea = SeaView(
      front: true,
      theme: SeaTheme.tropicalDay,
      lowEnd: lowEnd,
    )..update(0.1);
    expect(sea.foamCount, 140);
    lowEnd.value = true;
    final low = SeaView(
      front: true,
      theme: SeaTheme.tropicalDay,
      lowEnd: lowEnd,
    )..update(0.1);
    expect(low.foamCount, 70);
  });

  test('전투 통계가 턴마다 움직인 거리를 모아 turn_end 에 넘긴다 (계획서 M7)', () {
    final stats = BattleStats()
      ..record(const SimEvent(SimEventKind.move, side: 0, value: 1500))
      ..record(const SimEvent(SimEventKind.move, side: 0, value: -500))
      ..record(const SimEvent(SimEventKind.move, side: 1, value: 300));
    expect(stats.lastTurnMoved, [0, 0]);
    stats.record(const SimEvent(SimEventKind.turnEnd, side: 0, value: 1));
    expect(stats.lastTurnMoved, [2000, 0]);
    // 다음 턴은 0 부터 다시 센다.
    stats
      ..record(const SimEvent(SimEventKind.move, side: 0, value: 100))
      ..record(const SimEvent(SimEventKind.turnEnd, side: 0, value: 3));
    expect(stats.lastTurnMoved[0], 100);
  });
}

class _RecordingSound implements SoundService {
  final List<Sfx> played = [];

  @override
  Future<void> load(Map<Sfx, Uint8List> wavs) async {}

  @override
  void play(Sfx sfx, {double pitch = 1, double volume = 1}) => played.add(sfx);

  @override
  Future<void> loadMusic(Map<Music, Uint8List> wavs) async {}

  @override
  void playMusic(Music? track, {double speed = 1}) {}
}

/// 1×1 그림 하나로 모든 스프라이트를 대신하는 가짜. 진동만 본다.
class _FakeSprites implements BattleSprites {
  _FakeSprites(this._sprite);

  final Sprite _sprite;

  static Future<_FakeSprites> make() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 1, 1),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    final image = await recorder.endRecording().toImage(1, 1);
    return _FakeSprites(Sprite(image));
  }

  @override
  Sprite get(String file) => _sprite;

  @override
  dynamic noSuchMethod(Invocation invocation) => _sprite;
}
