import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:pb_sim/pb_sim.dart';

/// 내 배와 선원 저장소 (설계서 §3.4 설계도 3개, §13.7 편성, ADR-029 hive_ce).
///
/// 설계도는 JSON 으로 3칸에 둔다. 규칙에 맞지 않거나 읽을 수 없는 칸은 빈 칸으로 본다.
abstract class FleetStore {
  /// 설계도 칸 수 (설계서 §3.4).
  static const int slots = 3;

  /// [slot] 칸의 설계도. 비었으면 null.
  Blueprint? blueprint(int slot) {
    final text = readBlueprint(slot);
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, Object?>) return null;
      if (Blueprint.problemOfJson(json) != null) return null;
      return Blueprint.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveBlueprint(int slot, Blueprint blueprint) =>
      writeBlueprint(slot, jsonEncode(blueprint.toJson()));

  /// 전투에 쓰는 설계도 칸 (대표 설계도, 설계서 §13.6).
  int get activeSlot;

  Future<void> setActiveSlot(int slot);

  /// 출전 덱(선실 슬롯 순서의 해적 id). 저장한 적 없으면 null.
  List<String>? get deck;

  Future<void> setDeck(List<String> deck);

  String? readBlueprint(int slot);

  Future<void> writeBlueprint(int slot, String json);
}

/// Hive CE 상자 하나(`fleet`)에 둔다.
class HiveFleetStore extends FleetStore {
  HiveFleetStore._(this._box);

  static const String boxName = 'fleet';
  static const String _activeKey = 'active';
  static const String _deckKey = 'deck';

  final Box<String> _box;

  static Future<HiveFleetStore> open() async =>
      HiveFleetStore._(await Hive.openBox<String>(boxName));

  @override
  String? readBlueprint(int slot) => _box.get('blueprint_$slot');

  @override
  Future<void> writeBlueprint(int slot, String json) =>
      _box.put('blueprint_$slot', json);

  @override
  int get activeSlot => int.tryParse(_box.get(_activeKey) ?? '') ?? 0;

  @override
  Future<void> setActiveSlot(int slot) => _box.put(_activeKey, '$slot');

  @override
  List<String>? get deck {
    final text = _box.get(_deckKey);
    if (text == null || text.isEmpty) return null;
    return text.split(',');
  }

  @override
  Future<void> setDeck(List<String> deck) => _box.put(_deckKey, deck.join(','));
}

/// 메모리에만 두는 저장소. 테스트용.
class MemoryFleetStore extends FleetStore {
  final Map<int, String> _blueprints = {};

  @override
  int activeSlot = 0;

  @override
  List<String>? deck;

  @override
  String? readBlueprint(int slot) => _blueprints[slot];

  @override
  Future<void> writeBlueprint(int slot, String json) async =>
      _blueprints[slot] = json;

  @override
  Future<void> setActiveSlot(int slot) async => activeSlot = slot;

  @override
  Future<void> setDeck(List<String> deck) async => this.deck = List.of(deck);
}
