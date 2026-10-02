// art/pb_v0.22_main/tools/flame/pb_rarity.dart 의 수치 구조를 가져와 고쳤다
// (docs/ASSETS.md): 값은 코드에 박지 않고 anims.json `rarityFx.tiers` 에서 읽는다.
import 'dart:ui';

import 'package:pb_sim/pb_sim.dart';

/// 등급 하나의 전투 연출 값 (설계서 §10.5). 색과 입자만 정한다. 판정과 무관하다.
class RarityTier {
  const RarityTier({
    this.color,
    this.hi,
    this.aura = 0,
    this.motes = 0,
    this.glint = 0,
    this.aim = const Color(0xFFFFF2DC),
    this.trail = 'smoke',
    this.ring = 0,
    this.shards = 0,
    this.shake = 1,
    this.glow = 0,
  });

  factory RarityTier.fromJson(Map<String, dynamic> j) => RarityTier(
    color: _color(j['color']),
    hi: _color(j['hi']),
    aura: (j['aura'] as num?)?.toInt() ?? 0,
    motes: (j['motes'] as num?)?.toInt() ?? 0,
    glint: (j['glint'] as num?)?.toInt() ?? 0,
    aim: _color(j['aim']) ?? const Color(0xFFFFF2DC),
    trail: (j['trail'] as String?) ?? 'smoke',
    ring: (j['ring'] as num?)?.toInt() ?? 0,
    shards: (j['shards'] as num?)?.toInt() ?? 0,
    shake: (j['shake'] as num?)?.toDouble() ?? 1,
    glow: (j['glow'] as num?)?.toDouble() ?? 0,
  );

  /// 등급색과 밝은 쪽. 일반은 null(색을 더하지 않는다).
  final Color? color;
  final Color? hi;

  /// 발밑 고리: 0 없음, 1 고리, 2 고리 + 도는 점선 + 빛기둥, 3 무지개 고리 + 빛 구슬.
  final int aura;

  /// 발밑에서 떠오르는 반짝임 수.
  final int motes;

  /// 발사 순간 손끝 반짝 크기 단계.
  final int glint;

  /// 조준 점선 색.
  final Color aim;

  /// 발사체 꼬리: smoke | dots | ribbon | ribbon+stars | prism.
  final String trail;

  /// 명중 때 등급색 고리 수와 별 조각 수.
  final int ring;
  final int shards;

  /// 화면 흔들림 배율.
  final double shake;

  /// 해적 외곽 빛 반경(에셋 기준 1x px). 0 이면 없다.
  final double glow;

  static Color? _color(Object? hex) {
    if (hex is! String || hex.length != 7 || !hex.startsWith('#')) return null;
    final rgb = int.tryParse(hex.substring(1), radix: 16);
    return rgb == null ? null : Color(0xFF000000 | rgb);
  }
}

/// `anims.json` 의 `rarityFx`: 등급별 전투 연출 값 (설계서 §10.5).
class RarityFx {
  const RarityFx(this._tiers);

  /// [json] 은 `rarityFx` 객체. 없으면 모든 등급이 일반 연출이다.
  factory RarityFx.fromJson(Map<String, dynamic>? json) {
    final tiers = json?['tiers'];
    if (tiers is! Map<String, dynamic>) return const RarityFx({});
    return RarityFx({
      for (final MapEntry(:key, :value) in tiers.entries)
        if (value is Map<String, dynamic>) key: RarityTier.fromJson(value),
    });
  }

  static const RarityTier common = RarityTier();

  /// 에셋 키. 신화는 에셋에서 `mythic` 이다(pb_sim 은 `myth`).
  static const List<String> keys = [
    'common',
    'rare',
    'hero',
    'legend',
    'mythic',
  ];

  final Map<String, RarityTier> _tiers;

  /// [rarity] 의 연출 값. 그 등급이 데이터에 없으면 바로 아래 등급 것을 쓴다
  /// (신화 값은 에셋 v0.22 부터 있다).
  RarityTier of(Rarity rarity) {
    for (var i = rarity.step; i >= 0; i--) {
      final tier = _tiers[keys[i]];
      if (tier != null) return tier;
    }
    return common;
  }
}
