import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/audio/sound_service.dart';
import 'package:pirate_busters/audio/wind_loop.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/game/battle_game.dart';
import 'package:pirate_busters/game/camera_director.dart';
import 'package:pirate_busters/game/coords.dart';
import 'package:pirate_busters/game/view/backdrop.dart';
import 'package:pirate_busters/game/view/breeze.dart';
import 'package:pirate_busters/game/view/guide_marks.dart';
import 'package:pirate_busters/game/view/sea_crests.dart';
import 'package:pirate_busters/game/view/sea_shape.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/sea_zones.dart';
import 'package:pirate_busters/game/view/wind_feel.dart';
import 'package:pirate_busters/game/view/wind_spray.dart';
import 'package:pirate_busters/game/wind_sound.dart';
import 'package:pirate_busters/ui/hud/gap_bar.dart';

import 'test_catalog.dart';

/// 골든은 Windows 글꼴·렌더로 만든다(다른 OS 는 건너뛴다).
final bool _skipGolden = !Platform.isWindows;

/// 첫 턴이 [want] 조건을 만족하는 시드의 세션.
BattleSession _session(bool Function(MatchState s) want) {
  for (var seed = 1; ; seed++) {
    final m = testSetup.newMatch(seed);
    if (want(m.state)) {
      return BattleSession(
        m,
        humanSides: const {0, 1},
        speciesOf: testCatalog.speciesOf,
      );
    }
  }
}

/// 배에서 먼 바다 (배 둘레 잔잔한 폭 밖).
const List<ShipOnSea> _farShips = [
  (x: -3000, half: 190, heave: 0, facing: 1, moving: false),
  (x: 3000, half: 190, heave: 0, facing: -1, moving: false),
];

/// 판의 [x](월드 px) 근처 최대 너울 높이.
double _peak(SeaZones zones, double x) {
  var best = 0.0;
  for (var t = 0.0; t < 12; t += .05) {
    final h = SeaShape.swell(x, t, _farShips, zones).abs();
    if (h > best) best = h;
  }
  return best;
}

class _WindRecorder implements SoundService {
  final List<int> levels = [];

  @override
  void windLevel(int level) => levels.add(level);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final zones = SeaZones(const [0, 1, 3], width: 160);

  group('파도 구간 그리기 (설계서 §2.6·§10.2)', () {
    test('구간 번호는 시뮬레이션의 waveZoneIndex 와 같고 좌우 대칭이다', () {
      final state = testSetup.newMatch(3).state;
      final view = SeaZones.of(state);
      for (var cells = -20; cells <= 20; cells++) {
        final simX = cells * cellUnit + 500;
        final px = Coords.x(simX);
        expect(view.indexAt(px), waveZoneIndex(state, simX));
        expect(view.levelAt(px), view.levelAt(-px));
      }
    });

    test('경계는 가운데에서 5칸·10칸이고, 경계 근처에서만 세기가 섞인다', () {
      expect(zones.edges, [160, 320]);
      expect(zones.smoothLevelAt(80), 0);
      expect(zones.smoothLevelAt(240), 1);
      expect(zones.smoothLevelAt(600), 3);
      final mid = zones.smoothLevelAt(160);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(1));
      // 경계를 지나며 한 걸음에 크게 뛰지 않는다.
      for (var x = 100.0; x < 400; x += 2) {
        expect(
          (zones.smoothLevelAt(x + 2) - zones.smoothLevelAt(x)).abs(),
          lessThan(.25),
        );
      }
    });

    test('잔잔한 구간은 거의 평평하고 거친 구간 너울이 보통 구간보다 높다', () {
      final calm = _peak(zones, 80);
      final normal = _peak(zones, 240);
      final rough = _peak(zones, 900);
      expect(calm, lessThan(1));
      expect(normal, greaterThan(calm * 4));
      expect(rough, greaterThan(normal * 2));
    });

    test('배 자리 수면은 구간과 상관없이 너울이 0이다', () {
      for (final ship in _farShips) {
        expect(SeaShape.swell(ship.x, 2, _farShips, zones), 0);
      }
    });

    test('물마루는 잔잔한 구간에 없고 보통은 둘에 하나, 거친 구간은 모두 선다', () {
      final xs = [for (var i = 0; i < 8; i++) i * SeaShape.length];
      expect(xs.where((x) => SeaCrests.shown(0, x)), isEmpty);
      expect(xs.where((x) => SeaCrests.shown(1, x)).length, 4);
      expect(xs.where((x) => SeaCrests.shown(3, x)).length, 8);
    });

    test('포말은 거친 구간에서 더 자주 생기고 잔물결은 잔잔하면 작다', () {
      expect(SeaCrests.foamWeight(3), 1);
      expect(SeaCrests.foamWeight(1), greaterThan(SeaCrests.foamWeight(0)));
      expect(SeaCrests.rippleFor(0), lessThan(SeaCrests.rippleFor(1)));
      expect(SeaCrests.rippleFor(3), greaterThan(SeaCrests.rippleFor(1)));
    });

    test('구간 물빛은 잔잔하면 맑은 색, 보통은 없음, 거칠면 짙은 색이다', () {
      const theme = SeaTheme.tropicalDay;
      expect(theme.tintFor(0), theme.calmTint);
      expect(theme.tintFor(1).a, 0);
      expect(theme.tintFor(3), theme.roughTint);
    });

    test('간격 막대 바탕은 구간마다 다른 색이다 (설계서 §13.4)', () {
      final colors = {
        for (final l in const [0, 1, 3]) ZoneStrip.colorOf(l),
      };
      expect(colors.length, 3);
    });
  });

  group('바람 보이기 (설계서 §2.4·§10.2)', () {
    test('포말은 바람 쪽으로 흐르고 무풍이면 제자리다', () {
      expect(SeaCrests.foamDrift(3), greaterThan(0));
      expect(SeaCrests.foamDrift(-2), lessThan(0));
      expect(SeaCrests.foamDrift(0), 0);
    });

    test('물마루는 바람 쪽으로 길게 눕고 무풍이면 좌우 대칭이다', () {
      final still = SeaCrests.dots(0);
      expect(still.first.$1, -still.last.$1);
      final right = SeaCrests.dots(1);
      final reach = right.map((d) => d.$1).reduce((a, b) => a > b ? a : b);
      final back = right.map((d) => d.$1).reduce((a, b) => a < b ? a : b);
      expect(reach, greaterThan(-back));
      // 바람 쪽 끝은 수면 위로 말려 오른다.
      expect(right.last.$2, greaterThan(0));
      final left = SeaCrests.dots(-1);
      expect(left.last.$1, lessThan(0));
    });

    test('구름은 바람 쪽으로 흐르고 셀수록 빠르며 무풍이면 아주 느리다', () {
      expect(Backdrop.cloudSpeed(3), greaterThan(Backdrop.cloudSpeed(1)));
      expect(Backdrop.cloudSpeed(-2), lessThan(0));
      expect(Backdrop.cloudSpeed(0), inExclusiveRange(0, 10));
      expect(Backdrop.drifts('clouds'), isTrue);
      expect(Backdrop.drifts('far'), isFalse);
    });

    test('바람이 바뀌면 느끼는 바람이 한 프레임에 꺾이지 않고 이어 바뀐다', () {
      var v = -3.0;
      final step = WindFeel.approach(v, 3, 1 / 60);
      expect(step - v, lessThan(.5));
      for (var i = 0; i < 60; i++) {
        v = WindFeel.approach(v, 3, 1 / 60);
      }
      expect(v, closeTo(3, .2));
    });

    test('물보라는 바람 2단계 미만이면 없고, 3단계가 더 많고, 저사양이면 절반이다', () {
      expect(WindSpray.capFor(1, low: false), 0);
      expect(WindSpray.capFor(-2, low: false), greaterThan(0));
      expect(
        WindSpray.capFor(3, low: false),
        greaterThan(WindSpray.capFor(2, low: false)),
      );
      expect(
        WindSpray.capFor(3, low: true),
        WindSpray.capFor(3, low: false) ~/ 2,
      );
    });

    test('센 바람에는 물보라가 날리고 무풍이면 없다', () {
      WindSpray spray(bool Function(MatchState) want) {
        final session = _session(want);
        final sea = SeaShape(ships: () => _farShips, zones: zones)..update(1);
        final wind = WindFeel(session: session);
        final s = WindSpray(shape: sea, wind: wind);
        for (var i = 0; i < 30; i++) {
          s.update(1 / 30);
        }
        return s;
      }

      expect(spray((s) => s.wind.abs() == 3).count, greaterThan(0));
      expect(spray((s) => s.wind == 0).count, 0);
    });

    test('기움대 깃발은 무풍이면 처지고 바람이 셀수록 펴진다', () {
      expect(FlagWave.droop(stillAir), greaterThan(1));
      expect(FlagWave.droop((strength: 1, dir: 1, t: 0)), 0);
      expect(FlagWave.flutter(stillAir), 0);
    });

    test('바람 소리는 단계가 셀수록 크고 무풍이면 없다', () {
      expect(WindLoop.volumeFor(0), 0);
      expect(WindLoop.volumeFor(-3), WindLoop.volumeFor(3));
      expect(WindLoop.volumeFor(3), greaterThan(WindLoop.volumeFor(1)));
    });

    test('바람이 바뀔 때만 소리 서비스에 새 단계를 알린다', () {
      final session = _session((s) => s.wind != 0);
      final sound = _WindRecorder();
      WindSound(session: session, sound: sound)
        ..update(.1)
        ..update(.1);
      expect(sound.levels, [session.state.wind]);
    });
  });

  group('이동 안내 (설계서 §2.5)', () {
    test('끝 지점은 진영이 바라보는 쪽으로 전진한다', () {
      final state = testSetup.newMatch(1).state;
      for (final side in state.sides) {
        final bow = Coords.x(side.bowX);
        final ahead = GuideMarks.endX(side, 10) - bow;
        expect(ahead.sign, facingOf(side.side).toDouble());
        expect(ahead.abs(), closeTo(Coords.cell, 1e-9));
      }
    });

    test('연료로 멈추면 fuel, 상대 앞이면 foe, 뒤쪽 바다 끝이면 seaEnd 다', () {
      final session = _session((_) => true);
      final me = session.state.sides[session.state.activeSide];
      expect(session.moveStopFor(1), MoveStop.fuel);
      // 상대 배 4칸 앞까지 다가간 자리: 최소 간격 2칸에서 막힌다.
      me.offset = 18 * cellUnit;
      expect(session.moveStopFor(1), MoveStop.foe);
      // 바다 끝 1칸 앞: 뒤로는 바다 끝에서 막힌다.
      me.offset = -3 * cellUnit;
      expect(session.moveStopFor(-1), MoveStop.seaEnd);
    });

    test('연료 60·칸당 10 이면 한 턴에 6칸까지 간다 (BALANCE.md A2.7)', () {
      final session = _session((_) => true);
      final me = session.state.sides[session.state.activeSide];
      expect(me.tank ~/ me.fuelPerCell, 6);
      expect(session.reach(1000).abs(), 6 * cellUnit);
    });
  });

  group('카메라 (설계서 §2.1)', () {
    test('전체 보기는 최대 간격 30칸에서도 두 배가 들어오고 너무 좁아지지 않는다', () {
      final c = CameraDirector()..overview = true;
      // 최대 간격: 뱃머리 30칸, 배 가운데끼리 30 + 12칸.
      const far = (30 + 12) * Coords.cell / 2;
      final (_, w) = c.target(myX: -far, enemyX: far, facing: 1);
      expect(w, lessThanOrEqualTo(CameraDirector.maxWidth));
      expect(w, greaterThanOrEqualTo(far * 2 + 12 * Coords.cell));
      final (_, near) = c.target(myX: -40, enemyX: 40, facing: 1);
      expect(near, CameraDirector.overviewMinWidth);
    });

    test('상대가 가까이 오면 기본 화면이 두 배 가운데로 옮긴다', () {
      double centerFor(double enemyX) {
        final c = CameraDirector();
        return c.target(myX: -300, enemyX: enemyX, facing: 1).$1.x;
      }

      // 멀면 내 배 앞바다, 간격 2칸(배 가운데 거리 14칸)이면 거의 두 배 가운데.
      expect(centerFor(900), -300 + CameraDirector.idleAhead);
      const enemy = -300 + 14 * Coords.cell;
      expect(centerFor(enemy), closeTo((-300 + enemy) / 2, 20));
    });
  });

  group('바다·바람 장면 골든', () {
    Future<void> scene(
      WidgetTester tester,
      bool Function(MatchState) want,
      String name, {
      bool overview = false,
    }) async {
      final session = _session(want);
      rootBundle.clear();
      late ui.Image image;
      await tester.runAsync(() async {
        final game = BattleGame(session)..onGameResize(Vector2(960, 440));
        // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
        // ignore: invalid_use_of_internal_member
        await game.load();
        // Flame 테스트 도우미와 같은 내부 수명 주기 호출이다.
        // ignore: invalid_use_of_internal_member
        game.mount();
        // ignore: cascade_invocations, mount 은 위의 ignore 가 필요해 캐스케이드로 못 묶는다.
        game.update(0);
        await game.ready();
        game
          ..lowEnd.value = true
          ..overview.value = overview;
        for (var i = 0; i < 90; i++) {
          game.update(1 / 30);
        }
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        image = await recorder.endRecording().toImage(960, 440);
      });
      await expectLater(image, matchesGoldenFile('goldens/$name.png'));
    }

    testWidgets('전체 보기: 가운데 잔잔·보통·바깥 거침 구간', (tester) async {
      await scene(
        tester,
        (s) => s.waveZones[0] == 0 && s.waveZones[2] == 3,
        's2_zones_overview',
        overview: true,
      );
    }, skip: _skipGolden);

    testWidgets('전체 보기: 가운데 거침·바깥 잔잔 구간', (tester) async {
      await scene(
        tester,
        (s) => s.waveZones[0] == 3 && s.waveZones[2] == 0,
        's2_zones_overview_rough_middle',
        overview: true,
      );
    }, skip: _skipGolden);

    for (final (wind, name) in const [
      (-3, 's2_wind_left3'),
      (0, 's2_wind_calm'),
      (3, 's2_wind_right3'),
    ]) {
      testWidgets('바람 $wind 단계 기본 화면', (tester) async {
        await scene(
          tester,
          (s) => s.wind == wind && s.waveZones[2] == 3,
          name,
        );
      }, skip: _skipGolden);
    }
  });
}
