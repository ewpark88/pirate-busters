import 'package:flutter/widgets.dart';
import 'package:pb_ai/pb_ai.dart';

/// 메타 아이콘 (에셋 v0.23 `ui/meta/`, 설계서 §13.2~§13.5, ADR-063). 글자가
/// 아니라 그림이라 두 언어에서 같다. 이름은 화면이 ARB 글자로 붙인다.
abstract final class MetaIcons {
  static const String _dir = 'assets/images/ui/meta';

  // 전투 HUD (§13.4).
  static const String hull = '$_dir/hud/hull.png';
  static const String flood = '$_dir/hud/flood.png';
  static const String crew = '$_dir/hud/crew.png';
  static const String turns = '$_dir/hud/turns.png';
  static const String timer = '$_dir/hud/timer.png';
  static const String fullView = '$_dir/hud/fullview.png';
  static const String endTurn = '$_dir/hud/end_turn.png';
  static const String pause = '$_dir/hud/pause.png';
  static const String surrender = '$_dir/hud/surrender.png';
  static const String outOfRange = '$_dir/hud/out_of_range.png';
  static const String cancel = '$_dir/hud/cancel.png';
  static const String moveForward = '$_dir/hud/move_fwd.png';
  static const String moveBack = '$_dir/hud/move_back.png';

  // 결과 (§13.5)·캠페인 지도 별.
  static const String ad2x = '$_dir/meta/ad2x.png';
  static const String replay = '$_dir/meta/replay.png';
  static const String starOn = '$_dir/meta/star_on.png';
  static const String starOff = '$_dir/meta/star_off.png';

  // 설정 (§13.8).
  static const String language = '$_dir/meta/language.png';
  static const String sound = '$_dir/meta/sound.png';
  static const String vibrate = '$_dir/meta/vibrate.png';
  static const String lowSpec = '$_dir/meta/lowspec.png';

  // 항구 재화 (§13.2). 진주는 R4.
  static const String gold = '$_dir/currency/gold.png';

  /// 잠김·빨간 점 (§13.2, §13.6).
  static const String lock = '$_dir/meta/lock.png';
  static const String redDot = '$_dir/meta/reddot.png';

  /// 조선소 추천 설계도 불러오기 (§13.6).
  static const String blueprint = '$_dir/currency/blueprint.png';

  /// AI 성격 아이콘 (§13.3, §5.3).
  static String personality(Personality p) => '$_dir/ai/ai_${p.name}.png';

  /// 세력 깃발 (§15.3). [faction] 은 에셋 키(해역 1 `redclaw`).
  static String faction(String faction) => '$_dir/faction/faction_$faction.png';

  /// 해역 [sea] 세력의 깃발 (§15.3). 해역 1 붉은집게 초계대 ~ 6 골드핀 함대.
  static String factionOfSea(int sea) => faction(
    const [
      'redclaw',
      'fogbone',
      'thunderwing',
      'frosttusk',
      'abyss',
      'goldfin',
    ][(sea - 1).clamp(0, 5)],
  );

  /// [path] 그림을 [size] 크기 정사각형으로 놓는다.
  static Widget image(String path, {double size = 20}) =>
      Image.asset(path, width: size, height: size);
}
