import 'package:pb_sim/pb_sim.dart';

/// 원격 설정 값 (설계서 §7.4 Remote Config 키 목록). Firebase 연결 전에는 비어 있다.
/// 원격 글자는 `{"ko": …, "en": …}` 로만 받는다(§14.3).
abstract interface class RemoteValues {
  int? intOr(String key);

  String? stringOr(String key);
}

class EmptyRemoteValues implements RemoteValues {
  const EmptyRemoteValues();

  @override
  int? intOr(String key) => null;

  @override
  String? stringOr(String key) => null;
}

/// 메모리 값(테스트·개발).
class MemoryRemoteValues implements RemoteValues {
  MemoryRemoteValues([Map<String, Object> values = const {}])
    : _values = Map.of(values);

  final Map<String, Object> _values;

  @override
  int? intOr(String key) {
    final v = _values[key];
    return v is int ? v : null;
  }

  @override
  String? stringOr(String key) {
    final v = _values[key];
    return v is String ? v : null;
  }
}

/// 원격 값으로 매치 규칙을 덮어쓴다. 키는 `turn_`·`fuel_`·`flood_`·`range_` 접두사 +
/// 규칙 필드 이름(예: `turn_maxTurns`, `fuel_fuelPerTurn`, `flood_floodFullCell`).
/// 값이 규칙 검사에 걸리면 기본 규칙을 쓴다.
MatchRules applyRemoteRules(MatchRules base, RemoteValues remote) {
  final json = base.toJson();
  var changed = false;
  for (final key in json.keys) {
    for (final prefix in const ['turn_', 'fuel_', 'flood_', 'range_']) {
      final v = remote.intOr('$prefix$key');
      if (v != null) {
        json[key] = v;
        changed = true;
      }
    }
  }
  if (!changed) return base;
  try {
    return MatchRules.fromJson(json);
  } on FormatException {
    return base;
  }
}
