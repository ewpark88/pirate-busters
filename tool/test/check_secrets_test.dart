import 'package:test/test.dart';

import '../check_secrets.dart';

void main() {
  group('비밀 정보 검사', () {
    test('서명 키 파일 이름을 거부한다', () {
      expect(checkSecrets('app/android/key.properties', null), isNotEmpty);
      expect(checkSecrets('upload.jks', null), isNotEmpty);
      expect(checkSecrets('.env.local', null), isNotEmpty);
    });

    test('예시 파일은 허용한다', () {
      expect(checkSecrets('app/android/key.properties.example', ''), isEmpty);
    });

    test('개인 키와 API 키 모양 문자열을 찾는다', () {
      const pem = 'x\n-----BEGIN PRIVATE KEY-----\n';
      expect(checkSecrets('a.txt', pem).single, contains('a.txt:2'));
      final api = 'key = "AIza${'A' * 35}"';
      expect(checkSecrets('lib/a.dart', api), isNotEmpty);
    });

    test('평범한 소스는 통과한다', () {
      expect(checkSecrets('lib/a.dart', 'void main() {}'), isEmpty);
    });
  });
}
