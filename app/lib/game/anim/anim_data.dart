// art/pb_assets_v0.15/tools/flame/pb_anim.dart 에서 가져와 고쳤다 (docs/ASSETS.md).
// 렌더 전용 데이터·보간. 판정에는 쓰지 않는다.
import 'dart:convert';
import 'dart:math' as math;

import 'package:flame/components.dart';

/// 키 하나: 시각 [t](초)와 속성 값, 도착 보간 방식 [ease] (io | out | in | lin | step).
class AnimKey {
  AnimKey(this.t, this.ease, this.v);

  factory AnimKey.fromJson(Map<String, dynamic> j) {
    final v = <String, double>{};
    for (final p in const ['rot', 'dx', 'dy', 'sx', 'sy', 'op']) {
      final value = j[p];
      if (value is num) v[p] = value.toDouble();
    }
    return AnimKey(
      (j['t'] as num).toDouble(),
      (j['ease'] as String?) ?? 'io',
      v,
    );
  }

  final double t;
  final String ease;
  final Map<String, double> v;
}

/// 애니메이션 이벤트: spawn | shake | slash | repair | flash.
class AnimEvent {
  AnimEvent(this.t, this.type, this.raw);

  final double t;
  final String type;
  final Map<String, dynamic> raw;

  String? get part => raw['part'] as String?;

  Vector2? get point {
    final p = raw['point'];
    if (p is! List) return null;
    return Vector2((p[0] as num).toDouble(), (p[1] as num).toDouble());
  }
}

class AnimClip {
  AnimClip(this.duration, this.tracks, this.events);

  factory AnimClip.fromJson(Map<String, dynamic> j) => AnimClip(
    (j['duration'] as num).toDouble(),
    (j['tracks'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, [
        for (final e in v as List<dynamic>)
          AnimKey.fromJson(e as Map<String, dynamic>),
      ]),
    ),
    [
      for (final e in (j['events'] as List<dynamic>?) ?? const <dynamic>[])
        AnimEvent(
          ((e as Map<String, dynamic>)['t'] as num).toDouble(),
          e['type'] as String,
          e,
        ),
    ],
  );

  final double duration;
  final Map<String, List<AnimKey>> tracks;
  final List<AnimEvent> events;
}

/// `assets/data/anims.json`: 캐릭터별 공격 동작과 공용 피격.
class PbAnims {
  PbAnims(this.attacks, this.hit);

  factory PbAnims.fromJsonString(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    return PbAnims(
      (j['attacks'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, AnimClip.fromJson(v as Map<String, dynamic>)),
      ),
      AnimClip.fromJson(j['hit'] as Map<String, dynamic>),
    );
  }

  static const String path = 'assets/data/anims.json';

  final Map<String, AnimClip> attacks;
  final AnimClip hit;
}

double _ease(String e, double u) => switch (e) {
  'lin' => u,
  'out' => 1 - (1 - u) * (1 - u),
  'in' => u * u,
  _ => u < .5 ? 2 * u * u : 1 - math.pow(-2 * u + 2, 2) / 2,
};

/// 한 속성을 가진 키들 사이를 보간한다. 보간 방식은 도착 키의 ease.
double evalProp(List<AnimKey> keys, String p, double t, double def) {
  AnimKey? prev;
  AnimKey? next;
  for (final k in keys) {
    if (!k.v.containsKey(p)) continue;
    if (k.t <= t) {
      prev = k;
    } else {
      next = k;
      break;
    }
  }
  if (prev == null) return next?.v[p] ?? def;
  if (next == null || next.ease == 'step') return prev.v[p]!;
  final u = (t - prev.t) / (next.t - prev.t);
  return prev.v[p]! + (next.v[p]! - prev.v[p]!) * _ease(next.ease, u);
}

/// 부위 하나의 자세.
class PartPose {
  PartPose();

  factory PartPose.sample(List<AnimKey>? keys, double t) {
    final s = PartPose();
    if (keys == null) return s;
    return s
      ..rot = evalProp(keys, 'rot', t, 0)
      ..dx = evalProp(keys, 'dx', t, 0)
      ..dy = evalProp(keys, 'dy', t, 0)
      ..sx = evalProp(keys, 'sx', t, 1)
      ..sy = evalProp(keys, 'sy', t, 1)
      ..op = evalProp(keys, 'op', t, 1);
  }

  double rot = 0;
  double dx = 0;
  double dy = 0;
  double sx = 1;
  double sy = 1;
  double op = 1;
}
