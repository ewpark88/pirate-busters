// 릴리스 도우미 (docs/RELEASE.md, ADR-015).
// 사용법:
//   dart run tool/release.dart bump <patch|minor|major|X.Y.Z>  # 버전·BUILD 올리고 CHANGELOG 정리
//   dart run tool/release.dart check [vX.Y.Z+B]                 # 태그·pubspec·CHANGELOG 일치 검사
//   dart run tool/release.dart notes [X.Y.Z]                    # CHANGELOG 의 해당 절 출력
import 'dart:io';

const pubspecPath = 'app/pubspec.yaml';
const changelogPath = 'CHANGELOG.md';

final _versionLineRe = RegExp(
  r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
  multiLine: true,
);

/// `X.Y.Z+BUILD` 앱 버전.
class AppVersion {
  const AppVersion(this.major, this.minor, this.patch, this.build);

  final int major;
  final int minor;
  final int patch;
  final int build;

  String get name => '$major.$minor.$patch';

  @override
  String toString() => '$name+$build';
}

/// pubspec 본문에서 버전을 읽는다.
AppVersion readVersion(String pubspec) {
  final m = _versionLineRe.firstMatch(pubspec);
  if (m == null) throw const FormatException('pubspec 에 version: X.Y.Z+B 가 없다');
  int g(int i) => int.parse(m.group(i)!);
  return AppVersion(g(1), g(2), g(3), g(4));
}

/// [current] 에서 [kind](patch|minor|major|X.Y.Z)만큼 올린 버전. BUILD 는 항상 +1.
AppVersion bumpVersion(AppVersion current, String kind) {
  final next = current.build + 1;
  switch (kind) {
    case 'patch':
      return AppVersion(current.major, current.minor, current.patch + 1, next);
    case 'minor':
      return AppVersion(current.major, current.minor + 1, 0, next);
    case 'major':
      return AppVersion(current.major + 1, 0, 0, next);
  }
  final m = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(kind);
  if (m == null) throw FormatException('알 수 없는 bump 종류: $kind');
  return AppVersion(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    next,
  );
}

String writeVersion(String pubspec, AppVersion v) =>
    pubspec.replaceFirst(_versionLineRe, 'version: $v');

/// `## [Unreleased]` 아래 내용을 `## [name] - date` 절로 옮기고 빈 Unreleased 를 남긴다.
String promoteChangelog(String changelog, String name, String date) {
  const head = '## [Unreleased]';
  final start = changelog.indexOf(head);
  if (start < 0) {
    throw const FormatException('CHANGELOG 에 ## [Unreleased] 가 없다');
  }
  final bodyStart = start + head.length;
  final nextHead = changelog.indexOf('\n## [', bodyStart);
  final body = changelog
      .substring(bodyStart, nextHead < 0 ? changelog.length : nextHead)
      .trim();
  if (body.isEmpty) {
    throw const FormatException('[Unreleased] 가 비어 있다. 바뀐 점을 먼저 적는다');
  }
  final rest = nextHead < 0 ? '' : changelog.substring(nextHead);
  return '${changelog.substring(0, start)}$head\n\n## [$name] - $date\n\n$body\n$rest';
}

/// CHANGELOG 에서 `## [name]` 절 본문. 없으면 null.
String? changelogSection(String changelog, String name) {
  final head = RegExp('^## \\[${RegExp.escape(name)}\\].*\$', multiLine: true);
  final m = head.firstMatch(changelog);
  if (m == null) return null;
  final next = changelog.indexOf('\n## [', m.end);
  return changelog.substring(m.end, next < 0 ? changelog.length : next).trim();
}

/// 태그 `vX.Y.Z+B` 또는 `vX.Y.Z` 가 pubspec·CHANGELOG 와 맞는지. 위반 목록.
List<String> checkRelease(AppVersion v, String changelog, String? tag) {
  final errors = <String>[];
  if (tag != null) {
    final t = tag.startsWith('v') ? tag.substring(1) : tag;
    if (t != v.toString() && t != v.name) {
      errors.add('태그 $tag 와 pubspec 버전 $v 가 다르다');
    }
  }
  final section = changelogSection(changelog, v.name);
  if (section == null || section.isEmpty) {
    errors.add('CHANGELOG 에 ## [${v.name}] 절이 없거나 비어 있다');
  }
  return errors;
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('사용법: release.dart bump|check|notes ...');
    exitCode = 2;
    return;
  }
  final pubspecFile = File(pubspecPath);
  final changelogFile = File(changelogPath);
  final version = readVersion(pubspecFile.readAsStringSync());
  final changelog = changelogFile.readAsStringSync();
  switch (args[0]) {
    case 'bump':
      if (args.length != 2) {
        stderr.writeln('사용법: release.dart bump <patch|minor|major|X.Y.Z>');
        exitCode = 2;
        return;
      }
      final next = bumpVersion(version, args[1]);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      changelogFile.writeAsStringSync(
        promoteChangelog(changelog, next.name, today),
      );
      pubspecFile.writeAsStringSync(
        writeVersion(pubspecFile.readAsStringSync(), next),
      );
      stdout
        ..writeln('$version → $next')
        ..writeln(
          '다음: bash tool/verify.sh → 커밋 chore(release): v$next → 태그 v$next',
        );
    case 'check':
      final errors = checkRelease(
        version,
        changelog,
        args.length > 1 ? args[1] : null,
      );
      if (errors.isEmpty) {
        stdout.writeln('release OK ($version)');
        return;
      }
      errors.forEach(stderr.writeln);
      exitCode = 1;
    case 'notes':
      final name = args.length > 1 ? args[1] : version.name;
      final section = changelogSection(changelog, name);
      if (section == null) {
        stderr.writeln('CHANGELOG 에 [$name] 절이 없다');
        exitCode = 1;
        return;
      }
      stdout.writeln(section);
    default:
      stderr.writeln('알 수 없는 명령: ${args[0]}');
      exitCode = 2;
  }
}
