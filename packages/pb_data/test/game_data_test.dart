import 'dart:convert';
import 'dart:io';

import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

const _gameDir = '../../app/assets/game';
const _l10nDir = '../../app/lib/l10n';

GameData _load() => GameData.parse(
  ammoJson: File('$_gameDir/ammo.json').readAsStringSync(),
  piratesJson: File('$_gameDir/pirates.json').readAsStringSync(),
);

String _pirate(Map<String, Object?> override) => jsonEncode({
  'pirates': [
    {
      'id': 'x',
      'nameKey': 'n',
      'descKey': 'd',
      'loreKey': 'l',
      'family': 'lob',
      'rarity': 'common',
      'hp': 240,
      'cooldownTurns': 0,
      'ammo': {'type': 'explosive'},
      'onHit': {'radiusCells': 1, 'blockDmg': 40, 'pirateDmg': 80},
      'render': {'species': 'octo'},
      ...override,
    },
  ],
});

void main() {
  final ammoJson = File('$_gameDir/ammo.json').readAsStringSync();

  group('탄종 사다리 ammo.json (설계서 §4.8)', () {
    test('탄종 13개 × 등급 5칸이 설계서 표와 같다', () {
      final l = _load().ladder;
      (int, int) v(AmmoType t, Rarity r) => l.valueOf(t, r);
      expect(
        [for (final r in Rarity.values) v(AmmoType.explosive, r).$1],
        [30, 50, 60, 70, 80],
      );
      expect(
        [for (final r in Rarity.values) v(AmmoType.split, r).$1],
        [2, 3, 4, 5, 6],
      );
      expect(
        [for (final r in Rarity.values) v(AmmoType.burst, r).$1],
        [3, 6, 12, 16, 20],
      );
      expect(
        [for (final r in Rarity.values) v(AmmoType.sniper, r).$1],
        [150, 170, 190, 210, 230],
      );
      expect(
        [for (final r in Rarity.values) v(AmmoType.flock, r).$1],
        [3, 4, 6, 8, 10],
      );
      expect(
        [for (final r in Rarity.values) v(AmmoType.homing, r).$1],
        [30, 45, 60, 75, 90],
      );
      expect(v(AmmoType.mine, Rarity.common), (1, 20));
      expect(v(AmmoType.mine, Rarity.myth), (3, 60));
      expect(v(AmmoType.support, Rarity.legend).$1, 145);
    });

    test('탄종이 빠지거나 칸 수가 틀리거나 실수가 있으면 거부한다', () {
      final m = jsonDecode(ammoJson) as Map<String, Object?>;
      expect(
        () => AmmoLadder.fromJson({...m}..remove('split')),
        throwsA(isA<DataFormatError>()),
      );
      expect(
        () => AmmoLadder.fromJson({
          ...m,
          'split': [2, 3, 4],
        }),
        throwsA(isA<DataFormatError>()),
      );
      expect(
        () => AmmoLadder.fromJson({
          ...m,
          'split': [2, 3.5, 4, 5, 6],
        }),
        throwsA(isA<DataFormatError>()),
      );
    });
  });

  group('해적 40명 데이터 (설계서 §4.2, §4.3)', () {
    test('40명을 읽어 pb_sim 해적 정의로 바꾼다', () {
      final data = _load();
      expect(data.pirates, hasLength(40));
      final catalog = data.catalog;
      for (final p in data.pirates) {
        expect(catalog.byId(p.id).id, p.id);
      }
    });

    test('같은 탄종의 등급 쌍: 윙(일반) 3개 · 펠리(희귀) 4개가 정수로 나온다', () {
      final c = _load().catalog;
      final wing = c.byId('p27_wing');
      final pelly = c.byId('p28_pelly');
      expect([wing.ammo, wing.ammoValue], [AmmoType.flock, 3]);
      expect([pelly.ammo, pelly.ammoValue], [AmmoType.flock, 4]);
      expect(pelly.ammoParam, 1, reason: '다음 내 턴 시작 투하');
    });

    test('우니(영웅)는 분열탄 4조각, 퍼짐 25°', () {
      final uni = _load().catalog.byId('p04_uni');
      expect(
        [uni.ammo, uni.ammoValue, uni.spreadMdeg],
        [
          AmmoType.split,
          4,
          25000,
        ],
      );
    });

    test('체력·피해에 등급 배율을 곱한다: 영웅 우니 ×1.25, 희귀 펠리 ×1.10', () {
      final c = _load().catalog;
      expect(c.byId('p04_uni').hp, 300);
      expect(c.byId('p04_uni').blockDamage, 50);
      expect(c.byId('p28_pelly').hp, 220);
      expect(c.byId('p01_octo').hp, 240);
    });

    test('사거리는 계열 기본 등급, 히포·팡은 짧음 (설계서 §2.8, A2.8 예외)', () {
      final c = _load().catalog;
      expect(c.byId('p01_octo').range, RangeGrade.long);
      expect(c.byId('p06_pang').range, RangeGrade.short);
      expect(c.byId('p07_hippo').range, RangeGrade.short);
      expect(c.byId('p26_polly').range, RangeGrade.veryLong);
      expect(c.byId('p31_sharky').range, RangeGrade.short);
      expect(c.byId('p08_bones').range, RangeGrade.veryLong);
      expect(c.byId('p05_volke').range, RangeGrade.veryLong);
      expect(c.byId('p23_bara').range, RangeGrade.long);
    });

    test('등급 분포는 일반 12 · 희귀 12 · 영웅 8 · 전설 8 이다 (설계서 §4.2)', () {
      final count = List.filled(Rarity.values.length, 0);
      for (final p in _load().pirates) {
        count[p.rarity.index]++;
      }
      expect(count, [12, 12, 8, 8, 0]);
    });

    test('쿨다운은 BALANCE.md A4.2 표와 같다', () {
      const twoTurns = {
        'p02_starry',
        'p04_uni',
        'p05_volke',
        'p09_lion',
        'p10_volt',
        'p15_moby',
        'p20_orca',
        'p24_moray',
        'p25_kraki',
        'p30_manta',
        'p35_davy',
        'p40_lamp',
      };
      const zeroTurns = {
        'p01_octo',
        'p06_pang',
        'p07_hippo',
        'p11_finn',
        'p16_suri',
        'p26_polly',
        'p27_wing',
        'p36_tok',
      };
      for (final p in _load().pirates) {
        final want = twoTurns.contains(p.id)
            ? 2
            : (zeroTurns.contains(p.id) ? 0 : 1);
        expect(p.cooldownTurns, want, reason: p.id);
      }
    });

    test('고유 효과가 있는 해적은 설계서 §4.3 키와 BALANCE.md A4.2 인자를 갖는다', () {
      final c = _load().catalog;
      expect(
        [c.byId('p15_moby').ability, c.byId('p15_moby').abilityValue],
        [
          Ability.pull,
          3,
        ],
      );
      expect(c.byId('p20_orca').abilityValue, 80);
      expect(c.byId('p37_pumpum').abilityValue, 150);
      expect(c.byId('p40_lamp').abilityValue, 30);
      expect(c.byId('p29_alba').ability, Ability.steer);
      expect(c.byId('p01_octo').ability, Ability.none);
    });

    test('해적 글자 키가 한국어·영어 ARB 에 모두 있다 (설계서 §14.5)', () {
      final data = _load();
      for (final lang in ['ko', 'en']) {
        final arb =
            jsonDecode(File('$_l10nDir/app_$lang.arb').readAsStringSync())
                as Map<String, Object?>;
        expect(data.missingTextKeys(arb.keys.toSet()), isEmpty, reason: lang);
      }
    });

    test('실수·범위 밖 값·모르는 탄종·겹치는 id 는 거부한다', () {
      void bad(Map<String, Object?> o) => expect(
        () => GameData.parse(ammoJson: ammoJson, piratesJson: _pirate(o)),
        throwsA(isA<DataFormatError>()),
        reason: '$o',
      );
      bad({'hp': 240.0});
      bad({'cooldownTurns': 3});
      bad({
        'onHit': {'radiusCells': 3},
      });
      bad({
        'ammo': {'type': 'laser'},
      });
      bad({'family': 'magic'});
      final dup = jsonDecode(_pirate({})) as Map<String, Object?>;
      final list = dup['pirates']! as List<Object?>;
      expect(
        () => GameData.parse(
          ammoJson: ammoJson,
          piratesJson: jsonEncode({
            'pirates': [...list, ...list],
          }),
        ),
        throwsA(isA<DataFormatError>()),
      );
    });

    test('render.species 는 설계서 §4.3 에셋 키 표와 같아야 한다', () {
      for (final p in _load().pirates) {
        expect(speciesKeys[p.id], p.species, reason: p.id);
      }
      expect(speciesKeys, hasLength(40));
      expect(speciesKeys.values.toSet(), hasLength(40), reason: '키는 겹치지 않는다');
      // 랍은 계열 키 lob 과 헷갈리지 않게 lobster 다.
      expect(speciesKeys['p34_lob'], 'lobster');
      expect(speciesProblem('p34_lob', 'lob'), isNotNull);
      expect(speciesProblem('p11_finn', 'sword'), isNull);
      expect(speciesProblem('p11_finn', 'finn'), isNotNull);
      // 표에 없는 id 도 그림이 있는 키만 쓸 수 있다.
      expect(speciesProblem('x', 'octo'), isNull);
      expect(speciesProblem('x', 'dragon'), isNotNull);
      void bad(Map<String, Object?> o) => expect(
        () => GameData.parse(ammoJson: ammoJson, piratesJson: _pirate(o)),
        throwsA(isA<DataFormatError>()),
        reason: '$o',
      );
      bad({
        'render': {'species': 'dragon'},
      });
      bad({
        'id': 'p01_octo',
        'render': {'species': 'uni'},
      });
    });

    test('성장 특성은 파싱만 한다', () {
      final root =
          jsonDecode(
                _pirate({
                  'growth': {'traitLv10': 't10'},
                }),
              )
              as Map<String, Object?>;
      final def = PirateDef.fromJson((root['pirates']! as List<Object?>).first);
      expect(def.growth, {'traitLv10': 't10'});
    });

    test('고유 능력은 ability 의 type·value 로 읽고, 없으면 none 이다 (§4.3, ADR-075)', () {
      PirateDef read(Map<String, Object?> o) {
        final root = jsonDecode(_pirate(o)) as Map<String, Object?>;
        return PirateDef.fromJson((root['pirates']! as List<Object?>).first);
      }

      final moby = read({
        'ammo': {'type': 'pierce'},
        'ability': {'type': 'pull', 'value': 3},
      });
      expect(moby.ability, Ability.pull);
      expect(moby.abilityValue, 3);
      final spec = moby.toSpec(_load().ladder);
      expect(spec.ability, Ability.pull);
      expect(spec.abilityValue, 3);
      expect(read({}).ability, Ability.none);
      expect(
        () => read({
          'ability': {'type': 'teleport'},
        }),
        throwsA(isA<DataFormatError>()),
      );
      expect(
        () => read({
          'ammo': {'type': 'support'},
          'ability': {'type': 'bail', 'value': -1},
        }),
        throwsA(isA<DataFormatError>()),
      );
      expect(
        () => read({
          'ammo': {'type': 'explosive'},
          'ability': {'type': 'floatMine'},
        }),
        throwsA(isA<DataFormatError>()),
        reason: '떠 있는 기뢰는 설치탄에만',
      );
    });
  });

  group('여러 발 탄종 피해 (설계서 §4.8)', () {
    test('합계 = 기본 × (140% + 등급 단계 × 10%), 발마다 고르게 나눈다', () {
      expect(multiShotTotalPercent(0), 140);
      expect(multiShotTotalPercent(2), 160);
      expect(perShotDamage(40, 0, 2), 28);
      expect(perShotDamage(60, 0, 3), 28);
      expect(perShotDamage(50, 2, 4), 20);
    });

    test('특성·세트 보너스는 개수 +2, 폭발 반경 2칸까지', () {
      expect(cappedCount(4, 5), 6);
      expect(cappedCount(4, 1), 5);
      expect(cappedBlastRadius(3), 2);
    });
  });

  group('추천 설계도 blueprints.json (설계서 §3.4)', () {
    List<BlueprintPreset> load() => parsePresets(
      jsonDecode(File('$_gameDir/blueprints.json').readAsStringSync()),
    );

    test('확장 단계마다 밸런스·철갑·고속 3종이 있고 건조 규칙을 지킨다 (§3.1)', () {
      final presets = load();
      for (var stage = 1; stage <= HullSpec.maxStage; stage++) {
        expect(
          [
            for (final p in presets)
              if (p.stage == stage) p.id,
          ],
          ['balanced', 'armored', 'fast'],
          reason: '단계 $stage',
        );
      }
      for (final p in presets) {
        final b = p.blueprint;
        expect(b.cost, lessThanOrEqualTo(b.hull.buildPoints), reason: p.id);
        expect(
          b.modules.where((m) => m.kind == ModuleKind.captain),
          hasLength(1),
        );
      }
    });

    test('철갑은 가장 무겁고, 고속은 가장 가볍고 연료통으로 탱크가 크다', () {
      final byId = {
        for (final p in load())
          if (p.stage == HullSpec.maxStage) p.id: p.blueprint,
      };
      int weight(Blueprint b) =>
          b.cells.fold(0, (s, c) => s + c.material.weight);
      expect(weight(byId['armored']!), greaterThan(weight(byId['balanced']!)));
      expect(weight(byId['fast']!), lessThan(weight(byId['balanced']!)));
      expect(
        byId['fast']!.modules.where((m) => m.kind == ModuleKind.fuelTank),
        hasLength(2),
      );
    });

    test('설계도 이름·설명 키가 한국어·영어 ARB 에 모두 있다 (설계서 §14.5)', () {
      final keys = [for (final p in load()) ...p.textKeys];
      for (final lang in ['ko', 'en']) {
        final arb =
            jsonDecode(File('$_l10nDir/app_$lang.arb').readAsStringSync())
                as Map<String, Object?>;
        expect(keys.where((k) => !arb.containsKey(k)), isEmpty, reason: lang);
      }
    });

    test('규칙을 어긴 설계도(선장실 없음)는 데이터 오류로 거부한다', () {
      expect(
        () => parsePresets({
          'presets': [
            {
              'id': 'x',
              'nameKey': 'n',
              'descKey': 'd',
              'blueprint': {
                'hull': 'sloop',
                'cells': [
                  for (var x = 0; x < 12; x++) [x, 0, 'oak'],
                ],
                'cabins': [
                  [0, 0],
                  [1, 0],
                  [2, 0],
                  [3, 0],
                ],
                'modules': <Object?>[],
              },
            },
          ],
        }),
        throwsA(isA<DataFormatError>()),
      );
    });
  });
}
