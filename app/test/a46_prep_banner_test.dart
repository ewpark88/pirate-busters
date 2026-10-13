import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/game/start_gate.dart';
import 'package:pirate_busters/game/view/fx_text.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/hud/boss_banner.dart';

import 'test_catalog.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('ko'),
  supportedLocales: const [Locale('ko'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  group('A41 점검 남은 앱 버그 (A46, ADR-097)', () {
    test('출전 덱은 자리 수만큼 자르고, 준비 화면과 전투가 같은 덱을 쓴다', () {
      final setup = BattleSetup(testCatalog);
      const saved = ['p26_polly', 'p16_suri', 'p36_tok', 'p01_octo'];
      final deck = setup.sailDeck(saved, HullSpec.sloop, 99, seats: 2);
      expect(deck, ['p26_polly', 'p16_suri']);
      final match = setup.newStageMatch(
        1,
        testCampaign.sea(1).stages.first,
        blueprint: testCatalog.preset('balanced').blueprint,
        deck: saved,
        costLimit: 99,
      );
      expect(
        [for (final p in match.state.sides[0].crew.pirates) p.spec.id],
        setup.sailDeck(saved, HullSpec.sloop, 99),
        reason: '자리 5칸에 맞춘 덱 그대로, 시작 덱으로 바뀌지 않는다',
      );
    });

    test('코스트 한도를 넘으면 뒤에서 빼고, 아무것도 안 맞으면 시작 덱', () {
      final setup = BattleSetup(testCatalog);
      const hull = HullSpec.sloop;
      final cost = testCatalog.pirates.byId('p26_polly').cost;
      final deck = setup.sailDeck(
        ['p26_polly', 'p16_suri', 'p36_tok'],
        hull,
        cost,
      );
      expect(deck, ['p26_polly']);
      expect(setup.sailDeck(['nobody'], hull, 99), BattleSetup.starterDeck);
    });

    test('보스 배너가 떠 있는 동안 판 시계 문이 닫혀 있다', () {
      final gate = StartGate()..held = true;
      for (var i = 0; i < 400; i++) {
        expect(gate.tick(0.016), isFalse);
      }
      gate.held = false;
      var open = false;
      for (var i = 0; i < 5 && !open; i++) {
        open = gate.tick(0.016);
      }
      expect(open, isTrue);
    });

    testWidgets('보스 배너는 시간이 다 되거나 누르면 한 번만 닫힘을 알린다', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _app(BossBanner(gimmick: 'bow_iron_shield', onDone: () => done++)),
      );
      await tester.tap(find.byType(BossBanner));
      await tester.pump(BossBanner.shown + const Duration(seconds: 1));
      expect(done, 1);
    });

    test('피해 숫자는 그려지는 크기만큼 띄워 쌓는다', () {
      final at = Vector2(100, 100);
      final first = FxText.stackSpot(at, []);
      final second = FxText.stackSpot(at, [first]);
      final third = FxText.stackSpot(at, [first, second]);
      expect(first.y - second.y, FxText.slotHeight);
      expect(second.y - third.y, FxText.slotHeight);
      expect(FxText.stackSpot(Vector2(300, 100), [first]), Vector2(300, 100));
    });
  });
}
