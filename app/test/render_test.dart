import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/battle/dummy_controller.dart';
import 'package:pirate_busters/game/anim/anim_data.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/ui/battle_screen.dart';

void main() {
  group('부위 애니메이션 데이터 (설계서 §10.1)', () {
    test('anims.json 에서 캐릭터 8명의 공격 동작과 공용 피격을 읽는다', () {
      final anims = PbAnims.fromJsonString(
        File('assets/data/anims.json').readAsStringSync(),
      );
      expect(
        anims.attacks.keys,
        containsAll(['octo', 'bones', 'sword', 'otter']),
      );
      expect(anims.hit.duration, greaterThan(0));
    });

    test('키 사이는 도착 키의 보간 방식으로, 범위 밖은 끝 키 값으로 계산한다', () {
      final keys = [
        AnimKey(0, 'io', {'rot': 0}),
        AnimKey(1, 'lin', {'rot': 10}),
        AnimKey(2, 'step', {'rot': 20}),
      ];
      expect(evalProp(keys, 'rot', 0.5, 0), 5);
      expect(evalProp(keys, 'rot', 1.5, 0), 10);
      expect(evalProp(keys, 'rot', 3, 0), 20);
      expect(evalProp(keys, 'dy', 1, 7), 7);
    });
  });

  group('카메라 (설계서 §2.1)', () {
    test('기본은 내 배 앞쪽, 조준을 당길수록 넓게 본다', () {
      final c = CameraDirector();
      final (idle, w0) = c.target(myX: -600, enemyX: 600, facing: 1);
      final (_, w1) = c.target(
        myX: -600,
        enemyX: 600,
        facing: 1,
        aimStretch: 1,
      );
      expect(idle.x, greaterThan(-600));
      expect(w0, CameraDirector.baseWidth);
      expect(w1, greaterThan(w0));
    });

    test('탄이 날면 탄과 표적이 한 화면에 들어온다', () {
      final c = CameraDirector();
      final (center, w) = c.target(
        myX: -900,
        enemyX: 900,
        facing: 1,
        projectile: Vector2(-500, -200),
      );
      expect(w, greaterThanOrEqualTo(1400 + 400));
      expect(center.x, 200);
    });

    test('핀치 줌은 1.5배 확대부터 간격 48칸이 다 보이는 배율까지만', () {
      final c = CameraDirector()..setUserZoom(10);
      final (_, wIn) = c.target(myX: 0, enemyX: 1000, facing: 1);
      expect(wIn, closeTo(CameraDirector.baseWidth / 1.5, 0.01));
      c.setUserZoom(0.01);
      final (_, wOut) = c.target(myX: 0, enemyX: 1000, facing: 1);
      expect(wOut, CameraDirector.maxWidth);
    });

    test('핀치로 끝까지 줄이면 간격 48칸의 두 배가 모두 보인다', () {
      // 뱃머리 사이 48칸 + 배 폭 12칸: 두 배 가운데는 60칸(1920px) 떨어져 있다.
      final c = CameraDirector()..setUserZoom(0.01);
      final (center, w) = c.target(myX: -960, enemyX: 960, facing: 1);
      expect(center.x - w / 2, lessThan(-960 - 192));
      expect(center.x + w / 2, greaterThan(960 + 192));
    });

    test('해적을 고르면 그 해적 발 앞으로 폭 440 까지 줌인한다 (ADR-033)', () {
      final c = CameraDirector()..focusFeet = Vector2(-500, -64);
      final (center, w) = c.target(myX: -600, enemyX: 600, facing: 1);
      expect(w, CameraDirector.focusWidth);
      expect(center, Vector2(-450, -74));
      final (_, pulled) = c.target(
        myX: -600,
        enemyX: 600,
        facing: 1,
        aimStretch: 1,
      );
      expect(pulled, greaterThan(w));
    });

    test('착탄 지점을 1.3초 보여준 뒤 돌아간다', () {
      final c = CameraDirector()..impact(Vector2(300, -40));
      final (a, _) = c.target(myX: 0, enemyX: 900, facing: 1);
      expect(a.x, 300);
      c.update(1.4, (Vector2.zero(), 900));
      final (b, _) = c.target(myX: 0, enemyX: 900, facing: 1);
      expect(b.x, isNot(300));
    });
  });

  testWidgets('전투 화면이 전장과 HUD 를 띄우고 몇 초 돌아도 오류가 없다', (tester) async {
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        ],
        child: const MaterialApp(
          locale: Locale('ko'),
          supportedLocales: supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BattleScreen(seed: 5),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('턴 종료'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('전장이 배·해적·바다를 그리고 탄 비행·착탄까지 오류 없이 진행한다', (tester) async {
    final session = BattleSession(
      BattleSetup.newMatch(7),
      humanSides: const {0},
      opponent: const DummyController(),
    );
    final sound = _RecordingSound();
    // 앞 테스트의 가짜 시간 영역에서 만든 자산 캐시(Future)는 여기서 끝나지 않는다.
    rootBundle.clear();
    await tester.runAsync(() async {
      // GameWidget 없이 띄운다: flame_test 의 initializeGame 과 같은 순서.
      final game = BattleGame(session, sound: sound)
        ..onGameResize(Vector2(960, 440));
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      await game.load();
      // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
      // ignore: invalid_use_of_internal_member
      game.mount();
      // ignore: cascade_invocations, mount 은 위의 ignore 가 필요해 캐스케이드로 못 묶는다.
      game.update(0);
      await game.ready();
      // 허수아비가 먼저 두는 판: 탄이 날아 착탄할 때까지 6초를 돌린다.
      var sawShot = false;
      for (var i = 0; i < 180; i++) {
        game.update(1 / 30);
        sawShot |= session.playback != null;
      }
      expect(sawShot, isTrue);
      // 발사 때 포성, 착탄 때 폭음·철판·물보라 중 하나 (설계서 §10.3).
      expect(sound.played.first, Sfx.cannon);
      expect(sound.played.length, greaterThanOrEqualTo(2));
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final image = await recorder.endRecording().toImage(96, 44);
      expect(image.width, 96);
    });
    expect(tester.takeException(), isNull);
  });
}

class _RecordingSound implements SoundService {
  final List<Sfx> played = [];

  @override
  Future<void> load(Map<Sfx, Uint8List> wavs) async {}

  @override
  void play(Sfx sfx, {double pitch = 1, double volume = 1}) => played.add(sfx);
}
