import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pirate_busters/game/view/sea_shape.dart';
import 'package:pirate_busters/game/view/sea_theme.dart';
import 'package:pirate_busters/game/view/sea_view.dart';
import 'package:pirate_busters/game/view/sea_zone_tint.dart';
import 'package:pirate_busters/game/view/wind_feel.dart';
import 'package:pirate_busters/game/view/wind_spray.dart';

/// 전장 바다 겹 (설계서 §2.4·§2.6·§10.2): 바람 느낌, 수면 모양, 뒤 바다, 파도 구간
/// 물빛, 앞 바다, 물보라. 배(0)보다 뒤(−10·−9)와 앞(10·11)에 나눠 둔다.
List<Component> seaLayers({
  required SeaShape sea,
  required WindFeel wind,
  required SeaTheme theme,
  FragmentShader? shader,
  ValueListenable<bool>? lowEnd,
}) => [
  wind,
  sea,
  SeaView(front: false, theme: theme, swell: sea.call, priority: -10),
  if (sea.zones case final zones?)
    SeaZoneTint(zones: zones, theme: theme, surface: sea.call, priority: -9),
  SeaView(
    front: true,
    theme: theme,
    swell: sea.call,
    shape: sea,
    shader: shader,
    lowEnd: lowEnd,
    wind: wind,
    priority: 10,
  ),
  WindSpray(shape: sea, wind: wind, lowEnd: lowEnd, priority: 11),
];
