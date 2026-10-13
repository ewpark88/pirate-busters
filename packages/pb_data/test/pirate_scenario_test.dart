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
      rules: const MatchRules(calmSea: true),
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

    test('핀(관통탄): 한 발이 블록을 뚫고 두 칸 이상 맞힌다', () {
      expect(
        _someShot(
          'p11_finn',
          (s) =>
              s.events
                  .where((e) => e.kind == SimEventKind.blockHit && e.side == 1)
                  .length >=
              2,
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

    test('윙(다중투하, 일반 3개)과 펠리(희귀 4개)는 꼭대기에서 갈라진다', () {
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
          (s) => _has(s, SimEventKind.divide) && s.lastTraces.length == 5,
          fromDeg: 30,
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

    test('톡(충격탄): 상대 배를 맞히면 1칸 밀어낸다 (ADR-111)', () {
      expect(
        _someShot('p36_tok', (s) => _has(s, SimEventKind.pushed, side: 1)),
        isTrue,
      );
    });
  });

  group('나머지 28명 시나리오: 탄종과 전설 능력대로 동작한다 (설계서 §4.2, §4.8, ADR-111)', () {
    bool enemy(MatchState s, SimEventKind k) => _has(s, k, side: 1);
    int count(MatchState s, SimEventKind k) =>
        s.events.where((e) => e.kind == k && e.side == 1).length;
    bool boarded(MatchState s) => _has(s, SimEventKind.boarded, side: 0);
    bool pushed(MatchState s) => enemy(s, SimEventKind.pushed);
    final cases = <(String, String, bool Function(MatchState), int?)>[
      (
        'p02_starry',
        '화염탄이 넓게 터진다(반경 2칸)',
        (s) => count(s, SimEventKind.blockHit) >= 5,
        null,
      ),
      ('p03_crabs', '폭발탄이 맞는다', (s) => enemy(s, SimEventKind.impact), null),
      (
        'p05_volke',
        '층을 뚫고 터진다',
        (s) => count(s, SimEventKind.impact) >= 2,
        null,
      ),
      ('p08_bones', '저격탄이 맞는다', (s) => enemy(s, SimEventKind.impact), null),
      ('p09_lion', '연사가 적 배에 맞는다', (s) => enemy(s, SimEventKind.impact), 16000),
      (
        'p10_volt',
        '맞은 해적에서 번개가 번진다',
        (s) => enemy(s, SimEventKind.chained),
        16000,
      ),
      ('p12_nar', '관통해 맞힌다', (s) => enemy(s, SimEventKind.impact), null),
      (
        'p13_walrus',
        '관통해 블록을 부순다',
        (s) => enemy(s, SimEventKind.blockDestroyed),
        null,
      ),
      (
        'p14_saw',
        '관통해 블록을 부순다',
        (s) => enemy(s, SimEventKind.blockDestroyed),
        null,
      ),
      ('p15_moby', '적 배를 끌어당긴다', pushed, null),
      ('p17_pingu', '튕겨 맞힌다', (s) => enemy(s, SimEventKind.impact), null),
      ('p18_sheldon', '튕겨 맞힌다', (s) => enemy(s, SimEventKind.impact), null),
      ('p19_dolphy', '튕겨 맞힌다', (s) => enemy(s, SimEventKind.impact), null),
      ('p20_orca', '해일로 적 배를 밀어낸다', pushed, null),
      (
        'p22_jelly',
        '선체에 붙는다',
        (s) => enemy(s, SimEventKind.mineAttached),
        null,
      ),
      (
        'p24_moray',
        '선체에 붙는다',
        (s) => enemy(s, SimEventKind.mineAttached),
        null,
      ),
      (
        'p25_kraki',
        '촉수가 붙고 바로 터진다',
        (s) =>
            enemy(s, SimEventKind.mineAttached) &&
            enemy(s, SimEventKind.blockHit),
        null,
      ),
      ('p29_alba', '유도탄이 맞는다', (s) => enemy(s, SimEventKind.impact), null),
      (
        'p30_manta',
        '명중 시 궤적 가림을 건다',
        (s) => enemy(s, SimEventKind.statusApplied),
        null,
      ),
      ('p32_crabby', '적 배 위에 선다', boarded, 12000),
      ('p33_king', '적 배 위에 선다', boarded, 12000),
      ('p34_lob', '적 배 위에 선다', boarded, 12000),
      (
        'p35_davy',
        '해골 선원과 함께 문다',
        (s) => boarded(s) && enemy(s, SimEventKind.pirateHit),
        12000,
      ),
      ('p37_pumpum', '충격탄이 적 배를 민다', pushed, null),
      ('p38_cook', '충격탄이 적 배를 민다', pushed, null),
      ('p39_corey', '충격탄이 적 배를 민다', pushed, null),
      (
        'p40_lamp',
        '큰 충격파로 적 배를 2칸 민다',
        (s) => s.events.any(
          (e) => e.kind == SimEventKind.pushed && e.value == -2 * cellUnit,
        ),
        null,
      ),
    ];
    for (final (id, what, ok, gap) in cases) {
      test('$id: $what', () {
        expect(_someShot(id, ok, gap: gap), isTrue);
      });
    }

    test('p23_bara: 아래로 쏜 어뢰가 물속으로 들어가 적 배에 맞는다', () {
      expect(
        _someShot(
          'p23_bara',
          (s) => enemy(s, SimEventKind.impact),
          fromDeg: 340,
          toDeg: 359,
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
