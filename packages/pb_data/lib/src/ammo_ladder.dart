import 'package:pb_data/src/json_reader.dart';
import 'package:pb_sim/pb_sim.dart';

/// 탄종 등급 사다리 `ammo.json` (설계서 §4.8): 탄종 13개 × 등급 5칸.
///
/// 칸 하나는 정수 하나이거나 두 값 탄종이면 `[첫째, 둘째]` 다(설치탄: 지속 턴과
/// 폭발 때 침수 0.1%p). 등급 수치는 여기서만 정하고 해적 JSON 에는 적지 않는다.
class AmmoLadder {
  AmmoLadder._(this._rungs);

  /// 형식이 틀리거나 탄종·칸이 빠지면 [DataFormatError].
  factory AmmoLadder.fromJson(Object? json) {
    final r = JsonReader(json, path: 'ammo');
    final rungs = <AmmoType, List<(int, int)>>{};
    for (final type in AmmoType.values) {
      final cells = r.list(type.jsonName);
      if (cells.length != Rarity.values.length) {
        throw DataFormatError(
          'ammo.${type.jsonName}',
          '등급 ${Rarity.values.length}칸이어야 한다: ${cells.length}',
        );
      }
      rungs[type] = [
        for (final (i, c) in cells.indexed)
          _cell(c, 'ammo.${type.jsonName}[$i]'),
      ];
    }
    return AmmoLadder._(rungs);
  }

  static (int, int) _cell(Object? c, String path) => switch (c) {
    final int v => (v, 0),
    [final int a, final int b] => (a, b),
    _ => throw DataFormatError(path, '정수 또는 [정수, 정수] 가 아니다 ($c)'),
  };

  // 탄종으로 조회만 한다 (순회 순서에 기대지 않는다).
  final Map<AmmoType, List<(int, int)>> _rungs;

  /// [type] 탄종의 [rarity] 칸 (첫째, 둘째).
  (int, int) valueOf(AmmoType type, Rarity rarity) =>
      _rungs[type]![rarity.step];

  /// 원격 값 `ammo_<탄종>_<등급>`(첫째)·`ammo_<탄종>_<등급>_2`(둘째)로 칸을 바꾼
  /// 사다리 (설계서 §4.8, §7.4). [intOr] 가 null 이면 그대로.
  AmmoLadder withOverrides(int? Function(String key) intOr) {
    final rungs = <AmmoType, List<(int, int)>>{};
    for (final type in AmmoType.values) {
      rungs[type] = [
        for (final rarity in Rarity.values)
          () {
            final (a, b) = _rungs[type]![rarity.step];
            final key = 'ammo_${type.jsonName}_${rarity.name}';
            return (intOr(key) ?? a, intOr('${key}_2') ?? b);
          }(),
      ];
    }
    return AmmoLadder._(rungs);
  }
}
