import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/ui/cards/card_icons.dart';
import 'package:pirate_busters/ui/cards/card_motion.dart';
import 'package:pirate_busters/ui/cards/card_mythic.dart';
import 'package:pirate_busters/ui/cards/rarity_card.dart';
import 'package:pirate_busters/ui/hud/ammo_label.dart';

void main() {
  group('등급 카드 프레임 (설계서 §10.5)', () {
    test('등급 5종의 배경·앞면 그림이 있다 (신화는 mythic 키)', () {
      expect(RarityCard.keyOf(Rarity.myth), 'mythic');
      for (final r in Rarity.values) {
        final key = RarityCard.keyOf(r);
        for (final layer in const ['back', 'front']) {
          expect(
            File('assets/images/ui/cards/card_${key}_$layer.png').existsSync(),
            isTrue,
            reason: '$key $layer',
          );
        }
      }
    });

    test('탄종 칩·사거리·코스트·세트 아이콘 그림이 모두 있다', () {
      for (final ammo in AmmoType.values) {
        expect(
          File(ammoIconPath(ammo)).existsSync(),
          isTrue,
          reason: ammo.name,
        );
      }
      for (final range in RangeGrade.values) {
        expect(
          File(CardIcons.range(range)).existsSync(),
          isTrue,
          reason: range.name,
        );
      }
      for (final rarity in Rarity.values) {
        expect(
          File(CardIcons.cost(rarity.cost)).existsSync(),
          isTrue,
          reason: rarity.name,
        );
      }
      for (final species in CardIcons.setOf.keys) {
        expect(File(CardIcons.set(species)!).existsSync(), isTrue);
      }
      expect(CardIcons.set('nobody'), isNull);
    });

    test('세트 10개에 해적 4명씩, 모두 에셋 키 표에 있는 해적이다 (설계서 §4.7)', () {
      final bySet = <String, int>{};
      for (final MapEntry(key: species, value: id) in CardIcons.setOf.entries) {
        bySet[id] = (bySet[id] ?? 0) + 1;
        expect(speciesKeys.containsValue(species), isTrue, reason: species);
      }
      expect(bySet, hasLength(10));
      expect(bySet.values.toSet(), {4});
      expect(CardIcons.setOf, hasLength(40));
    });

    test('신화 카드: 오로라는 6초에 좌우로 왕복하고 후광은 12초에 한 바퀴 돈다', () {
      expect(MythicPainter.shiftAt(0), 0);
      expect(
        MythicPainter.shiftAt(1.5),
        closeTo(MythicPainter.auroraShift, 1e-9),
      );
      expect(
        MythicPainter.shiftAt(4.5),
        closeTo(-MythicPainter.auroraShift, 1e-9),
      );
      expect(MythicPainter.shiftAt(6), closeTo(0, 1e-9));
      expect(MythicPainter.haloAngleAt(12), closeTo(2 * math.pi, 1e-9));
      expect(
        const MythicPainter(1).shouldRepaint(const MythicPainter(2)),
        isTrue,
      );
    });

    testWidgets('공용 시계가 없으면 멈춘 그림이라 화면이 가라앉고, 있으면 움직인다', (tester) async {
      Widget cards() => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            for (final r in Rarity.values)
              SizedBox(
                width: 72,
                child: RarityCard(rarity: r, species: 'octo'),
              ),
          ],
        ),
      );
      await tester.pumpWidget(cards());
      await tester.pumpAndSettle();
      expect(find.byType(RarityCard), findsNWidgets(5));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(CardMotion(child: cards()));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.binding.hasScheduledFrame, isTrue, reason: '시계가 돈다');
      expect(tester.takeException(), isNull);

      // 저사양 모드: 시계를 멈춘다 (§12).
      await tester.pumpWidget(CardMotion(enabled: false, child: cards()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
