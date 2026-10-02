// 아트 에셋 패키지를 저장소에 넣는다 (docs/ASSETS.md, ADR-026).
// 사용법:
//   dart run tool/import_assets.dart <패키지 경로>           복사 + pubspec 검사
//   dart run tool/import_assets.dart --merge <패키지 경로>   덮어쓰기만 + pubspec 검사
//   dart run tool/import_assets.dart --check                  pubspec 검사만
// 1) 패키지 전체를 art/<이름>/ 에 그대로 복사한다 (git 제외).
// 2) png/ 의 @2x 만 골라 이름에서 "@2x" 를 떼고 app/assets/images/ 로 복사한다.
// 3) anims.json·tokens.json 을 app/assets/data/ 로 복사한다.
// 4) app/pubspec.yaml 의 에셋 폴더 목록이 실제 폴더와 다르면 exit 1.
// --merge 는 app/assets 를 지우지 않고 패키지에 있는 파일만 덮어쓴다. 캐릭터 몸
// PNG 가 일부만 든 패키지(v0.22: 랍스터와 표정 부위뿐)를 넣을 때 쓴다.
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

/// --merge 뒤에 지우는 옛 키 경로(app/assets/images 기준). 새 키로 대체됐다.
const obsoleteImages = [
  'characters/lob',
  'ui/portraits/lob_blue.png',
  'ui/portraits/lob_red.png',
  // v0.22 에서 탄종 키로 이름이 바뀐 아이콘.
  'ammo/icons/explode.png',
  'ammo/icons/rapid.png',
  'ammo/icons/snipe.png',
  'ammo/icons/plant.png',
  'ammo/icons/multidrop.png',
  // v0.24 에서 1칸 선실 타일(`ship/rooms/room1_*`)로 대체된 3×2칸 선실 타일.
  'ship/rooms/room_barrel.png',
  'ship/rooms/room_lantern.png',
  'ship/rooms/room_plain.png',
];

/// 명령줄 인자를 (패키지 경로, 덮어쓰기만) 로 읽는다. 검사만이면 경로가 null.
/// 형식이 틀리면 null.
({String? package, bool merge})? parseArgs(List<String> args) => switch (args) {
  ['--check'] => (package: null, merge: false),
  ['--merge', final path] when !path.startsWith('--') => (
    package: path,
    merge: true,
  ),
  [final path] when !path.startsWith('--') => (package: path, merge: false),
  _ => null,
};

/// 데이터 파일(패키지 기준 상대 경로) → app/assets/data/ 아래 이름.
const dataFiles = {
  'anims/anims.json': 'anims.json',
  'style/tokens.json': 'tokens.json',
  'weapons/weapons.json': 'weapons.json',
  // `ui/cards/cards.json`·`ui/icons/sets.json` 은 설명·세트 이름 글자가 들어 있어
  // 앱에 넣지 않는다(절대 규칙 10). 필요한 값은 코드와 ARB 로 옮긴다.
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

/// 몸 부위(`parts_blue/parts.json`)가 없는 캐릭터 id 를 찾는다. 표정 부위만 든
/// 패키지를 지우고 채우는 방식으로 넣으면 몸이 사라지므로 검사한다 (ADR-058).
List<String> charactersWithoutBody(Iterable<String> files) {
  final all = <String>{};
  final withBody = <String>{};
  final pattern = RegExp('^assets/images/characters/([^/]+)/(.*)');
  for (final f in files) {
    final m = pattern.firstMatch(f);
    if (m == null) continue;
    all.add(m.group(1)!);
    if (m.group(2) == 'parts_blue/parts.json') withBody.add(m.group(1)!);
  }
  return all.difference(withBody).toList()..sort();
}

void main(List<String> args) {
  final parsed = parseArgs(args);
  if (parsed == null) {
    stderr.writeln(
      '사용법: dart run tool/import_assets.dart [--merge] <패키지 경로>|--check',
    );
    exitCode = 2;
    return;
  }
  final package = parsed.package;
  if (package != null) _import(Directory(package), merge: parsed.merge);
  _check();
}

void _import(Directory src, {required bool merge}) {
  if (!src.existsSync()) {
    stderr.writeln('패키지가 없다: ${src.path}');
    exit(1);
  }
  final name = artDirName(src.uri.pathSegments.where((s) => s.isNotEmpty).last);
  final art = Directory('art/$name');
  // 이미 art/ 아래에 풀어 둔 패키지면 다시 복사하지 않는다.
  if (src.absolute.path != art.absolute.path) _copyTree(src, art);

  if (!merge) {
    for (final sub in ['images', 'data']) {
      final d = Directory('$assetsRoot/$sub');
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
  }
  final png = Directory('${src.path}/png');
  var count = 0;
  for (final f in png.listSync(recursive: true).whereType<File>()) {
    final target = imageTarget(f.path.substring(png.path.length + 1));
    if (target == null) continue;
    _copyFile(f, '$assetsRoot/images/$target');
    count++;
  }
  var data = 0;
  dataFiles.forEach((from, to) {
    final file = File('${src.path}/$from');
    // 옛 패키지에는 없는 데이터 파일이 있다.
    if (!file.existsSync()) return;
    _copyFile(file, '$assetsRoot/data/$to');
    data++;
  });
  if (merge) {
    for (final old in obsoleteImages) {
      final path = '$assetsRoot/images/$old';
      if (FileSystemEntity.isDirectorySync(path)) {
        Directory(path).deleteSync(recursive: true);
      } else if (File(path).existsSync()) {
        File(path).deleteSync();
      }
    }
  }
  stdout.writeln('art/$name, 이미지 $count개·데이터 $data개 배치');
}

void _check() {
  final root = Directory(assetsRoot);
  final files = root.existsSync()
      ? root
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => f.path.replaceAll(r'\', '/').substring(4))
            // 글꼴은 pubspec 의 `fonts:` 로 따로 선언한다.
            .where((f) => !f.startsWith('assets/fonts/'))
      : const <String>[];
  final errors = [
    ...compareAssetDirs(
      pubspecAssetDirs(File(pubspecPath).readAsStringSync()),
      assetDirsOf(files),
    ),
    for (final id in charactersWithoutBody(files)) '몸 부위가 없다: characters/$id',
  ];
  if (errors.isEmpty) {
    stdout.writeln('assets OK');
    return;
  }
  stderr.writeln('$pubspecPath·에셋 불일치 ${errors.length}건:');
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
