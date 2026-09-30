import 'dart:convert';
import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// 해적별 투사체 그림 (에셋 v0.21 `weapons.json`, 렌더 전용).
///
/// `spin` 은 날아가는 동안 초당 [WeaponStyle.spinDeg] 도 돌고, `face` 는 진행
/// 방향을 본다. 강습(`melee`)처럼 그림이 없는 해적은 공용 포탄으로 그린다.
class WeaponStyle {
  const WeaponStyle({required this.file, required this.spin, this.spinDeg = 0});

  /// `assets/images/` 아래 파일.
  final String file;

  /// true 면 회전, false 면 진행 방향.
  final bool spin;
  final double spinDeg;

  /// [seconds] 초 날았고 속도가 ([vx], [vy]) (화면 좌표)일 때 그림 각도(라디안).
  double angle(double seconds, double vx, double vy) =>
      spin ? seconds * spinDeg * math.pi / 180 : math.atan2(vy, vx);
}

class WeaponStyles {
  WeaponStyles._(this._styles, this._images);

  static const String path = 'assets/data/weapons.json';

  /// 분열 조각·다중투하 소형 폭탄 그림.
  static const WeaponStyle splitShard = WeaponStyle(
    file: 'weapons/uni_split.png',
    spin: true,
    spinDeg: 720,
  );
  static const WeaponStyle bomblet = WeaponStyle(
    file: 'weapons/bomblet.png',
    spin: true,
    spinDeg: 360,
  );

  /// weapons.json 을 읽고 그림을 미리 올린다.
  static Future<WeaponStyles> load(Images images, AssetBundle bundle) async {
    final json =
        jsonDecode(await bundle.loadString(path)) as Map<String, dynamic>;
    final styles = <String, WeaponStyle>{};
    final weapons = json['weapons'] as Map<String, dynamic>;
    for (final MapEntry(key: id, value: raw) in weapons.entries) {
      final w = raw as Map<String, dynamic>;
      final sprite = w['sprite'] as String?;
      if (sprite == null) continue;
      styles[id] = WeaponStyle(
        file: sprite.replaceFirst('.svg', '.png'),
        spin: w['mode'] != 'face',
        spinDeg: (w['spin'] as num?)?.toDouble() ?? 0,
      );
    }
    await images.loadAll([
      for (final s in styles.values) s.file,
      splitShard.file,
      bomblet.file,
    ]);
    return WeaponStyles._(styles, images);
  }

  final Map<String, WeaponStyle> _styles;
  final Images _images;

  /// 종족 [species] 의 투사체. 없으면 null(공용 포탄).
  WeaponStyle? of(String species) => _styles[species];

  Sprite sprite(WeaponStyle style) => Sprite(_images.fromCache(style.file));
}
