import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/meta/ship_shop.dart';

/// 내 배와 선원 저장소 (설계서 §3.4 설계도 3개, §13.7 편성, ADR-029 hive_ce).
///
/// 설계도는 JSON 으로 3칸에 둔다. 규칙에 맞지 않거나 읽을 수 없는 칸은 빈 칸으로 본다.
abstract class FleetStore {
  /// 설계도 칸 수 (설계서 §3.4).
  static const int slots = 3;

  /// [slot] 칸의 설계도. 비었으면 null. [stage] 를 주면 그보다 작은 단계로 저장한
  /// 설계도를 그 단계로 키우고(설계서 §3.1), 더 큰 단계로 저장한 것은 빈 칸으로 본다.
  Blueprint? blueprint(int slot, {int? stage}) {
    final text = readBlueprint(slot);
    if (text == null) return null;
    try {
      var json = jsonDecode(text);
      if (json is! Map<String, Object?>) return null;
      if (stage != null) {
        final saved = json['stage'] is int
            ? json['stage']! as int
            : HullSpec.maxStage;
        if (saved > stage) return null;
        json = ShipShop.grow(json, stage);
      }
      final fitted = fitToFrame(json);
      if (Blueprint.problemOfJson(fitted) != null) return null;
      return Blueprint.fromJson(fitted);
    } on FormatException {
      return null;
    }
  }

  /// [slot] 칸 설계도 JSON 을 [stage] 로 키운 초안. 규칙 검사를 하지 않는다(새 선실을
  /// 아직 안 놓은 배도 조선소에서 이어 고친다, 설계서 §3.1). 비었거나 더 큰 단계면 null.
  Map<String, Object?>? draft(int slot, int stage) {
    final text = readBlueprint(slot);
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, Object?>) return null;
      final saved = json['stage'] is int
          ? json['stage']! as int
          : HullSpec.maxStage;
      return saved > stage ? null : fitToFrame(ShipShop.grow(json, stage));
    } on FormatException {
      return null;
    }
  }

  /// 선체 틀(설계서 §3.4)이 생기기 전에 저장한 설계도를 살린다: 틀 밖 블록과 그 칸의
  /// 모듈을 뺀다. 나머지 규칙(용골 연결·선실)은 그대로 검사한다.
  static Map<String, Object?> fitToFrame(Map<String, Object?> json) {
    final hullId = json['hull'];
    if (hullId is! String) return json;
    final hull = HullSpec.byId(hullId);
    bool keep(Object? raw) =>
        raw is! List<Object?> ||
        raw.length < 2 ||
        raw[0] is! int ||
        raw[1] is! int ||
        hull.inFrame(raw[0]! as int, raw[1]! as int);
    List<Object?> only(Object? list) => [
      if (list is List<Object?>)
        for (final raw in list)
          if (keep(raw)) raw,
    ];
    return {
      ...json,
      'cells': only(json['cells']),
      'modules': only(json['modules']),
    };
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
