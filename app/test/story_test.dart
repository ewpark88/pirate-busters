import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/story/cutscene_screen.dart';
import 'package:pirate_busters/story/story_data.dart';

void main() {
  group('컷신 데이터 (설계서 §15.2, §15.4)', () {
    test('프롤로그는 5컷, 해역 인트로 1~2컷, 중간 보스 전후 1컷, 보스 전후 2~3컷', () {
      expect(StoryData.of(StoryData.prologue)!.length, 5);
      expect(StoryData.of(StoryData.sea1Intro)!.length, inInclusiveRange(1, 2));
      expect(StoryData.of(StoryData.bossBefore('1-5'))!.length, 1);
      expect(StoryData.of(StoryData.bossAfter('1-5'))!.length, 1);
      expect(
        StoryData.of(StoryData.bossBefore('1-12'))!.length,
        inInclusiveRange(2, 3),
      );
      expect(
        StoryData.of(StoryData.bossAfter('1-12'))!.length,
        inInclusiveRange(2, 3),
      );
      expect(StoryData.of('nothing'), isNull);
    });

    test('대사 키는 두 ARB 에, 초상은 에셋에 있다 (§14.3, 0원 원칙)', () {
      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync()) as Map;
      final en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
      for (final cuts in StoryData.cuts.values) {
        for (final cut in cuts) {
          expect(ko, contains(cut.textKey));
          expect(en, contains(cut.textKey));
          final species = cut.species;
          if (species != null) {
            final team = cut.enemy ? 'red' : 'blue';
            expect(
              File(
                'assets/images/ui/portraits/${species}_$team.png',
              ).existsSync(),
              isTrue,
              reason: species,
            );
          }
        }
      }
    });
  });

  group('본 컷신 저장', () {
    test('본 컷신은 한 번만 남고 JSON 을 오간다', () {
      final p = const PlayerProgress()
          .seeStory('prologue')
          .seeStory('prologue')
          .seeStory('sea_1_intro');
      expect(p.seenStories, ['prologue', 'sea_1_intro']);
      expect(PlayerProgress.parse(p.encode()).hasSeen('sea_1_intro'), isTrue);
    });
  });

  group('컷신 화면', () {
    Future<void> pump(WidgetTester tester, Locale locale) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => CutsceneScreen.show(
                    context,
                    StoryData.of(StoryData.prologue)!,
                  ),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    for (final locale in const [Locale('ko'), Locale('en')]) {
      testWidgets('탭하면 다음 컷, 마지막 컷 뒤에는 닫힌다 (${locale.languageCode})', (
        tester,
      ) async {
        await pump(tester, locale);
        expect(find.text('1 / 5'), findsOneWidget);
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.text('${i + 1} / 5'));
          await tester.pump();
        }
        expect(find.text('5 / 5'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('5 / 5'));
        await tester.pumpAndSettle();
        expect(find.byType(CutsceneScreen), findsNothing);
      });
    }

    testWidgets('건너뛰기를 누르면 바로 닫힌다', (tester) async {
      await pump(tester, const Locale('ko'));
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      await tester.tap(find.text(l10n.storySkip));
      await tester.pumpAndSettle();
      expect(find.byType(CutsceneScreen), findsNothing);
    });
  });
}
