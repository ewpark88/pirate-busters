import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pb_data/pb_data.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/data/game_catalog.dart';

/// 캠페인 데이터 (설계서 §6.1). MVP 는 해역 1 하나다(§11.1). 에셋 `assets/stages/`
/// 에서 읽고 게임 데이터와 맞는지 검증한다.
class CampaignCatalog {
  const CampaignCatalog(this.seas);

  /// 파일 본문으로 만든다. 형식 오류는 [DataFormatError], 게임 데이터와 안 맞으면
  /// [ArgumentError].
  factory CampaignCatalog.parse(List<String> seaJsons, GameCatalog game) {
    final seas = [for (final j in seaJsons) SeaSpec.fromJson(jsonDecode(j))];
    final problems = [
      for (final sea in seas)
        ...sea.problems(
          hasPirate: game.pirates.has,
          hasPreset: (id) => game.presets.any((p) => p.id == id),
        ),
    ];
    if (problems.isNotEmpty) {
      throw ArgumentError('캠페인 데이터 오류: ${problems.join(', ')}');
    }
    return CampaignCatalog(seas);
  }

  static const String _dir = 'assets/stages';

  /// MVP 해역 파일.
  static const List<String> files = ['sea1.json'];

  static Future<CampaignCatalog> load(
    AssetBundle bundle,
    GameCatalog game,
  ) async => CampaignCatalog.parse([
    for (final f in files) await bundle.loadString('$_dir/$f'),
  ], game);

  final List<SeaSpec> seas;

  SeaSpec sea(int number) => seas.firstWhere(
    (s) => s.sea == number,
    orElse: () => throw ArgumentError('해역 없음: $number'),
  );

  /// 튜토리얼 3판 (설계서 §13.1). 해역 1 파일에 있다.
  List<StageSpec> get tutorial => sea(1).tutorial;

  StageSpec stage(String id) {
    for (final s in seas) {
      for (final st in s.stages) {
        if (st.id == id) return st;
      }
    }
    throw ArgumentError('스테이지 없음: $id');
  }
}
