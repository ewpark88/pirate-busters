import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/campaign/star_rules.dart';
import 'package:pirate_busters/game/finale_director.dart';
import 'package:pirate_busters/game/view/wind_feel.dart';
import 'package:pirate_busters/game/view/wind_streaks.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/ui/cards/card_icons.dart';
import 'package:pirate_busters/ui/hud/battle_banners.dart';

import 'test_catalog.dart';

/// 앱 사후 점검 남은 일 (설계서 §2.7·§10.4·§13.5·§13.7, ADR-111).
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

/// 오른쪽 선장실 블록을 [amount] 깎는다(해적 체력은 그대로).
void _chipCaptain(MatchState s, int amount) {
  final right = s.sides[1];
  final m = right.modules.list.firstWhere((m) => m.kind == ModuleKind.captain);
  right.grid.damage(m.x, m.y, amount);
}

void main() {
  testWidgets('두 사람이 번갈아 두는 판의 턴 제한 배너는 플레이어 1·2 로 적고, 선장실로 가린 이유를 보여 준다', (
    tester,
  ) async {
    final session = BattleSession(
      testSetup.newMatch(3),
      humanSides: const {0, 1},
      speciesOf: testCatalog.speciesOf,
    );
    _chipCaptain(session.state, 10);
    session.state
      ..outcome = MatchOutcome.timeDecision
      ..winner = timeLeader(session.state);
    final banner = ValueNotifier<BattleBanner?>(
      const BattleBanner(BattleBannerKind.timeDecision, 1),
    );
    await tester.pumpWidget(
      _app(BattleBanners(session: session, banner: banner, myTurn: true)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('플레이어 1 100% : 플레이어 2 100%'), findsOneWidget);
    expect(find.byKey(const ValueKey('end-by-captain')), findsOneWidget);
    expect(find.text('체력 같음: 선장실 비교'), findsOneWidget);
  });

  test('결과 요약은 턴 제한이 선장실로 가려졌는지 담는다 (설계서 §13.5)', () {
    final state = testSetup.newMatch(3).state;
    _chipCaptain(state, 10);
    state
      ..outcome = MatchOutcome.timeDecision
      ..winner = timeLeader(state);
    expect(MatchSummary.fromState(state, 0).byCaptain, isTrue);
    state.sides[0].crew.damage(0, 10, 0, state.events);
    expect(MatchSummary.fromState(state, 0).byCaptain, isFalse);
  });

  testWidgets('선원 카드 아이콘 줄에는 코스트만 있고 보류된 세트 아이콘은 없다', (tester) async {
    final spec = testCatalog.pirates.byId('p01_octo');
    await tester.pumpWidget(
      _app(CardIcons.column(spec)),
    );
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(1));
    expect(
      (images.single.image as AssetImage).assetName,
      CardIcons.cost(spec.cost),
    );
  });

  test('바람 줄은 부드럽게 따라가는 바람을 따른다: 턴 바람이 바뀌어도 한 번에 꺾이지 않는다', () {
    final session = BattleSession(
      testSetup.newMatch(3),
      humanSides: const {0},
      speciesOf: testCatalog.speciesOf,
    );
    session.state.wind = 3;
    final feel = WindFeel(session: session)..value = 0;
    final streaks = WindStreaks(session: session, feel: feel)..update(.1);
    expect(streaks.count, 0, reason: '느끼는 바람은 아직 무풍');
    feel.value = 3;
    streaks.update(.1);
    expect(streaks.count, WindStreaks.countFor(3, low: false));
  });
}
