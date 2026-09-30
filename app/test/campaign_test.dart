import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ai/pb_ai.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/campaign/campaign_catalog.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/campaign/star_rules.dart';

import 'test_catalog.dart';

MatchSummary summary({
  bool won = true,
  MatchOutcome outcome = MatchOutcome.sunk,
  int turns = 10,
  int flood = 10,
  int hull = 80,
  int down = 0,
}) => MatchSummary(
  won: won,
  outcome: outcome,
  turns: turns,
  floodPercent: flood,
  hullPercent: hull,
  piratesDown: down,
  shotsFired: 12,
);

void main() {
  final sea1Json = File('assets/stages/sea1.json').readAsStringSync();
  final campaign = CampaignCatalog.parse([sea1Json], testCatalog);
  final sea1 = campaign.sea(1);

  group('캠페인 데이터 (설계서 §6.1, §13.1, §4.6)', () {
    test('해역 1 은 튜토리얼 3판과 캠페인 6판(1-1~1-5, 1-12)이다', () {
      expect(sea1.tutorial.map((s) => s.tutorialStep), [1, 2, 3]);
      expect(sea1.campaign.map((s) => s.id), [
        '1-1',
        '1-2',
        '1-3',
        '1-4',
        '1-5',
        '1-12',
      ]);
      expect(sea1.byId('1-5').kind, StageKind.midBoss);
      expect(sea1.byId('1-12').kind, StageKind.boss);
    });

    test('확정 보상 해적은 1-2 수리, 1-4 폴리, 1-5 팡, 1-12 샤키다 (§4.6)', () {
      expect(sea1.byId('1-2').rewardPirate, 'p16_suri');
      expect(sea1.byId('1-4').rewardPirate, 'p26_polly');
      expect(sea1.byId('1-5').rewardPirate, 'p06_pang');
      expect(sea1.byId('1-12').rewardPirate, 'p31_sharky');
      expect(sea1.byId('1-1').rewardPirate, isNull);
    });

    test('적 덱·설계도·보상 해적이 모두 게임 데이터에 있다', () {
      expect(
        sea1.problems(
          hasPirate: testCatalog.pirates.has,
          hasPreset: (id) => testCatalog.presets.any((p) => p.id == id),
        ),
        isEmpty,
      );
      expect(campaign.stage('1-3').aiLevel, AiLevel.easy);
      expect(campaign.stage('1-3').personality, Personality.hunter);
    });

    test('대사·미션 글자 키가 한국어·영어 ARB 에 모두 있다 (§14.3, §15.4)', () {
      final ko =
          jsonDecode(
                File('lib/l10n/app_ko.arb').readAsStringSync(),
              )
              as Map<String, Object?>;
      final en =
          jsonDecode(
                File('lib/l10n/app_en.arb').readAsStringSync(),
              )
              as Map<String, Object?>;
      for (final s in sea1.stages) {
        for (final key in [...s.dialogueKeys, s.mission.textKey]) {
          expect(ko, contains(key), reason: '${s.id} $key ko');
          expect(en, contains(key), reason: '${s.id} $key en');
        }
      }
    });

    test('모르는 미션·난이도·겹치는 id 는 형식 오류다', () {
      Object? stage(Map<String, Object?> over) => {
        'sea': 1,
        'stages': [
          {
            'id': '1-1',
            'kind': 'normal',
            'enemyPreset': 'balanced',
            'enemyDeck': ['p06_pang'],
            'aiLevel': 'easy',
            'personality': 'bombard',
            'starTurns': 12,
            'mission': {'type': 'no_pirate_down'},
            'dialogueKeys': <String>[],
            ...over,
          },
        ],
      };
      expect(
        () => SeaSpec.fromJson(
          stage({
            'mission': {'type': 'dance'},
          }),
        ),
        throwsA(isA<DataFormatError>()),
      );
      expect(
        () => SeaSpec.fromJson(stage({'aiLevel': 'god'})),
        throwsA(isA<DataFormatError>()),
      );
      expect(
        () => SeaSpec.fromJson(stage({'id': '2-1'})),
        throwsA(isA<DataFormatError>()),
      );
      expect(
        () => CampaignCatalog.parse([
          jsonEncode(
            stage({
              'enemyDeck': ['p99_nobody'],
            }),
          ),
        ], testCatalog),
        throwsArgumentError,
      );
    });
  });

  group('별 판정 (설계서 §6.1)', () {
    const rules = StarRules();
    final s11 = sea1.byId('1-1'); // 미션: 해적 KO 없음, 12턴 이내

    test('지면 별이 없고, 이기면 1개, 턴 안이면 2개, 미션까지 하면 3개', () {
      expect(rules.evaluate(s11, summary(won: false)).count, 0);
      expect(rules.evaluate(s11, summary(turns: 20, down: 1)).count, 1);
      expect(rules.evaluate(s11, summary(turns: 12, down: 1)).count, 2);
      expect(rules.evaluate(s11, summary(turns: 8)).count, 3);
      expect(rules.evaluate(s11, summary(turns: 20)).count, 2);
    });

    test('미션 5종이 요약 값으로 판정된다', () {
      MissionSpec m(String type, [Map<String, int> p = const {}]) =>
          MissionSpec(type: type, params: p);
      expect(
        rules.missionDone(
          m('flood_below', {'percent': 30}),
          summary(flood: 30),
        ),
        isTrue,
      );
      expect(
        rules.missionDone(
          m('flood_below', {'percent': 30}),
          summary(flood: 31),
        ),
        isFalse,
      );
      expect(
        rules.missionDone(m('hull_above', {'percent': 60}), summary(hull: 59)),
        isFalse,
      );
      expect(
        rules.missionDone(
          m('win_by_sink'),
          summary(outcome: MatchOutcome.floodSunk),
        ),
        isTrue,
      );
      expect(
        rules.missionDone(
          m('win_by_sink'),
          summary(outcome: MatchOutcome.annihilation),
        ),
        isFalse,
      );
      expect(
        rules.missionDone(m('turns_within', {'turns': 10}), summary(turns: 11)),
        isFalse,
      );
    });

    test('끝난 판의 상태에서 요약을 만든다', () {
      final match = testSetup.newMatch(7);
      final state = match.state;
      final me = MatchSummary.fromState(state, 0);
      expect(me.won, isFalse);
      expect(me.turns, 1);
      expect(me.floodPercent, 0);
      expect(me.hullPercent, 100);
      expect(me.piratesDown, 0);
    });
  });
}
