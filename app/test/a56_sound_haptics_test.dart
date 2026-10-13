import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sfx_bank.dart';
import 'package:pirate_busters/audio/sound_library.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/finale_director.dart';
import 'package:pirate_busters/game/hit_stop.dart';
import 'package:pirate_busters/game/impact_sound.dart';
import 'package:pirate_busters/game/sprites.dart';
import 'package:pirate_busters/game/start_gate.dart';
import 'package:pirate_busters/game/view/fx_layer.dart';
import 'package:pirate_busters/game/view/hit_weight.dart';

import 'test_catalog.dart';

class _Sound implements SoundService {
  @override
  void windLevel(int level) {}

  final List<Sfx> played = [];
  final List<bool> ducks = [];
  final List<bool> sea = [];

  @override
  Future<void> load(Map<Sfx, Uint8List> wavs) async {}

  @override
  void play(Sfx sfx, {double pitch = 1, double volume = 1}) => played.add(sfx);

  @override
  Future<void> loadMusic(Map<Music, Uint8List> wavs) async {}

  @override
  void playMusic(Music? track, {double speed = 1}) {}

  @override
  void duck({required bool on}) => ducks.add(on);

  @override
  void ambience({required bool on}) => sea.add(on);
}

class _Sprites implements BattleSprites {
  _Sprites(this._sprite);

  final Sprite _sprite;

  static Future<_Sprites> make() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 1, 1),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    return _Sprites(Sprite(await recorder.endRecording().toImage(1, 1)));
  }

  @override
  Sprite get(String file) => _sprite;

  @override
  dynamic noSuchMethod(Invocation invocation) => _sprite;
}

BattleSession _session() => BattleSession(
  testSetup.newMatch(3),
  humanSides: const {0},
  speciesOf: testCatalog.speciesOf,
  opponent: const AiController(level: AiLevel.easy),
);

void main() {
  group('A56 새 효과음 (설계서 §10.3)', () {
    test('새 소리 다섯 가지가 모두 합성되고, 음원 없이 합성음으로 둔다', () {
      const added = [
        Sfx.dent,
        Sfx.turn,
        Sfx.wake,
        Sfx.star,
        Sfx.levelUp,
      ];
      for (final s in added) {
        expect(SfxBank.wav(s).length, greaterThan(44 + 1000), reason: s.name);
        // S4: 철판 찌그러짐은 CC0 녹음을 골라 음원으로 옮겼다(합성음은 대체용).
        if (s == Sfx.dent) {
          expect(AudioAssets.synthOnly, isNot(contains(s)));
          expect(AudioAssets.variants[s], 3);
        } else {
          expect(AudioAssets.synthOnly, contains(s));
        }
      }
      expect(SfxBank.seaLoop().length, greaterThan(44 + 100000));
    });

    test('철판에 중간 이상 한 방이면 찌그러지는 소리를 겹친다', () {
      List<Sfx> of(int damage, {required bool iron}) => [
        for (final (s, _) in impactLayers(HitWeight(damage), iron: iron)) s,
      ];
      expect(of(500, iron: true), contains(Sfx.dent));
      expect(of(500, iron: false), isNot(contains(Sfx.dent)));
      expect(of(10, iron: true), isNot(contains(Sfx.dent)));
    });
  });

  group('A56 전장 소리·진동 (설계서 §10.3·§10.4)', () {
    testWidgets('턴 전환·이동(간격)에 소리, 사람 발사에 진동, 환경음은 설정을 따른다', (
      tester,
    ) async {
      var vibrations = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') vibrations++;
          return null;
        },
      );
      final sound = _Sound();
      final played = <Sfx>[];
      final soundOn = ValueNotifier(true);
      final session = _session();
      final d = FinaleDirector(
        session: session,
        ships: const [],
        fx: FxLayer(sprites: await _Sprites.make()),
        stop: HitStop(),
        gate: StartGate(),
        settled: ValueNotifier(false),
        playSfx: played.add,
        viewSide: () => 0,
        lowEnd: ValueNotifier(false),
        banner: ValueNotifier(null),
        sound: sound,
        soundOn: soundOn,
      );
      expect(sound.sea, [true], reason: '전장이 열리면 환경음');
      SimEvent ev(SimEventKind k, {int side = 0, int value = 0}) =>
          SimEvent(k, side: side, value: value);
      d.update(.016, [
        ev(SimEventKind.turnStart, value: 2),
        ev(SimEventKind.move),
        ev(SimEventKind.move),
        ev(SimEventKind.fire),
        ev(SimEventKind.fire, side: 1),
      ]);
      await tester.pump();
      expect(played, [Sfx.turn, Sfx.wake]);
      expect(vibrations, 1, reason: '내 발사만 가볍게');
      d.update(FinaleDirector.wakeGapSec, [ev(SimEventKind.move)]);
      expect(played.last, Sfx.wake, reason: '간격이 지나면 다시 물살');
      soundOn.value = false;
      expect(sound.sea.last, isFalse);
      d.dispose();
      expect(sound.sea.last, isFalse);
      session.dispose();
    });
  });

  group('A54·A56 판 끝 순서·턴 멈춤·진동 끄기 (설계서 §10.4, §13.4)', () {
    Future<FinaleDirector> director(
      BattleSession s, {
      ValueNotifier<bool>? settled,
      StartGate? gate,
      ValueNotifier<BattleBanner?>? banner,
      ValueNotifier<bool>? vibration,
    }) async => FinaleDirector(
      session: s,
      ships: const [],
      fx: FxLayer(sprites: await _Sprites.make(), vibration: vibration),
      stop: HitStop(),
      gate: gate ?? StartGate(),
      settled: settled ?? ValueNotifier(false),
      playSfx: (_) {},
      viewSide: () => 0,
      lowEnd: ValueNotifier(false),
      banner: banner ?? ValueNotifier(null),
    );

    testWidgets('판이 끝나면 배너를 먼저 띄우고, 배너 시간이 지난 뒤에야 결과로 넘어간다', (
      tester,
    ) async {
      final s = _session();
      s.state
        ..outcome = MatchOutcome.captainLost
        ..winner = 0;
      final settled = ValueNotifier(false);
      final banner = ValueNotifier<BattleBanner?>(null);
      final d = await director(s, settled: settled, banner: banner);
      d.update(.016, const []);
      expect(banner.value?.kind, BattleBannerKind.captainLost);
      expect(settled.value, isFalse, reason: '배너가 떠 있는 동안');
      d.update(FinaleDirector.endBannerSec / 2, const []);
      expect(settled.value, isFalse);
      d.update(FinaleDirector.endBannerSec, const []);
      expect(settled.value, isTrue, reason: '배너 뒤 결과');
      await tester.pump(const Duration(milliseconds: 300));
      s.dispose();
    });

    testWidgets('턴이 시작되면 판 시계가 0.5초 서고 내 턴 배너가 뜬다', (tester) async {
      final s = _session();
      final gate = StartGate();
      for (var i = 0; i < StartGate.steadyFrames; i++) {
        gate.tick(.016);
      }
      final banner = ValueNotifier<BattleBanner?>(null);
      (await director(s, gate: gate, banner: banner)).update(.016, const [
        SimEvent(SimEventKind.turnStart, side: 0, value: 3),
      ]);
      expect(banner.value?.kind, BattleBannerKind.myTurn);
      expect(gate.tick(.1), isFalse, reason: '멈춤 중');
      expect(gate.tick(.5), isFalse);
      expect(gate.tick(.016), isTrue);
      s.dispose();
    });

    testWidgets('진동을 끄면 발사·판 끝 진동이 울리지 않는다', (tester) async {
      var vibrations = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') vibrations++;
          return null;
        },
      );
      final s = _session();
      final d = await director(s, vibration: ValueNotifier(false));
      d.update(.016, const [SimEvent(SimEventKind.fire, side: 0)]);
      s.state
        ..outcome = MatchOutcome.captainLost
        ..winner = 0;
      d.update(.016, const []);
      await tester.pump(const Duration(milliseconds: 300));
      expect(vibrations, 0);
      s.dispose();
    });
  });
}
