import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/app/app_theme.dart';

/// 골든 테스트용: 앱 글꼴 세 가지(설계서 §14.4)를 파일에서 읽어 등록한다.
/// 테스트 작업 폴더는 `app/` 이다.
Future<void> loadAppFonts() async {
  const files = {
    AppFonts.display: ['BlackHanSans-Regular.ttf'],
    AppFonts.body: ['IBMPlexSansKR-Regular.ttf', 'IBMPlexSansKR-Bold.ttf'],
    AppFonts.round: ['Jua-Regular.ttf'],
  };
  for (final MapEntry(key: family, value: names) in files.entries) {
    final loader = FontLoader(family);
    for (final name in names) {
      final bytes = File('assets/fonts/$name').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}

/// 골든 테스트용: 화면에 있는 그림을 모두 읽어 둔 뒤 한 프레임 더 그린다. 그림은
/// 비동기로 풀리므로, 기다리지 않으면 처음 찍는 화면에 그림이 빠진다. 데이터 JSON 을
/// 읽은 뒤에야 그림이 생기는 화면(컷신 배경·해적 부위)이 있어 새 그림이 없을 때까지
/// 되풀이한다.
Future<void> loadImages(WidgetTester tester) async {
  final done = <ImageProvider>{};
  for (var round = 0; round < 6; round++) {
    final fresh = [
      for (final e in find.byType(Image).evaluate())
        if (!done.contains((e.widget as Image).image)) e,
    ];
    await tester.runAsync(() async {
      // 데이터 JSON 읽기(실제 비동기)가 끝날 틈을 준다.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      for (final e in fresh) {
        final image = (e.widget as Image).image;
        done.add(image);
        await precacheImage(image, e);
      }
    });
    await tester.pump();
  }
}
