import 'package:pb_ai/pb_ai.dart';
import 'package:test/test.dart';

void main() {
  group('AI 다이얼 원격 덮어쓰기 (설계서 §7.4, 개발 계획서 A9)', () {
    test('ai_<난이도>_<다이얼> 키만 바꾸고 다른 난이도는 그대로다', () {
      final hard = AiDials.withOverrides(
        AiLevel.hard,
        (k) => switch (k) {
          'ai_hard_thinkMs' => 400,
          'ai_hard_timeMode' => 0,
          'ai_easy_thinkMs' => 1,
          _ => null,
        },
      );
      expect(hard.thinkMs, 400);
      expect(hard.timeMode, isFalse);
      expect(hard.angleErrorMdeg, AiDials.of(AiLevel.hard).angleErrorMdeg);
      expect(
        AiDials.withOverrides(AiLevel.normal, (_) => null).thinkMs,
        AiDials.of(AiLevel.normal).thinkMs,
      );
    });

    test('범위 밖 값(퍼센트 101, bool 2, support 순번 밖)은 무시한다', () {
      final d = AiDials.withOverrides(
        AiLevel.easy,
        (k) => switch (k) {
          'ai_easy_pickTopPercent' => 101,
          'ai_easy_combo' => 2,
          'ai_easy_support' => SupportUse.values.length,
          'ai_easy_positions' => -1,
          _ => null,
        },
      );
      final base = AiDials.of(AiLevel.easy);
      expect(d.pickTopPercent, base.pickTopPercent);
      expect(d.combo, base.combo);
      expect(d.support, base.support);
      expect(d.positions, base.positions);
    });

    test('컨트롤러에 다이얼을 주면 계획기가 그 값을 쓴다', () {
      final dials = AiDials.of(AiLevel.easy).copyWith(thinkMs: 123);
      final c = AiController(level: AiLevel.easy, dials: dials);
      expect(c.dials?.thinkMs, 123);
      expect(const AiController(level: AiLevel.easy).dials, isNull);
    });
  });
}
