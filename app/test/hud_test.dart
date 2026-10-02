import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/battle/session_views.dart';
import 'package:pirate_busters/game/view/shot_view.dart';
import 'package:pirate_busters/input/pull_aim.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/settings/settings_store.dart';
import 'package:pirate_busters/ui/cards/rarity_card.dart';
import 'package:pirate_busters/ui/hud/battle_hud.dart';
import 'package:pirate_busters/ui/kit/pb_panel.dart';
import 'test_catalog.dart';

Future<BattleSession> _pumpHud(
  WidgetTester tester,
  Locale locale, {
  bool paused = false,
}) async {
  // 작은 가로 폰(논리 640×360).
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final session = BattleSession(
    testSetup.newMatch(3),
    humanSides: const {0, 1},
    speciesOf: testCatalog.speciesOf,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: BattleHud(
            session: session,
            overview: ValueNotifier(false),
            paused: paused,
            onPause: (_) {},
            onRestart: ({hotseat}) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return session;
}

void main() {
  group('전투 HUD 두 언어 (설계서 §13.4, §14)', () {
    testWidgets('한국어로 HUD 글자가 나오고 넘치지 않는다', (tester) async {
      await _pumpHud(tester, const Locale('ko'));
      expect(find.text('턴 종료'), findsOneWidget);
      expect(find.text('남은 턴 30'), findsOneWidget);
      expect(find.text('연료'), findsWidgets);
      expect(find.textContaining('침수'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('영어로 HUD 글자가 나오고 넘치지 않는다', (tester) async {
      await _pumpHud(tester, const Locale('en'));
      expect(find.text('End turn'), findsOneWidget);
      expect(find.text('30 turns left'), findsOneWidget);
      expect(find.text('Fuel'), findsWidgets);
      expect(find.textContaining('Flood'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('일시정지 창이 두 언어로 나오고 넘치지 않는다', (tester) async {
      for (final locale in supportedLocales) {
        await _pumpHud(tester, locale, paused: true);
        // 상대 선택 2개뿐. 언어는 전투 중에 바꾸지 않는다(설계서 §14.1).
        // 상대 고르기는 키트 탭 두 개다 (설계서 §13 공통).
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.byType(PbTabs), findsOneWidget);
        expect(find.text(l10n.opponentAi), findsOneWidget);
        expect(find.text(l10n.language), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('턴 종료 버튼을 누르면 턴이 넘어간다', (tester) async {
      final session = await _pumpHud(tester, const Locale('en'));
      final side = session.state.activeSide;
      await tester.tap(find.text('End turn'));
      await tester.pump();
      expect(session.state.activeSide, 1 - side);
    });

    testWidgets('카드를 누르면 해적을 고르고, 카드를 끌어도 쏘지 않는다 (ADR-033)', (
      tester,
    ) async {
      final session = await _pumpHud(tester, const Locale('en'));
      final side = session.state.activeSide;
      // 카드는 등급 프레임 카드로 찾는다 (설계서 §10.5).
      final card = find.byType(RarityCard).first;
      await tester.tap(card);
      await tester.pump();
      expect(session.selected, isNotNull);
      await tester.drag(card, const Offset(-80, 80));
      await tester.pump();
      expect(session.state.sides[side].shotsFired, 0);
    });
  });

  group('연출 중 HUD와 탄 시인성 (설계서 §13.4, §10.4, A17)', () {
    testWidgets('조준하는 동안 위쪽 정보가 흐려졌다가 그만두면 돌아온다', (tester) async {
      final session = await _pumpHud(tester, const Locale('ko'));
      double top() => tester
          .widget<AnimatedOpacity>(find.byKey(const ValueKey('hud-top')))
          .opacity;
      expect(top(), 1);
      session.setAim(0, const AimShot(angle: 30000, power: 500), 0.5);
      await tester.pumpAndSettle();
      expect(top(), BattleHud.busyOpacity);
      session.clearAim();
      await tester.pumpAndSettle();
      expect(top(), 1);
    });

    testWidgets('카운트다운은 화면 위쪽(턴 타이머 아래)에 뜬다', (tester) async {
      final session = await _pumpHud(tester, const Locale('ko'));
      session.update(session.remainingMs - 3000);
      await tester.pump();
      final y = tester.getCenter(find.byKey(const ValueKey('countdown'))).dy;
      expect(y, lessThan(360 * 0.3), reason: '배가 있는 화면 가운데를 가리지 않는다');
    });

    test('멀리 뺀 화면에서도 탄이 화면에서 최소 크기 이상이다', () {
      for (final zoom in [0.2, 0.35, 0.6, 1.0, 2.0]) {
        final screen = 18 * ShotView.visibleScale(zoom) * zoom;
        expect(
          screen,
          greaterThanOrEqualTo(ShotView.minScreenPx - 0.01),
          reason: 'zoom $zoom',
        );
      }
      expect(ShotView.visibleScale(2), 1, reason: '가까우면 원래 크기');
    });
  });
}
