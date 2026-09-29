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

    test('빈 값을 찾는다', () {
      expect(compareArb({'a': ''}, {'a': 'A'}), hasLength(1));
    });
  });
}
