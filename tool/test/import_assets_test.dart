import 'package:test/test.dart';

import '../import_assets.dart';

void main() {
  group('에셋 경로 바꾸기', () {
    test('@2x 가 아닌 파일은 넣지 않는다', () {
      expect(imageTarget('fx/bomb@1x.png'), isNull);
      expect(imageTarget('fx/bomb@3x.png'), isNull);
    });

    test('파일과 폴더 이름에서 @2x 를 뗀다', () {
      expect(imageTarget('fx/impact/burst@2x.png'), 'fx/impact/burst.png');
      expect(
        imageTarget('characters/octo/parts_battle_blue@2x/arm.png'),
        'characters/octo/parts_battle_blue/arm.png',
      );
      expect(
        imageTarget('characters/octo/octo_red_battle@2x.png'),
        'characters/octo/octo_red_battle.png',
      );
    });

    test('배 타일·선실·장비는 ship 아래로 옮긴다', () {
      expect(
        imageTarget('tiles/block_oak_0@2x.png'),
        'ship/tiles/block_oak_0.png',
      );
      expect(
        imageTarget(r'rooms\room_plain@2x.png'),
        'ship/rooms/room_plain.png',
      );
      expect(imageTarget('rig/mast@2x.png'), 'ship/rig/mast.png');
    });

    test('캐릭터 폴더의 초상은 넣지 않는다', () {
      expect(imageTarget('characters/octo/octo_blue_portrait@2x.png'), isNull);
      expect(
        imageTarget('ui/portraits/octo_blue@2x.png'),
        'ui/portraits/octo_blue.png',
      );
    });

    test('패키지 이름을 art 폴더 이름으로 줄인다', () {
      expect(artDirName('pirate_busters_assets_v0.15'), 'pb_assets_v0.15');
    });
  });

  group('pubspec 에셋 목록 검사', () {
    test('pubspec 의 에셋 항목만 뽑는다', () {
      const yaml = '''
flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/images/fx/
''';
      expect(pubspecAssetDirs(yaml), {'assets/data/', 'assets/images/fx/'});
    });

    test('파일 목록에서 폴더를 모은다', () {
      expect(
        assetDirsOf([
          'assets/data/a.json',
          'assets/data/b.json',
          'assets/images/fx/x.png',
        ]),
        {'assets/data/', 'assets/images/fx/'},
      );
    });

    test('빠진 폴더와 없는 폴더를 찾는다', () {
      final errors = compareAssetDirs(
        {'assets/data/', 'assets/old/'},
        {'assets/data/', 'assets/images/fx/'},
      );
      expect(errors, [
        'pubspec 에 없다: assets/images/fx/',
        '폴더가 없다: assets/old/',
      ]);
    });
  });
}
