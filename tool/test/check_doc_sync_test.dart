import 'package:test/test.dart';

import '../check_doc_sync.dart';

void main() {
  test('줄바꿈이 CRLF 든 LF 든 같은 해시가 나온다', () {
    expect(docsHash(['a\r\nb', 'c\r\n']), docsHash(['a\nb', 'c\n']));
  });

  test('문서 순서가 바뀌면 해시가 다르다', () {
    expect(docsHash(['설계서', '밸런스']), isNot(docsHash(['밸런스', '설계서'])));
  });

  test('해시는 소문자 16진수 8자리다', () {
    expect(docsHash(['x']), matches(RegExp(r'^[0-9a-f]{8}$')));
    expect(docsHash(['']), matches(RegExp(r'^[0-9a-f]{8}$')));
  });
}
