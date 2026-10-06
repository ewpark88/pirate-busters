import 'package:flutter_test/flutter_test.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/battle/battle_setup.dart';
import 'package:pirate_busters/battle/speech_director.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';
import 'package:pirate_busters/settings/language.dart';
import 'package:pirate_busters/ui/hud/speech_bubbles.dart';

import 'test_catalog.dart';

Match _match() =>
    BattleSetup(testCatalog).newStageMatch(5, testCampaign.stage('1-1'));

void _endTurn(Match m) => m.apply(const EndTurnCommand(t: 10));

void main() {
  group('전투 중 말풍선 (설계서 §15.4)', () {
    test('맞으면 그 해적이 말하고, 한 턴에 하나만 나온다', () {
      final m = _match();
      final d = SpeechDirector(me: 0);
      expect(d.observe(m.state), isNull, reason: '첫 관찰은 기준만 잡는다');
      final crew = m.state.sides[0].crew.pirates;
      crew[1].hp -= 10;
      final bark = d.observe(m.state)!;
      expect([bark.kind, bark.slot], [BarkKind.hurt, 1]);
      crew[0].hp -= 10;
      expect(d.observe(m.state), isNull, reason: '같은 턴');
      _endTurn(m);
      crew[0].hp -= 10;
      expect(d.observe(m.state)?.kind, BarkKind.hurt);
    });

    test('동료가 쓰러지면 살아 있는 다른 해적이 말하고, 맞음보다 앞선다', () {
      final m = _match();
      final d = SpeechDirector(me: 0)..observe(m.state);
      final crew = m.state.sides[0].crew.pirates;
      crew[0]
        ..hp = 0
        ..status = PirateStatus.down;
      crew[1].hp -= 5;
      final bark = d.observe(m.state)!;
      expect([bark.kind, bark.slot], [BarkKind.allyDown, 1]);
    });

    test('캠페인에서는 상대 선장이 상대 턴에 한 번 도발하고, 선체가 60% 아래면 한 번 더 말한다', () {
      final m = _match();
      final d = SpeechDirector(me: 0, captain: true)..observe(m.state);
      Bark? next() {
        _endTurn(m);
        return d.observe(m.state);
      }

      final barks = [for (var i = 0; i < 4; i++) next()];
      expect(barks.whereType<Bark>().map((b) => b.kind), [
        BarkKind.tauntStart,
      ]);
      final grid = m.state.sides[1].grid;
      for (
        var i = 0;
        i < grid.cellCount && grid.totalHp * 100 >= grid.initialTotalHp * 59;
        i++
      ) {
        grid.removeAt(i);
      }
      expect(next()?.kind, BarkKind.tauntLow);
      expect(next(), isNull, reason: '선체 낮음은 한 번만');
    });

    test('같은 판 흐름이면 같은 줄을 고르고, 모든 줄이 두 언어에 있다', () async {
      Bark? run() {
        final m = _match();
        final d = SpeechDirector(me: 0)..observe(m.state);
        m.state.sides[0].crew.pirates[0].hp -= 3;
        return d.observe(m.state);
      }

      expect(run(), run());
      for (final locale in supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final kind in BarkKind.values) {
          final lines = {
            for (var i = 1; i <= SpeechDirector.lines; i++)
              barkText(l10n, kind, i),
          };
          expect(
            lines,
            hasLength(SpeechDirector.lines),
            reason: '$locale $kind',
          );
        }
      }
    });
  });
}
