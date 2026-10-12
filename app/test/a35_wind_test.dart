import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/battle/battle_session.dart';
import 'package:pirate_busters/game/view/mast_painter.dart';
import 'package:pirate_busters/game/view/wind_streaks.dart';

import 'test_catalog.dart';

/// 첫 턴 바람이 [want] 조건을 만족하는 시드의 세션.
BattleSession _session(bool Function(int wind) want) {
  for (var seed = 1; ; seed++) {
    final m = testSetup.newMatch(seed);
    if (want(m.state.wind)) {
      return BattleSession(
        m,
        humanSides: const {0, 1},
        speciesOf: testCatalog.speciesOf,
      );
    }
  }
}

void main() {
  group('바람 줄 (설계서 §2.3·§10.2, A35)', () {
    test('단계가 높을수록 줄이 많고 빠르고 길며, 무풍이면 없다', () {
      expect(WindStreaks.countFor(0, low: false), 0);
      expect(
        WindStreaks.countFor(3, low: false),
        greaterThan(WindStreaks.countFor(1, low: false)),
      );
      expect(
        WindStreaks.countFor(-2, low: false),
        WindStreaks.countFor(2, low: false),
      );
      expect(WindStreaks.speedFor(3), greaterThan(WindStreaks.speedFor(1)));
      expect(WindStreaks.lengthFor(3), greaterThan(WindStreaks.lengthFor(1)));
    });

    test('저사양이면 줄 수를 절반으로 줄인다 (설계서 §12)', () {
      expect(
        WindStreaks.countFor(2, low: true),
        WindStreaks.countFor(2, low: false) ~/ 2,
      );
    });

    test('바람이 있으면 그 단계만큼 줄이 생기고, 무풍이면 없다', () {
      final windy = _session((w) => w.abs() >= 2);
      final streaks = WindStreaks(session: windy)..update(0.1);
      expect(
        streaks.count,
        WindStreaks.countFor(windy.state.wind, low: false),
      );
      final calm = _session((w) => w == 0);
      final none = WindStreaks(session: calm)..update(0.1);
      expect(none.count, 0);
      final low = WindStreaks(session: windy, lowEnd: ValueNotifier(true))
        ..update(0.1);
      expect(low.count, lessThan(streaks.count));
    });
  });

  group('돛·깃발 펄럭임 (설계서 §10.2, A35)', () {
    test('돛은 바람 쪽으로 밀리고 세기에 비례하며, 무풍이면 곧다', () {
      double skew(double s, int dir) =>
          MastPainter.sailSkew((strength: s, dir: dir, t: 0));
      expect(skew(0, 0), 0);
      expect(skew(1, 1), greaterThan(0));
      expect(skew(1, -1), lessThan(0));
      expect(skew(1, 1).abs(), greaterThan(skew(.3, 1).abs()));
    });

    test('깃발은 무풍이면 처지고 바람이 셀수록 펴진다', () {
      double droop(double s) =>
          MastPainter.flagDroop((strength: s, dir: 1, t: 0));
      expect(droop(0), greaterThan(droop(.5)));
      expect(droop(1), 0);
    });
  });
}
