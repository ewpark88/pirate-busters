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

  group('나머지 28명 시나리오: 고유 동작대로 동작한다 (설계서 §4.2, §4.8, ADR-075·078)', () {
    bool enemy(MatchState s, SimEventKind k) => _has(s, k, side: 1);
    int count(MatchState s, SimEventKind k) =>
        s.events.where((e) => e.kind == k && e.side == 1).length;
    void damageOwnDeck(MatchState s) {
      final grid = s.sides[0].grid;
      for (var x = 0; x < grid.width; x++) {
        if (!grid.hasBlock(x, 1)) continue;
        final max = grid.materialAt(x, 1)!.durability;
        grid.damage(x, 1, max - max ~/ 4);
      }
      s.sides[0].flood = 300;
    }

    final cases = <(String, String, bool Function(MatchState), int?)>[
      (
        'p02_starry',
        '화염탄이 불을 붙인다',
        (s) => enemy(s, SimEventKind.ignited),
        null,
      ),
      (
        'p03_crabs',
        '두 발이 모두 적 배에 맞는다',
        (s) => count(s, SimEventKind.impact) >= 2,
        null,
      ),
      (
        'p05_volke',
        '층을 뚫고 터진다',
        (s) => count(s, SimEventKind.impact) >= 2,
        null,
      ),
      (
        'p08_bones',
        '매우 긴 사거리로 맞힌다',
        (s) => enemy(s, SimEventKind.impact),
        null,
      ),
      ('p09_lion', '연사가 적 배에 맞는다', (s) => enemy(s, SimEventKind.impact), 16),
      (
        'p10_volt',
        '맞은 해적에서 번개가 번진다',
        (s) => enemy(s, SimEventKind.chained),
        16,
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
        '세로줄을 자른다',
        (s) => enemy(s, SimEventKind.blockDestroyed),
        null,
      ),
      (
        'p15_moby',
        '적 배를 끌어당겨 묶는다',
        (s) => enemy(s, SimEventKind.statusApplied),
        null,
      ),
      ('p17_pingu', '튕겨 맞힌다', (s) => enemy(s, SimEventKind.impact), null),
      (
        'p18_sheldon',
        '벽에서 되튀어 두 번 이상 맞힌다',
        (s) => count(s, SimEventKind.impact) >= 2,
        null,
      ),
      ('p19_dolphy', '흘수선을 연타한다', (s) => enemy(s, SimEventKind.impact), null),
      ('p20_orca', '침수를 올린다', (s) => enemy(s, SimEventKind.flood), null),
      (
        'p22_jelly',
        '기뢰를 띄우거나 붙인다',
        (s) =>
            enemy(s, SimEventKind.mineFloated) ||
            enemy(s, SimEventKind.mineAttached),
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
        '촉수가 붙는다',
        (s) => enemy(s, SimEventKind.mineAttached),
        null,
      ),
      (
        'p29_alba',
        '명중 시 바람 역전을 건다',
        (s) => enemy(s, SimEventKind.statusApplied),
        null,
      ),
      (
        'p30_manta',
        '명중 시 궤적 봉쇄를 건다',
        (s) => enemy(s, SimEventKind.statusApplied),
        null,
      ),
      (
        'p32_crabby',
        '해적을 바다로 떨어뜨린다',
        (s) => enemy(s, SimEventKind.pirateFell),
        12,
      ),
      ('p33_king', '선실을 봉쇄한다', (s) => enemy(s, SimEventKind.statusApplied), 12),
      ('p34_lob', '착지해 해적을 벤다', (s) => enemy(s, SimEventKind.pirateHit), 12),
      (
        'p35_davy',
        '해골 선원을 부른다',
        (s) =>
            s.effects.where((e) => e.kind == EffectKind.biteAgain).length >= 3,
        12,
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

    final support = <(String, String, bool Function(MatchState))>[
      (
        'p37_pumpum',
        '내 배 침수를 줄인다',
        (s) => _has(s, SimEventKind.supported, side: 0),
      ),
      ('p38_cook', '아군을 치유한다', (s) => _has(s, SimEventKind.supported, side: 0)),
      ('p39_corey', '산호 방벽을 세운다', (s) => _has(s, SimEventKind.barrierPlaced)),
      (
        'p40_lamp',
        '다음 턴 궤적·바람·연료를 건다',
        (s) => _has(s, SimEventKind.supported, side: 0),
      ),
    ];
    for (final (id, what, ok) in support) {
      test('$id(지원탄): $what', () {
        expect(
          _someShot(id, ok, setup: damageOwnDeck, fromDeg: 60, toDeg: 175),
          isTrue,
        );
      });
    }
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
