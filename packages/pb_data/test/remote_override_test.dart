import 'dart:io';

import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:test/test.dart';

void main() {
  final data = GameData.parse(
    ammoJson: File('../../app/assets/game/ammo.json').readAsStringSync(),
    piratesJson: File('../../app/assets/game/pirates.json').readAsStringSync(),
  );

  group('원격 설정 덮어쓰기 (설계서 §7.4, 개발 계획서 A9)', () {
    test('ammo_<탄종>_<등급> 키가 사다리 칸을 바꾸고 나머지는 그대로다', () {
      final over = data.withOverrides(
        (k) => switch (k) {
          'ammo_explosive_common' => 45,
          'ammo_pierce_rare_2' => 9,
          _ => null,
        },
      );
      expect(over.ladder.valueOf(AmmoType.explosive, Rarity.common), (45, 0));
      expect(
        over.ladder.valueOf(AmmoType.explosive, Rarity.rare),
        data.ladder.valueOf(AmmoType.explosive, Rarity.rare),
      );
      expect(over.ladder.valueOf(AmmoType.pierce, Rarity.rare).$2, 9);
    });

    test('pirate_<id>_<필드> 키가 해적 수치를 바꾸고 카탈로그에 반영된다', () {
      final over = data.withOverrides(
        (k) => switch (k) {
          'pirate_p01_octo_hp' => 300,
          'pirate_p01_octo_blockDmg' => 50,
          _ => null,
        },
      );
      final octo = over.catalog.byId('p01_octo');
      expect(octo.hp, 300);
      expect(octo.blockDamage, 50);
      expect(octo.pirateDamage, data.catalog.byId('p01_octo').pirateDamage);
      expect(data.catalog.byId('p01_octo').hp, isNot(300));
    });

    test('규칙에 어긋나는 값(체력 0, 쿨다운 9)은 DataFormatError 다', () {
      expect(
        () => data.withOverrides((k) => k == 'pirate_p01_octo_hp' ? 0 : null),
        throwsA(isA<DataFormatError>()),
      );
      expect(
        () => data.withOverrides(
          (k) => k == 'pirate_p01_octo_cooldownTurns' ? 9 : null,
        ),
        throwsA(isA<DataFormatError>()),
      );
    });

    test('값이 하나도 없으면 원래와 같은 수치다', () {
      final over = data.withOverrides((_) => null);
      for (final p in data.pirates) {
        expect(over.catalog.byId(p.id).hp, data.catalog.byId(p.id).hp);
      }
    });
  });
}
