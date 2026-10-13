import 'dart:convert';
import 'dart:io';

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

  group('덮어쓰기 방식 --merge (에셋 v0.22, ADR-058)', () {
    test('인자를 패키지 경로와 방식으로 읽는다', () {
      expect(parseArgs(['--check']), (package: null, merge: false));
      expect(parseArgs(['art/pkg']), (package: 'art/pkg', merge: false));
      expect(parseArgs(['--merge', 'art/pkg']), (
        package: 'art/pkg',
        merge: true,
      ));
      expect(parseArgs([]), isNull);
      expect(parseArgs(['--merge']), isNull);
      expect(parseArgs(['--merge', '--check']), isNull);
      expect(parseArgs(['a', 'b']), isNull);
    });

    test('표정 부위·새 타일·랍 초상은 이름에서 @2x 만 떼고 옮긴다', () {
      expect(
        imageTarget('characters/octo/expr_blue@2x/aim_head.png'),
        'characters/octo/expr_blue/aim_head.png',
      );
      expect(
        imageTarget('ship/tiles_v2/oak_3@2x.png'),
        'ship/tiles_v2/oak_3.png',
      );
      expect(
        imageTarget('ui/portraits/lobster_red@2x.png'),
        'ui/portraits/lobster_red.png',
      );
      expect(
        imageTarget('ship/rooms/room1_lantern_0_left@2x.png'),
        'ship/rooms/room1_lantern_0_left.png',
      );
      // 카드 그림은 tool/assets/export_cards.py 가 구운 것이다 (ADR-062).
      expect(
        imageTarget('characters/octo/octo_red_card@2x.png'),
        'characters/octo/octo_red_card.png',
      );
      expect(
        imageTarget('characters/octo/parts_battle_red@2x/battle.json'),
        'characters/octo/parts_battle_red/battle.json',
      );
      // 계열(투척) 아이콘 lob 은 그대로다.
      expect(imageTarget('ui/icons/lob@2x.png'), 'ui/icons/lob.png');
    });

    test('옛 키 파일은 앱 에셋에 남아 있지 않고 새 키 파일이 있다', () {
      const images = 'app/assets/images';
      for (final old in obsoleteImages) {
        expect(
          FileSystemEntity.typeSync('$images/$old'),
          FileSystemEntityType.notFound,
          reason: old,
        );
      }
      for (final team in ['blue', 'red']) {
        final file = '$images/ui/portraits/lobster_$team.png';
        expect(File(file).existsSync(), isTrue, reason: file);
      }
      expect(Directory('$images/characters/lobster').existsSync(), isTrue);
    });

    test('글자가 든 데이터 파일은 앱에 넣지 않는다 (절대 규칙 10)', () {
      expect(dataFiles.keys, isNot(contains('ui/cards/cards.json')));
      expect(dataFiles.keys, isNot(contains('ui/icons/sets.json')));
    });

    test('몸 부위가 없는 캐릭터를 찾는다', () {
      expect(
        charactersWithoutBody([
          'assets/images/characters/octo/parts_blue/parts.json',
          'assets/images/characters/octo/expr_blue/expr.json',
          'assets/images/characters/uni/expr_blue/expr.json',
          'assets/images/ui/portraits/uni_blue.png',
        ]),
        ['uni'],
      );
    });
  });

  group('에셋 v0.23 적용 범위 (A12, ADR-063)', () {
    test('이 단계에서 쓰는 배경·모듈·메타 아이콘·말풍선은 가져온다', () {
      expect(
        imageTarget('bg/tropic/tropic_far@2x.png'),
        'bg/tropic/tropic_far.png',
      );
      expect(
        imageTarget('bg/props/limit_back@2x.png'),
        'bg/props/limit_back.png',
      );
      expect(
        imageTarget('ship/modules/gunport@2x.png'),
        'ship/modules/gunport.png',
      );
      expect(imageTarget('ui/meta/hud/hull@2x.png'), 'ui/meta/hud/hull.png');
      expect(
        imageTarget('ui/story/bubble_left@2x.png'),
        'ui/story/bubble_left.png',
      );
      expect(
        imageTarget('ship/tiles_v2/oak_0@2x.png'),
        'ship/tiles_v2/oak_0.png',
      );
    });

    test('뒷 단계 기능의 그림은 가져오지 않는다', () {
      for (final rel in [
        'bg/fog/fog_sky@2x.png',
        'boss/ram@2x.png',
        'ui/meta/chest/chest_wood@2x.png',
        'ui/meta/tier/tier_king@2x.png',
        'ship/tiles_v2/ice_0@2x.png',
        'ship/tiles_v2/shield@2x.png',
        'fx/damage_v3/crack_iron_0@2x.png',
      ]) {
        expect(imageTarget(rel), isNull, reason: rel);
      }
      // 불·그을린 블록은 R1c 에서 쓴다.
      expect(
        imageTarget('ship/tiles_v2/burn_1@2x.png'),
        'ship/tiles_v2/burn_1.png',
      );
    });

    test('배경 데이터에서 이름 글자 필드를 지운다 (절대 규칙 10)', () {
      expect(
        stripText({
          'note': '설명',
          'horizon': 420,
          'regions': {
            'tropic': {
              'ko': '열대 만',
              'en': 'Tropical Bay',
              'faction': '붉은집게 초계대',
              'sun': [1080, 120, 34],
            },
          },
          'limits': {'back': 'props/limit_back.svg (설명)'},
        }),
        {
          'horizon': 420,
          'regions': {
            'tropic': {
              'sun': [1080, 120, 34],
            },
          },
        },
      );
    });

    test('앱의 배경·모드 데이터에는 글자 필드가 없다', () {
      bool hasText(Object? o) => switch (o) {
        final Map<String, Object?> m => m.entries.any(
          (e) => textFields.contains(e.key) || hasText(e.value),
        ),
        final List<Object?> l => l.any(hasText),
        _ => false,
      };
      for (final f in textStrippedData) {
        final json = jsonDecode(File('app/assets/data/$f').readAsStringSync());
        expect(hasText(json), isFalse, reason: f);
      }
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

  group('제외 목록 (docs/ASSETS.md 「안 쓰는 에셋 정리」)', () {
    test('빈 줄과 주석은 버리고 경로만 읽는다', () {
      expect(
        parseExcludes('# 머리\n\nship/tiles/\nfx/fire.png  # 불 규칙 없음\n'),
        ['ship/tiles/', 'fx/fire.png'],
      );
    });

    test('/ 로 끝나면 폴더 전체, 아니면 그 파일만 뺀다', () {
      const ex = ['ship/tiles/', 'fx/fire.png'];
      expect(isExcluded('ship/tiles/block_oak_0.png', ex), isTrue);
      expect(isExcluded('ship/tiles_v2/oak_0.png', ex), isFalse);
      expect(isExcluded('fx/fire.png', ex), isTrue);
      expect(isExcluded('fx/fire_big.png', ex), isFalse);
    });

    test('가져오기는 제외 목록의 그림을 넣지 않는다 (--merge 포함)', () {
      const ex = ['ship/tiles/', 'ui/icons/pearl.png'];
      expect(imageTarget('tiles/block_oak_0@2x.png', excludes: ex), isNull);
      expect(imageTarget('ui/icons/pearl@2x.png', excludes: ex), isNull);
      expect(
        imageTarget('ui/icons/gold@2x.png', excludes: ex),
        'ui/icons/gold.png',
      );
    });

    test('검사는 제외 목록의 그림이 다시 들어와 있으면 알린다', () {
      expect(
        returnedExcludes(
          ['assets/images/fx/fire.png', 'assets/images/fx/bomb.png'],
          const ['fx/fire.png'],
        ),
        ['제외 목록의 그림이 다시 들어왔다: assets/images/fx/fire.png'],
      );
    });

    test('저장소의 제외 목록은 비어 있지 않고, 앱에 그 그림이 하나도 없다', () {
      final ex = parseExcludes(File(excludePath).readAsStringSync());
      expect(ex, contains('ship/tiles/'));
      expect(ex.length, greaterThanOrEqualTo(79));
      final images = Directory('app/assets/images')
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/').substring(4));
      expect(returnedExcludes(images, ex), isEmpty);
    });
  });
}
