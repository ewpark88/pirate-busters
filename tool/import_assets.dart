// 아트 에셋 패키지를 저장소에 넣는다 (docs/ASSETS.md, ADR-026).
// 사용법:
//   dart run tool/import_assets.dart <패키지 경로>   복사 + pubspec 검사
//   dart run tool/import_assets.dart --check          pubspec 검사만
// 1) 패키지 전체를 art/<이름>/ 에 그대로 복사한다 (git 제외).
// 2) png/ 의 @2x 만 골라 이름에서 "@2x" 를 떼고 app/assets/images/ 로 복사한다.
// 3) anims.json·tokens.json 을 app/assets/data/ 로 복사한다.
// 4) app/pubspec.yaml 의 에셋 폴더 목록이 실제 폴더와 다르면 exit 1.
import 'dart:io';

const assetsRoot = 'app/assets';
const pubspecPath = 'app/pubspec.yaml';

/// png/ 아래 상대 경로를 app/assets/images/ 아래 상대 경로로 바꾼다.
/// @2x 가 아니거나 앱에 넣지 않는 파일이면 null.
String? imageTarget(String rel) {
  final path = rel.replaceAll(r'\', '/');
  if (!path.contains('@2x')) return null;
  final segs = path.split('/');
  // 캐릭터 초상은 ui/portraits 를 쓴다.
  if (segs.first == 'characters' && segs.last.contains('_portrait@2x')) {
    return null;
  }
  if (const {'tiles', 'rooms', 'rig'}.contains(segs.first)) {
    segs.insert(0, 'ship');
  }
  return segs.map((s) => s.replaceAll('@2x', '')).join('/');
}

/// 데이터 파일(패키지 기준 상대 경로) → app/assets/data/ 아래 이름.
const dataFiles = {
  'anims/anims.json': 'anims.json',
  'style/tokens.json': 'tokens.json',
};

/// 패키지 폴더 이름 → art/ 아래 이름. `pirate_busters_assets_v0.15` → `pb_assets_v0.15`.
String artDirName(String packageDirName) =>
    packageDirName.replaceFirst('pirate_busters_assets_', 'pb_assets_');

/// pubspec.yaml 본문에서 `assets/` 로 시작하는 에셋 항목을 뽑는다.
Set<String> pubspecAssetDirs(String pubspec) => RegExp(
  r'^\s*-\s+(assets/\S+)',
  multiLine: true,
).allMatches(pubspec).map((m) => m.group(1)!).toSet();

/// 파일 목록(app/ 기준 상대 경로)이 들어 있는 폴더를 pubspec 형식(`dir/`)으로 모은다.
Set<String> assetDirsOf(Iterable<String> files) => {
  for (final f in files) '${f.substring(0, f.lastIndexOf('/'))}/',
};

/// pubspec 에 빠진 폴더와 실제로 없는 폴더를 위반 목록으로 돌려준다.
List<String> compareAssetDirs(Set<String> declared, Set<String> actual) => [
  for (final d in (actual.difference(declared).toList()..sort()))
    'pubspec 에 없다: $d',
  for (final d in (declared.difference(actual).toList()..sort())) '폴더가 없다: $d',
];

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('사용법: dart run tool/import_assets.dart <패키지 경로>|--check');
    exitCode = 2;
    return;
  }
  if (args.first != '--check') {
    _import(Directory(args.first));
  }
  _check();
}

void _import(Directory src) {
  if (!src.existsSync()) {
    stderr.writeln('패키지가 없다: ${src.path}');
    exit(1);
  }
  final name = artDirName(src.uri.pathSegments.where((s) => s.isNotEmpty).last);
  _copyTree(src, Directory('art/$name'));

  for (final sub in ['images', 'data']) {
    final d = Directory('$assetsRoot/$sub');
    if (d.existsSync()) d.deleteSync(recursive: true);
  }
  final png = Directory('${src.path}/png');
  var count = 0;
  for (final f in png.listSync(recursive: true).whereType<File>()) {
    final target = imageTarget(f.path.substring(png.path.length + 1));
    if (target == null) continue;
    _copyFile(f, '$assetsRoot/images/$target');
    count++;
  }
  dataFiles.forEach((from, to) {
    _copyFile(File('${src.path}/$from'), '$assetsRoot/data/$to');
  });
  stdout.writeln('art/$name 복사, 이미지 $count개·데이터 ${dataFiles.length}개 배치');
}

void _check() {
  final root = Directory(assetsRoot);
  final files = root.existsSync()
      ? root
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => f.path.replaceAll(r'\', '/').substring(4))
      : const <String>[];
  final errors = compareAssetDirs(
    pubspecAssetDirs(File(pubspecPath).readAsStringSync()),
    assetDirsOf(files),
  );
  if (errors.isEmpty) {
    stdout.writeln('assets OK');
    return;
  }
  stderr.writeln('$pubspecPath 에셋 목록 불일치 ${errors.length}건:');
  for (final e in errors) {
    stderr.writeln('  - $e');
  }
  exitCode = 1;
}

void _copyTree(Directory from, Directory to) {
  for (final e in from.listSync(recursive: true).whereType<File>()) {
    _copyFile(e, '${to.path}/${e.path.substring(from.path.length + 1)}');
  }
}

void _copyFile(File from, String to) {
  File(to).parent.createSync(recursive: true);
  from.copySync(to);
}
