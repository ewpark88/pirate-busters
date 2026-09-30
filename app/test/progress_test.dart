import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/progress_store.dart';

void main() {
  group('플레이어 진행 (설계서 §4.5, §6.1, §13.1)', () {
    test('경험치가 다음 레벨 필요량(100 × 레벨)을 넘으면 레벨이 오르고 나머지가 남는다', () {
      const p = PlayerProgress();
      final up = p.addXp(130);
      expect(up.level, 2);
      expect(up.xp, 30);
      expect(up.xpToNext, 200);
      expect(up.costLimit, greaterThan(p.costLimit));
    });

    test('한 번에 여러 레벨이 오를 수 있고 최고 레벨에서는 멈춘다', () {
      final p = const PlayerProgress().addXp(100 + 200 + 50);
      expect(p.level, 3);
      expect(p.xp, 50);
      final top = const PlayerProgress(level: 20).addXp(5000);
      expect(top.level, PlayerProgress.maxLevel);
      expect(top.xp, 5000);
    });

    test('스테이지 별은 최고치만 남긴다', () {
      final p = const PlayerProgress()
          .recordStage('1-1', 2)
          .recordStage('1-1', 1)
          .recordStage('1-2', 3);
      expect(p.starsOf('1-1'), 2);
      expect(p.starsOf('1-2'), 3);
      expect(p.hasCleared('1-3'), isFalse);
      expect(p.starsOf('1-3'), 0);
    });

    test('해적은 한 번만 얻고 얻은 순서를 지킨다', () {
      final p = const PlayerProgress()
          .addPirate('p01_octo')
          .addPirate('p36_tok')
          .addPirate('p01_octo');
      expect(p.ownedPirates, ['p01_octo', 'p36_tok']);
    });

    test('조선소는 4판째부터 열리고 튜토리얼은 3판이다', () {
      var p = const PlayerProgress();
      for (var i = 0; i < 3; i++) {
        expect(p.shipyardUnlocked, isFalse);
        p = p.countMatch();
      }
      expect(p.shipyardUnlocked, isTrue);
      expect(p.finishTutorial(2).finishTutorial(1).tutorialDone, 2);
      expect(p.finishTutorial(3).tutorialFinished, isTrue);
    });

    test('JSON 으로 저장했다 읽어도 같다', () {
      final p = const PlayerProgress()
          .addXp(250)
          .addGold(1200)
          .addPirate('p16_suri')
          .recordStage('1-5', 3)
          .seePrologue()
          .finishTutorial(3)
          .countMatch();
      final back = PlayerProgress.parse(p.encode());
      expect(back.toJson(), p.toJson());
    });

    test('저장이 비었거나 깨졌으면 새 진행이고 범위 밖 값은 잘린다', () {
      expect(PlayerProgress.parse(null).level, 1);
      expect(PlayerProgress.parse('{').gold, 0);
      final odd = PlayerProgress.fromJson({
        'level': 99,
        'stars': {'1-1': 7},
        'tutorialDone': 9,
        'ownedPirates': ['a', 3],
      });
      expect(odd.level, PlayerProgress.maxLevel);
      expect(odd.starsOf('1-1'), 3);
      expect(odd.tutorialDone, 3);
      expect(odd.ownedPirates, ['a']);
    });

    test('저장소에 넣으면 그대로 돌아온다', () async {
      final store = MemoryProgressStore();
      await store.save(const PlayerProgress().addGold(50));
      expect(store.progress.gold, 50);
    });
  });
}
