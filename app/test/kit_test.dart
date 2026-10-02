import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/campaign/stage_node.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/kit/kit_motion.dart';
import 'package:pirate_busters/ui/kit/pb_button.dart';
import 'package:pirate_busters/ui/kit/pb_dialog.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';

import 'test_catalog.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool? reduced,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final body = Scaffold(body: Center(child: child));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: reduced == null ? body : KitMotion(reduced: reduced, child: body),
    ),
  );
}

void main() {
  group('키트 움직임 (설계서 §13 공통)', () {
    testWidgets('움직임이 켜지면 숫자가 세어 올라가 끝값에서 멈춘다', (tester) async {
      await _pump(
        tester,
        CountUp(value: 500, builder: (_, v) => Text('$v')),
        reduced: false,
      );
      expect(find.text('500'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      final mid = int.parse(tester.widget<Text>(find.byType(Text)).data!);
      expect(mid, inExclusiveRange(0, 500));
      await tester.pumpAndSettle();
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('저사양 모드면 숫자가 바로 끝값이다', (tester) async {
      await _pump(
        tester,
        CountUp(value: 500, builder: (_, v) => Text('$v')),
        reduced: true,
      );
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('튕기며 나타나는 패널은 순서만큼 늦게 시작해 끝나면 다 보인다', (tester) async {
      await _pump(
        tester,
        const PopIn(order: 3, child: Text('A')),
        reduced: false,
      );
      double opacity() => tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(opacity(), 0);
      await tester.pump(PopIn.step * 2);
      expect(opacity(), 0, reason: '아직 차례가 아니다');
      await tester.pumpAndSettle();
      expect(opacity(), 1);
    });

    testWidgets('누르는 동안 버튼이 줄었다가 떼면 돌아온다', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        PbButton(label: '출항', onPressed: () => taps++),
        reduced: false,
      );
      double scale() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
      final g = await tester.startGesture(tester.getCenter(find.text('출항')));
      await tester.pump();
      expect(scale(), lessThan(1));
      await g.up();
      await tester.pumpAndSettle();
      expect(scale(), 1);
      expect(taps, 1);
    });

    testWidgets('저사양 모드면 화면 전환이 바로 끝난다', (tester) async {
      await _pump(tester, const SizedBox(), reduced: true);
      final context = tester.element(find.byType(SizedBox).last);
      const builder = KitPageTransitions();
      const child = Text('B');
      final out = builder.buildTransitions(
        MaterialPageRoute<void>(builder: (_) => child),
        context,
        kAlwaysCompleteAnimation,
        kAlwaysDismissedAnimation,
        child,
      );
      expect(out, same(child));
    });
  });

  group('키트 조작 (설계서 §13 공통)', () {
    testWidgets('확인 창은 확정이면 true, 취소면 false 를 돌려준다', (tester) async {
      await _pump(tester, const SizedBox());
      final context = tester.element(find.byType(SizedBox).last);
      for (final (button, expected) in [('항복', true), ('취소', false)]) {
        bool? result;
        showPbConfirm(
          context,
          message: '이번 해전을 포기할까요?',
          cancel: '취소',
          confirm: '항복',
        ).then((v) => result = v).ignore();
        await tester.pumpAndSettle();
        await tester.tap(find.text(button));
        await tester.pumpAndSettle();
        expect(result, expected, reason: button);
      }
    });

    testWidgets('토글과 탭은 누른 값을 알려 준다', (tester) async {
      bool? toggled;
      int? tab;
      await _pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PbToggle(value: false, label: '진동', onChanged: (v) => toggled = v),
            PbTabs(
              labels: const ['가', '나'],
              selected: 0,
              onSelect: (i) => tab = i,
            ),
          ],
        ),
      );
      await tester.tap(find.byType(PbToggle));
      await tester.tap(find.text('나'));
      expect(toggled, isTrue);
      expect(tab, 1);
    });

    testWidgets('비활성 버튼은 눌러도 아무 일이 없다', (tester) async {
      await _pump(tester, const PbButton(label: '저장', onPressed: null));
      await tester.tap(find.text('저장'), warnIfMissed: false);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('스테이지 이름은 내부 id 가 아니라 번역 문장이다 (설계서 §13 공통)', (tester) async {
    await _pump(tester, const SizedBox());
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SizedBox).last),
    );
    final tutorial = testCampaign.sea(1).tutorial.first;
    final stage = testCampaign.stage('1-2');
    expect(stageName(l10n, tutorial), l10n.stageTutorialName(tutorial.number));
    expect(stageName(l10n, stage), l10n.stageNumberName(1, 2));
    expect(seaRegion(1), 'tropic');
    expect(seaRegion(9), 'gold');
  });
}
