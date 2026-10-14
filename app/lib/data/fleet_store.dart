import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:pb_sim/pb_sim.dart';

/// 내 배와 선원 저장소 (설계서 §3.4 설계도 3개, §13.7 편성, ADR-029 hive_ce).
///
/// 설계도는 JSON 으로 3칸에 둔다. 규칙에 맞지 않거나 읽을 수 없는 칸은 빈 칸으로 본다.
abstract class FleetStore {
  /// 설계도 칸 수 (설계서 §3.4).
  static const int slots = 3;

  /// [slot] 칸의 설계도. 비었거나 지금 규칙(설계서 §3, ADR-111)에 맞지 않으면 null.
  /// 옛 확장 단계·재질·모듈로 저장한 설계도는 빈 칸으로 본다.
  Blueprint? blueprint(int slot) {
    final json = draft(slot);
    if (json == null) return null;
    try {
      // 옛 모듈·재질 이름은 problemOfJson 에서 FormatException 으로 난다.
      if (Blueprint.problemOfJson(json) != null) return null;
      return Blueprint.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  /// [slot] 칸 설계도 JSON 초안. 규칙 검사를 하지 않는다(선실을 아직 다 놓지 않은 배도
  /// 조선소에서 이어 고친다). 비었거나 읽을 수 없으면 null.
  Map<String, Object?>? draft(int slot) {
    final text = readBlueprint(slot);
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      return json is Map<String, Object?> ? json : null;
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

  /// 테스트 대전에서 마지막으로 고른 덱 ([side] 0 = 나, 1 = 상대, ADR-053).
  List<String> testDeck(int side);

  Future<void> setTestDeck(int side, List<String> deck);

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

  @override
  List<String> testDeck(int side) {
    final text = _box.get('test_deck_$side') ?? '';
    return text.isEmpty ? const [] : text.split(',');
  }

  @override
  Future<void> setTestDeck(int side, List<String> deck) =>
      _box.put('test_deck_$side', deck.join(','));
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

  final Map<int, List<String>> _testDecks = {};

  @override
  List<String> testDeck(int side) => _testDecks[side] ?? const [];

  @override
  Future<void> setTestDeck(int side, List<String> deck) async =>
      _testDecks[side] = List.of(deck);
}
