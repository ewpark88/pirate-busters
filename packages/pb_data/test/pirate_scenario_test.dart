import 'dart:convert';
import 'dart:io';

import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

const _gameDir = '../../app/assets/game';

final GameData _data = GameData.parse(
  ammoJson: File('$_gameDir/ammo.json').readAsStringSync(),
  piratesJson: File('$_gameDir/pirates.json').readAsStringSync(),
);

final Blueprint _ship = parsePresets(
  jsonDecode(File('$_gameDir/blueprints.json').readAsStringSync()),
).first.blueprint;

/// 왼쪽(0) 이 [id] 해적과 옥토, 오른쪽은 옥토·톡. 파도 없음, 왼쪽이 선공.
/// [gap] 을 주면 두 배를 같은 거리만큼 당겨 뱃머리 간격을 맞춘다.
Match _start(String id, {int? gap}) {
  for (var seed = 1; ; seed++) {
    final m = Match.start(
      seed: seed,
      rules: const MatchRules(waveLevel: 0),
      blueprints: [_ship, _ship],
      decks: [
        [id, if (id != 'p01_octo') 'p01_octo'],
        ['p01_octo', 'p36_tok'],
      ],
      costLimits: const [15, 15],
      pirates: _data.catalog,
    );
    if (m.state.activeSide != 0) continue;
    if (gap != null) {
      final now = (m.state.sides[0].bowX - m.state.sides[1].bowX).abs();
      for (final s in m.state.sides) {
        s.offset = (now - gap) ~/ 2;
      }
    }
    return m;
  }
}

/// 각도·힘을 바꿔 가며 새 판에서 한 발씩 쏴 [ok] 가 되는 발사를 찾는다.
bool _someShot(
  String id,
  bool Function(MatchState s) ok, {
  int? gap,
  int tapTick = 0,
  void Function(MatchState s)? setup,
  int fromDeg = 5,
  int toDeg = 85,
}) {
  for (final power in const [10000, 8000, 6000]) {
    for (var deg = fromDeg; deg <= toDeg; deg++) {
      final m = _start(id, gap: gap);
      setup?.call(m.state);
      m.apply(FireCommand(t: 1000, slot: 0, angle: deg * 1000, power: power));
      if (m.pendingSlot >= 0) {
        m.apply(TapCommand(t: 1000, slot: 0, ticks: tapTick));
      }
      if (ok(m.state)) return true;
    }
  }
  return false;
}

bool _has(MatchState s, SimEventKind kind, {int? side}) =>
    s.events.any((e) => e.kind == kind && (side == null || e.side == side));

void main() {
  group('해적 12명 시나리오: 실제 데이터로 쏘면 탄종대로 동작한다 (설계서 §4.2, §4.8)', () {
    test('옥토(폭발탄): 적 배에 맞아 블록을 부순다', () {
      expect(
        _someShot(
          'p01_octo',
          (s) => _has(s, SimEventKind.blockDestroyed, side: 1),
        ),
        isTrue,
      );
    });

    test('우니(분열탄): 탭한 틱에 4조각으로 갈라진다', () {
      expect(
        _someShot(
          'p04_uni',
          (s) => _has(s, SimEventKind.divide) && s.lastTraces.length == 5,
          tapTick: 15,
        ),
        isTrue,
      );
    });

    test('팡(저격탄, 짧음): 간격 12칸에서 적 배에 맞는다, 치명 배율 ×1.5', () {
      expect(_data.catalog.byId('p06_pang').ammoValue, 150);
      expect(
        _someShot(
          'p06_pang',
          (s) => _has(s, SimEventKind.impact, side: 1),
          gap: 12000,
        ),
        isTrue,
      );
    });

    test('히포(연사탄, 짧음): 가까이서 3발이 차례로 난다', () {
      expect(
        _someShot(
          'p07_hippo',
          (s) =>
              s.lastTraces.length == 3 && _has(s, SimEventKind.impact, side: 1),
          gap: 12000,
        ),
        isTrue,
      );
    });

    test('핀(관통탄, 보통): 간격 20칸에서 한 발에 블록을 둘 이상 뚫는다', () {
      expect(
        _someShot(
          'p11_finn',
          (s) =>
              s.events
                  .where((e) => e.kind == SimEventKind.blockDestroyed)
                  .length >=
              2,
          gap: 20000,
        ),
        isTrue,
      );
    });

    test('수리(물수제비탄): 수면에서 튕긴다', () {
      expect(
        _someShot('p16_suri', (s) => _has(s, SimEventKind.bounce)),
        isTrue,
      );
    });

    test('퍼피(설치탄, 보통): 간격 20칸에서 적 선체에 붙고 턴 효과가 걸린다', () {
      expect(
        _someShot(
          'p21_puffy',
          (s) =>
              _has(s, SimEventKind.mineAttached, side: 1) &&
              s.effects.single.kind == EffectKind.mineBlast,
          gap: 20000,
        ),
        isTrue,
      );
    });

    test('폴리(유도탄): 중력 없이 날아 적 배에 맞는다', () {
      expect(
        _someShot('p26_polly', (s) => _has(s, SimEventKind.impact, side: 1)),
        isTrue,
      );
    });

    test('윙(다중투하, 일반 3개)과 펠리(희귀 4개, 다음 내 턴 투하)', () {
      expect(
        _someShot(
          'p27_wing',
          (s) => _has(s, SimEventKind.divide) && s.lastTraces.length == 4,
          fromDeg: 30,
        ),
        isTrue,
      );
      expect(
        _someShot(
          'p28_pelly',
          (s) => s.effects.any((e) => e.kind == EffectKind.flockDrop),
        ),
        isTrue,
      );
    });

    test('샤키(강습탄, 짧음): 가까이서 착지해 물고 다음 상대 턴에 또 문다', () {
      expect(
        _someShot(
          'p31_sharky',
          (s) =>
              _has(s, SimEventKind.impact, side: 1) &&
              s.effects.any((e) => e.kind == EffectKind.biteAgain),
          gap: 12000,
        ),
        isTrue,
      );
    });

    test('톡(지원탄): 내 배에 떨어져 구멍 난 블록을 고친다', () {
      expect(
        _someShot(
          'p36_tok',
          (s) => _has(s, SimEventKind.repaired, side: 0),
          setup: (s) {
            final grid = s.sides[0].grid;
            for (var x = 0; x < grid.width; x++) {
              if (!grid.hasBlock(x, 1)) continue;
              final max = grid.materialAt(x, 1)!.durability;
              grid.damage(x, 1, max - max ~/ 4);
            }
          },
          fromDeg: 80,
          toDeg: 89,
        ),
        isTrue,
      );
    });
  });

  test('우니의 탭 분열은 리플레이에서 같은 해시로 재현된다 (완료 조건)', () {
    final m = _start('p04_uni')
      ..apply(const FireCommand(t: 1000, slot: 0, angle: 45000, power: 9000))
      ..apply(const TapCommand(t: 1000, slot: 0, ticks: 20))
      ..apply(const EndTurnCommand(t: 9000));
    expect(m.turnLog.last.commands.whereType<TapCommand>(), hasLength(1));
    final again = _start('p04_uni');
    m.turnLog.forEach(again.playTurn);
    expect(hashMatchState(again.state), hashMatchState(m.state));
  });
}
