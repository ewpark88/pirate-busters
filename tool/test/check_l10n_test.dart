import 'package:test/test.dart';

import '../check_l10n.dart';

void main() {
  group('ARB 짝 검사', () {
    test('키와 플레이스홀더가 같으면 통과한다', () {
      final ko = {
        '@@locale': 'ko',
        'hello': '{name}님 안녕',
        '@hello': <String, dynamic>{},
      };
      final en = {'@@locale': 'en', 'hello': 'Hi {name}'};
      expect(compareArb(ko, en), isEmpty);
    });

    test('한쪽에만 있는 키를 찾는다', () {
      final errors = compareArb({'a': '가', 'b': '나'}, {'a': 'A', 'c': 'C'});
      expect(errors, hasLength(2));
    });

    test('플레이스홀더가 다르면 찾는다', () {
      expect(compareArb({'a': '{n}개'}, {'a': '{count} items'}), hasLength(1));
    });

    test('ICU 복수형 본문은 플레이스홀더로 보지 않는다', () {
      expect(
        compareArb(
          {'a': '쉬는 턴 {count}'},
          {'a': '{count, plural, =1{Rest 1 turn} other{Rest {count} turns}}'},
        ),
        isEmpty,
      );
    });

    test('플레이스홀더가 2개 이상인데 인자 순서 정의가 없으면 찾는다', () {
      expect(
        compareArb(
          {'a': '코스트 {used} / {limit}'},
          {'a': 'Cost {used} / {limit}'},
        ),
        hasLength(1),
      );
    });

    test('플레이스홀더가 2개 이상이어도 인자 순서 정의가 있으면 통과한다', () {
      expect(
        compareArb(
          {'a': '코스트 {used} / {limit}'},
          {
            'a': 'Cost {used} / {limit}',
            '@a': {
              'placeholders': {
                'used': <String, dynamic>{},
                'limit': <String, dynamic>{},
              },
            },
          },
        ),
        isEmpty,
      );
    });

    test('빈 값을 찾는다', () {
      expect(compareArb({'a': ''}, {'a': 'A'}), hasLength(1));
    });
  });

  group('직접 쓴 문장 검사 (설계서 §14.5)', () {
    test('한글 문자열과 Text 안의 영어 문장을 찾는다', () {
      const src = '''
final a = Text('턴 종료');
final b = Text('End turn');
final c = label ?? '대기';
''';
      expect(findHardcodedText('x.dart', src), hasLength(3));
    });

    test('로그·오류·주석·숫자·키·경로는 봐 준다', () {
      const src = r'''
// 한국어 주석은 괜찮다
debugPrint('효과음 실패');
throw ArgumentError('잘못된 값');
final t = Text('$seconds');
final u = Text(l10n.endTurn); // 턴 종료
final v = 'assets/images/octo.png';
''';
      expect(findHardcodedText('x.dart', src), isEmpty);
    });
  });
}
