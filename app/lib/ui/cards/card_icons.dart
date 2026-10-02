import 'package:flutter/widgets.dart';
import 'package:pb_sim/pb_sim.dart';

/// 카드에 붙이는 아이콘 (에셋 v0.22, 설계서 §13.4·§13.7): 사거리 · 코스트 · 세트.
/// 글자가 아니라 그림이라 두 언어에서 같다.
abstract final class CardIcons {
  static const String _dir = 'assets/images/ui/icons';

  /// 사거리 등급 아이콘 (설계서 §2.8): 짧음 1 ~ 매우 긺 4.
  static String range(RangeGrade range) => '$_dir/range_${range.index + 1}.png';

  /// 출전 코스트 아이콘 (설계서 §4.5). 그림은 3·4·5·6·8 이 있다.
  static String cost(int cost) => '$_dir/cost_$cost.png';

  /// 아트 에셋 키 → 세트 id (설계서 §4.7, 에셋 `sets.json` 과 같아야 한다).
  static const Map<String, String> setOf = {
    'pang': 'claw',
    'crabs': 'claw',
    'king': 'claw',
    'lobster': 'claw',
    'shark': 'ghost',
    'bones': 'ghost',
    'crabby': 'ghost',
    'davy': 'ghost',
    'polly': 'sky',
    'gull': 'sky',
    'pelly': 'sky',
    'alba': 'sky',
    'starry': 'spike',
    'puffer': 'spike',
    'uni': 'spike',
    'lion': 'spike',
    'pumpum': 'whale',
    'nar': 'whale',
    'moby': 'whale',
    'orca': 'whale',
    'octo': 'abyss',
    'jelly': 'abyss',
    'kraki': 'abyss',
    'lamp': 'abyss',
    'sword': 'frost',
    'walrus': 'frost',
    'pingu': 'frost',
    'saw': 'frost',
    'otter': 'wave',
    'sheldon': 'wave',
    'bara': 'wave',
    'dolphy': 'wave',
    'turtle': 'reef',
    'cook': 'reef',
    'corey': 'reef',
    'volke': 'reef',
    'hippo': 'bolt',
    'moray': 'bolt',
    'volt': 'bolt',
    'manta': 'bolt',
  };

  /// [species] 가 속한 세트의 아이콘. 세트가 없으면 null.
  static String? set(String species) {
    final id = setOf[species];
    return id == null ? null : '$_dir/set_$id.png';
  }

  /// 사거리 · 코스트 · 세트 아이콘을 세로로 놓는다. [size] 는 아이콘 한 변.
  static Widget column(PirateSpec spec, String species, {double size = 13}) {
    final setIcon = set(species);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final path in [range(spec.range), cost(spec.cost), ?setIcon])
          Padding(
            padding: EdgeInsets.all(size / 12),
            child: Image.asset(path, width: size, height: size),
          ),
      ],
    );
  }
}
