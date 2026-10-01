import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pb_sim/pb_sim.dart';

/// 앱이 쓰는 게임 데이터: 해적 정의·탄종 사다리·추천 설계도 (설계서 §3.4, §4.3, §4.8).
/// 시작할 때 에셋 `assets/game/` 에서 한 번 읽고 검증한다.
class GameCatalog {
  GameCatalog._(this.data, this.presets)
    : pirates = data.catalog,
      _species = {for (final p in data.pirates) p.id: p.species};

  /// 파일 본문으로 만든다. 형식·규칙 오류는 [DataFormatError].
  factory GameCatalog.parse({
    required String ammoJson,
    required String piratesJson,
    required String blueprintsJson,
  }) => GameCatalog._(
    GameData.parse(ammoJson: ammoJson, piratesJson: piratesJson),
    parsePresets(jsonDecode(blueprintsJson)),
  );

  static const String _dir = 'assets/game';

  /// 에셋에서 읽는다.
  static Future<GameCatalog> load(AssetBundle bundle) async =>
      GameCatalog.parse(
        ammoJson: await bundle.loadString('$_dir/ammo.json'),
        piratesJson: await bundle.loadString('$_dir/pirates.json'),
        blueprintsJson: await bundle.loadString('$_dir/blueprints.json'),
      );

  /// 원격 설정으로 해적 수치·탄종 사다리를 덮어쓴 카탈로그 (설계서 §7.4).
  GameCatalog applyRemote(int? Function(String key) intOr) =>
      GameCatalog._(data.withOverrides(intOr), presets);

  final GameData data;

  /// 추천 설계도 (밸런스·철갑·고속).
  final List<BlueprintPreset> presets;

  /// `pb_sim` 해적 정의.
  final PirateCatalog pirates;

  final Map<String, String> _species;

  /// 해적 정의 (이름·설명 키, 계열·등급 등).
  PirateDef def(String id) => data.pirate(id);

  /// 해적 id → 그림 종족 id (`assets/images/characters/<종족>`).
  String speciesOf(String pirateId) => _species[pirateId] ?? pirateId;

  /// id 로 추천 설계도를 찾는다.
  BlueprintPreset preset(String id) => presets.firstWhere(
    (p) => p.id == id,
    orElse: () => throw ArgumentError('알 수 없는 추천 설계도: $id'),
  );
}
