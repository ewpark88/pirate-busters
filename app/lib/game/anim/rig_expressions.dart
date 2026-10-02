import 'dart:convert';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 표정 하나에서 바꿔 끼우는 부위(머리 또는 눈): 그림과 놓을 자리.
/// offset·pivot 규칙은 parts.json 과 같다 (docs/ASSETS.md).
class ExprPart {
  const ExprPart(this.sprite, this.offset, this.pivot);

  final Sprite sprite;
  final Vector2 offset;
  final Vector2 pivot;
}

/// 캐릭터 한 명의 표정 6종 (설계서 §10.1): 기본·조준·공격·피격·승리·패배.
/// 머리와 눈 부위만 바꾼다. 에셋 `characters/<id>/expr_<team>/expr.json`.
class RigExpressions {
  RigExpressions(this._byName);

  static const String normal = 'default';
  static const List<String> names = [
    normal,
    'aim',
    'attack',
    'hit',
    'win',
    'lose',
  ];

  /// 캐릭터 [id], 팀 [team] 의 표정 부위를 읽는다. 표정 에셋이 없는 캐릭터면 null.
  static Future<RigExpressions?> load(
    Images images,
    String id,
    String team,
  ) async {
    final dir = 'characters/$id/expr_$team';
    final String source;
    try {
      source = await rootBundle.loadString('assets/images/$dir/expr.json');
    } on Object {
      return null;
    }
    Vector2 v(dynamic a) {
      final l = a as List<dynamic>;
      return Vector2((l[0] as num).toDouble(), (l[1] as num).toDouble());
    }

    final json = jsonDecode(source) as Map<String, dynamic>;
    final byName = <String, Map<String, ExprPart>>{};
    final all = json['expressions'] as Map<String, dynamic>;
    for (final MapEntry(key: name, value: parts) in all.entries) {
      final map = <String, ExprPart>{};
      for (final p in parts as List<dynamic>) {
        final m = p as Map<String, dynamic>;
        map[m['id'] as String] = ExprPart(
          Sprite(await images.load('$dir/${m['file']}')),
          v(m['offset']),
          v(m['pivot']),
        );
      }
      byName[name] = map;
    }
    return RigExpressions(byName);
  }

  final Map<String, Map<String, ExprPart>> _byName;

  /// 표정 [name] 의 부위(부위 id → 그림). 없는 표정이면 null.
  Map<String, ExprPart>? of(String name) => _byName[name];
}
