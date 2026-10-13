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
    test('새 소리 일곱 가지가 모두 합성되고, 음원 없이 합성음으로 둔다', () {
      const added = [
        Sfx.dent,
        Sfx.turn,
        Sfx.gurgle,
        Sfx.crackle,
        Sfx.wake,
        Sfx.star,
        Sfx.levelUp,
      ];
      for (final s in added) {
        expect(SfxBank.wav(s).length, greaterThan(44 + 1000), reason: s.name);
        expect(AudioAssets.synthOnly, contains(s));
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
    testWidgets('턴 전환·침수·불·이동(간격)에 소리, 사람 발사에 진동, 환경음은 설정을 따른다', (
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
        ev(SimEventKind.flood, value: 15),
        ev(SimEventKind.flood, value: -40),
        ev(SimEventKind.ignited),
        ev(SimEventKind.move),
        ev(SimEventKind.move),
        ev(SimEventKind.fire),
        ev(SimEventKind.fire, side: 1),
      ]);
      await tester.pump();
      expect(played, [Sfx.turn, Sfx.gurgle, Sfx.crackle, Sfx.wake]);
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
}
