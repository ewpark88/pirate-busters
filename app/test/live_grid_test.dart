import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/playback.dart';
import 'package:pirate_busters/battle/session_views.dart';

import 'test_catalog.dart';

/// 사람이 선공인 허수아비전 세션.
BattleSession _humanFirst() {
  for (var seed = 1; ; seed++) {
    final m = testSetup.newMatch(seed);
    if (m.state.activeSide == 0) {
      return BattleSession(
        m,
        humanSides: const {0},
        speciesOf: testCatalog.speciesOf,
        opponent: const AiController(level: AiLevel.easy),
      );
    }
  }
}

/// 상대 배를 맞히는 (해적, 각도, 힘)을 찾아 쏜 세션. 못 찾으면 null.
BattleSession? _hitting() {
  for (var slot = 0; slot < 2; slot++) {
    for (var angle = 10000; angle <= 60000; angle += 5000) {
      for (var power = 6000; power <= 10000; power += 500) {
        final s = _humanFirst()..update(500);
        if (!s.canFire(slot)) continue;
        s.fire(slot, angle, power);
        final grid = s.state.sides[1].grid;
        if (grid.totalHp < grid.initialTotalHp) return s;
      }
    }
  }
  return null;
}

ShotTrace _trace(int ticks) {
  final t = ShotTrace(id: 0, startTick: 0);
  for (var i = 0; i <= ticks; i++) {
    t.add(i * 100, 0);
  }
  return t;
}

void main() {
  group('착탄에 맞춘 내구도 표시 (설계서 §2.3·§13.4, A33)', () {
    test('보이는 격자는 이벤트가 나온 틱에만 칸을 깎고 부순다', () {
      final grid = testSetup.newMatch(3).state.sides[1].grid;
      final before = [GridSnapshot(grid), GridSnapshot(grid)];
      final cells = [
        for (var i = 0; i < grid.cellCount; i++)
          if (grid.hasBlockAt(i)) i,
      ];
      final a = cells.first;
      final b = cells.last;
      final shot = ShotPlayback.resolved(
        side: 0,
        slot: 0,
        fireT: 0,
        traces: [_trace(40)],
        before: before,
        breakPauseMs: 0,
        events: [
          SimEvent(SimEventKind.impact, side: 1, cell: a, value: 10),
          SimEvent(SimEventKind.blockHit, side: 1, cell: a, y: 3, value: 5),
          SimEvent(SimEventKind.impact, side: 1, cell: b, value: 20),
          SimEvent(SimEventKind.blockHit, side: 1, cell: b, value: 9),
          SimEvent(SimEventKind.blockDestroyed, side: 1, cell: b),
        ],
      );
      expect(shot.live[1].hp, before[1].hp, reason: '탄이 닿기 전');
      shot
        ..elapsedMs = 15 * 1000 ~/ simTickHz
        ..takeDue();
      expect(shot.live[1].hp[a], 3);
      expect(shot.live[1].materials[b], before[1].materials[b]);
      shot
        ..elapsedMs = 25 * 1000 ~/ simTickHz
        ..takeDue();
      expect(shot.live[1].hp[b], 0);
      expect(shot.live[1].materials[b], ShipGrid.emptyCell);
      expect(shot.live[0].hp, before[0].hp, reason: '쏜 배는 그대로');
    });

    test('쏜 직후에는 선체 막대가 그대로이고, 탄이 닿은 뒤에 실제 값으로 준다', () {
      final s = _hitting();
      expect(s, isNotNull, reason: '맞히는 조준을 찾지 못했다');
      final grid = s!.state.sides[1].grid;
      final real = grid.totalHp / grid.initialTotalHp;
      expect(s.visibleHull(1), 1, reason: '발사 순간(탄은 아직 공중)');
      var last = 1.0;
      var guard = 0;
      while (s.playback != null && guard++ < 1000) {
        s.update(30);
        final v = s.visibleHull(1);
        expect(v, lessThanOrEqualTo(last + 1e-9), reason: '줄기만 한다');
        last = v;
      }
      expect(s.visibleHull(1), closeTo(real, 1e-9));
    });
  });

  group('궤적 미리보기 (설계서 §2.2, A33)', () {
    test('유도탄(폴리) 미리보기 앞부분이 실제로 날아간 경로와 같다', () {
      for (var seed = 1; seed < 40; seed++) {
        final m = testSetup.newMatch(
          seed,
          deck: const ['p26_polly', 'p36_tok'],
          costLimit: 999,
        );
        if (m.state.activeSide != 0) continue;
        final s = BattleSession(
          m,
          humanSides: const {0},
          speciesOf: testCatalog.speciesOf,
          opponent: const AiController(level: AiLevel.easy),
        )..update(500);
        expect(s.state.sides[0].crew.pirates[0].spec.ammo, AmmoType.homing);
        final preview = s.previewShot(0, 20000, 9000).head(20);
        s.fire(0, 20000, 9000);
        final real = (s.playback! as ShotPlayback).traces.first;
        // 실제 탄은 배에 닿으면 멈추므로 겹치는 앞부분(끝점 제외)을 비교한다.
        final n = math.min(preview.lastTick, real.xs.length - 2);
        expect(n, greaterThan(10));
        for (var i = 0; i <= n; i++) {
          expect(preview.xs[i], real.xs[i], reason: 'x 틱 $i');
          expect(preview.ys[i], real.ys[i], reason: 'y 틱 $i');
        }
        return;
      }
      fail('사람 선공 시드를 찾지 못했다');
    });
  });
}
