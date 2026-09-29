import 'package:test/test.dart';

import '../release.dart';

void main() {
  const pubspec = 'name: x\nversion: 0.2.0+1\n';
  const changelog =
      '# Changelog\n\n## [Unreleased]\n\n### Added\n- 파도\n\n'
      '## [0.2.0] - 2026-09-29\n\n### Added\n- 턴 루프\n';

  group('릴리스 도우미', () {
    test('pubspec 버전을 읽고 쓴다', () {
      final v = readVersion(pubspec);
      expect(v.toString(), '0.2.0+1');
      expect(
        writeVersion(pubspec, bumpVersion(v, 'patch')),
        contains('0.2.1+2'),
      );
    });

    test('bump 는 종류대로 올리고 BUILD 는 항상 1 올린다', () {
      const v = AppVersion(0, 2, 3, 7);
      expect(bumpVersion(v, 'minor').toString(), '0.3.0+8');
      expect(bumpVersion(v, 'major').toString(), '1.0.0+8');
      expect(bumpVersion(v, '0.3.0').toString(), '0.3.0+8');
      expect(() => bumpVersion(v, 'huge'), throwsFormatException);
    });

    test('Unreleased 내용을 새 버전 절로 옮긴다', () {
      final out = promoteChangelog(changelog, '0.3.0', '2026-10-01');
      expect(out, contains('## [Unreleased]\n\n## [0.3.0] - 2026-10-01'));
      expect(changelogSection(out, '0.3.0'), contains('- 파도'));
      expect(changelogSection(out, '0.2.0'), contains('- 턴 루프'));
      expect(changelogSection(out, 'Unreleased'), isEmpty);
    });

    test('Unreleased 가 비면 bump 를 거부한다', () {
      const empty = '## [Unreleased]\n\n## [0.2.0] - x\n\n- a\n';
      expect(
        () => promoteChangelog(empty, '0.3.0', 'd'),
        throwsFormatException,
      );
    });

    test('태그와 pubspec·CHANGELOG 가 맞는지 검사한다', () {
      const v = AppVersion(0, 2, 0, 1);
      expect(checkRelease(v, changelog, 'v0.2.0+1'), isEmpty);
      expect(checkRelease(v, changelog, 'v0.2.0'), isEmpty);
      expect(checkRelease(v, changelog, 'v0.2.1'), hasLength(1));
      expect(
        checkRelease(const AppVersion(0, 9, 0, 1), changelog, null),
        hasLength(1),
      );
    });
  });
}
