import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/ui/hud/hud_gauge.dart';

Widget _gauge(double v, {double? preview}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: SizedBox(
      width: 120,
      child: HudGauge(value: v, color: Colors.blue, preview: preview),
    ),
  ),
);

void main() {
  group('HUD 게이지 (설계서 §13.4, A33)', () {
    testWidgets('깎이면 앞 막대는 곧바로 줄고 잔상 막대는 잠깐 머문 뒤 따라온다', (
      tester,
    ) async {
      await tester.pumpWidget(_gauge(1));
      await tester.pumpWidget(_gauge(.5));
      final state = tester.state<HudGaugeState>(find.byType(HudGauge));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 200));
      expect(state.front, closeTo(.5, .05), reason: '앞 막대는 0.2초 안에');
      expect(state.trail, closeTo(1, 1e-9), reason: '잔상은 아직 머문다');
      expect(state.rising, isFalse);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      expect(state.trail, lessThan(.6), reason: '잔상이 따라 내려왔다');
      await tester.pumpAndSettle();
      expect(state.trail, closeTo(.5, 1e-3));
    });

    testWidgets('차면 초록 잔상이 먼저 차고 앞 막대가 따라 오른다', (tester) async {
      await tester.pumpWidget(_gauge(.3));
      await tester.pumpWidget(_gauge(.8));
      final state = tester.state<HudGaugeState>(find.byType(HudGauge));
      await tester.pump(const Duration(milliseconds: 16));
      expect(state.rising, isTrue);
      expect(state.trail, closeTo(.8, 1e-9));
      expect(state.front, lessThan(.4));
      await tester.pumpAndSettle();
      expect(state.front, closeTo(.8, 1e-3));
    });

    testWidgets('줄어들 몫 미리보기가 있어도 오류 없이 그린다', (tester) async {
      await tester.pumpWidget(_gauge(.7, preview: .4));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
