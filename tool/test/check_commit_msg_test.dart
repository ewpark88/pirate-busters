import 'package:test/test.dart';

import '../check_commit_msg.dart';

void main() {
  group('커밋 메시지 검사', () {
    test('규칙에 맞는 메시지는 통과한다', () {
      expect(checkCommitMessage('feat(sim): 턴 루프·탄도·타격·붕괴 (M2)'), isEmpty);
      expect(
        checkCommitMessage('fix(app): 버튼 겹침\n\n본문 설명\n\nCo-Authored-By: x'),
        isEmpty,
      );
    });

    test('머지와 되돌리기 메시지는 검사하지 않는다', () {
      expect(checkCommitMessage("Merge branch 'feat/M1-sim-core'"), isEmpty);
      expect(checkCommitMessage('Revert "feat(sim): x"'), isEmpty);
    });

    test('scope 가 없으면 거부한다', () {
      expect(checkCommitMessage('feat: 무언가'), isNotEmpty);
    });

    test('허용되지 않은 type 과 scope 를 거부한다', () {
      final errors = checkCommitMessage('feature(engine): 무언가');
      expect(errors, hasLength(2));
    });

    test('첫 줄이 너무 길면 거부한다', () {
      expect(checkCommitMessage('feat(sim): ${'가' * 80}'), isNotEmpty);
    });

    test('요약 끝의 마침표와 본문 앞 빈 줄 누락을 거부한다', () {
      expect(checkCommitMessage('docs(docs): 고침.'), isNotEmpty);
      expect(checkCommitMessage('docs(docs): 고침\n바로 본문'), isNotEmpty);
    });

    test('git 주석 줄은 무시한다', () {
      expect(checkCommitMessage('# 주석\nci(tool): CI 추가\n# 끝'), isEmpty);
    });
  });
}
