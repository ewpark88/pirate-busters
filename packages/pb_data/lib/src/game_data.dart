import 'dart:convert';

import 'package:pb_data/src/ammo_ladder.dart';
import 'package:pb_data/src/json_reader.dart';
import 'package:pb_data/src/pirate_def.dart';
import 'package:pb_sim/pb_sim.dart';

/// 게임 데이터 묶음: 탄종 사다리 + 해적 정의 (설계서 §4.3, §4.8). 앱이 에셋에서 읽은
/// 문자열을 넘기면 검증해서 `pb_sim` 해적 카탈로그를 만든다.
class GameData {
  GameData._(this.ladder, this.pirates);

  /// [ammoJson]·[piratesJson] 은 `app/assets/game/` 파일 본문. 형식 오류·중복 id 는
  /// [DataFormatError].
  factory GameData.parse({
    required String ammoJson,
    required String piratesJson,
  }) {
    final ladder = AmmoLadder.fromJson(jsonDecode(ammoJson));
    final root = JsonReader(jsonDecode(piratesJson), path: 'pirates.json');
    final defs = <PirateDef>[];
    for (final (i, raw) in root.list('pirates').indexed) {
      final def = PirateDef.fromJson(raw, path: 'pirates[$i]');
      if (defs.any((d) => d.id == def.id)) {
        throw DataFormatError('pirates[$i].id', '해적 id 가 겹친다: ${def.id}');
      }
      defs.add(def);
    }
    return GameData._(ladder, List.unmodifiable(defs));
  }

  final AmmoLadder ladder;

  /// 파일 순서의 해적 정의.
  final List<PirateDef> pirates;

  PirateDef pirate(String id) => pirates.firstWhere(
    (p) => p.id == id,
    orElse: () => throw ArgumentError('알 수 없는 해적: $id'),
  );

  /// 원격 설정으로 수치를 덮어쓴 데이터 (설계서 §7.4, 개발 계획서 A9). 탄종 사다리는
  /// `ammo_<탄종>_<등급>`, 해적은 `pirate_<id>_hp|cooldownTurns|blockDmg|pirateDmg`.
  /// 규칙 검사에 걸리는 값은 [DataFormatError].
  GameData withOverrides(int? Function(String key) intOr) => GameData._(
    ladder.withOverrides(intOr),
    List.unmodifiable([
      for (final p in pirates)
        p.copyWith(
          hp: intOr('pirate_${p.id}_hp'),
          cooldownTurns: intOr('pirate_${p.id}_cooldownTurns'),
          blockDmg: intOr('pirate_${p.id}_blockDmg'),
          pirateDmg: intOr('pirate_${p.id}_pirateDmg'),
        ),
    ]),
  );

  /// `pb_sim` 해적 카탈로그.
  PirateCatalog get catalog => PirateCatalog([
    for (final p in pirates) p.toSpec(ladder),
  ]);

  /// 데이터가 쓰는 문자열 키 중 [arbKeys](ARB 에 있는 키)에 없는 것 (설계서 §14.5).
  List<String> missingTextKeys(Set<String> arbKeys) => [
    for (final p in pirates)
      for (final k in p.textKeys)
        if (!arbKeys.contains(k)) '${p.id}: $k',
  ];
}
