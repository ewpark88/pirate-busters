// mozzi lib/core/json/json_reader.dart 에서 가져와 고쳤다 (ADR-004): 게임 데이터는
// 정수만 받는다. 실수가 오면 오류다 (설계서 §4.3, §7.1).

/// JSON 형식 오류. 어떤 키가 왜 잘못됐는지 [path] 로 알려 준다.
class DataFormatError implements Exception {
  const DataFormatError(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => 'DataFormatError($path): $reason';
}

/// `Map<String, Object?>` 를 타입을 검사하며 읽는다.
class JsonReader {
  JsonReader(Object? json, {this.path = r'$'})
    : _map = json is Map<String, Object?>
          ? json
          : throw DataFormatError(path, '객체가 아니다 (${json.runtimeType})');

  final Map<String, Object?> _map;
  final String path;

  bool has(String key) => _map.containsKey(key);

  /// 키 이름들(정렬). 순회 순서에 기대지 않도록 정렬해서 준다.
  List<String> get keys => _map.keys.toList()..sort();

  Object? _require(String key) {
    if (!_map.containsKey(key)) throw DataFormatError('$path.$key', '키가 없다');
    return _map[key];
  }

  /// 정수. 실수(1.0 포함)는 받지 않는다.
  int integer(String key) {
    final v = _require(key);
    if (v is int) return v;
    throw DataFormatError('$path.$key', '정수가 아니다 ($v)');
  }

  int integerOr(String key, int fallback) => has(key) ? integer(key) : fallback;

  String string(String key) {
    final v = _require(key);
    if (v is String) return v;
    throw DataFormatError('$path.$key', '문자열이 아니다 ($v)');
  }

  String? stringOrNull(String key) => has(key) ? string(key) : null;

  JsonReader object(String key) =>
      JsonReader(_require(key), path: '$path.$key');

  JsonReader objectOr(String key) => has(key)
      ? object(key)
      : JsonReader(const <String, Object?>{}, path: '$path.$key');

  List<Object?> list(String key) {
    final v = _require(key);
    if (v is List<Object?>) return v;
    throw DataFormatError('$path.$key', '배열이 아니다 ($v)');
  }

  List<String> stringList(String key) => [
    for (final (i, v) in list(key).indexed)
      v is String
          ? v
          : throw DataFormatError('$path.$key[$i]', '문자열이 아니다 ($v)'),
  ];

  /// 원본 값 (배열 원소 등을 직접 볼 때).
  Object? raw(String key) => _require(key);
}
