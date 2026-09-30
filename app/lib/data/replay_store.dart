import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:pb_sim/pb_sim.dart';

/// 리플레이 저장소 (설계서 §7.2, §13.5 ‘리플레이 저장’). 한 판이 수 KB 라 JSON 문자열로 둔다.
abstract interface class ReplayStore {
  /// 저장한 리플레이 이름(저장 순).
  List<String> get names;

  Replay? load(String name);

  Future<void> save(String name, Replay replay);
}

/// Hive CE 상자 하나(`replays`)에 둔다. 최근 [keep] 개만 남긴다.
class HiveReplayStore implements ReplayStore {
  HiveReplayStore._(this._box);

  static const String boxName = 'replays';
  static const int keep = 20;

  final Box<String> _box;

  static Future<HiveReplayStore> open() async =>
      HiveReplayStore._(await Hive.openBox<String>(boxName));

  @override
  List<String> get names => _box.keys.cast<String>().toList()..sort();

  @override
  Replay? load(String name) {
    final text = _box.get(name);
    if (text == null) return null;
    try {
      return Replay.fromJson(jsonDecode(text) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(String name, Replay replay) async {
    await _box.put(name, jsonEncode(replay.toJson()));
    final all = names;
    for (final old in all.take(all.length > keep ? all.length - keep : 0)) {
      await _box.delete(old);
    }
  }
}

/// 메모리 저장소(테스트).
class MemoryReplayStore implements ReplayStore {
  final Map<String, Replay> _replays = {};

  @override
  List<String> get names => _replays.keys.toList()..sort();

  @override
  Replay? load(String name) => _replays[name];

  @override
  Future<void> save(String name, Replay replay) async =>
      _replays[name] = replay;
}
