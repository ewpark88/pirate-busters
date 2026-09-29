/// `jsonDecode` 결과(Map/List)에서 정해진 타입으로 값을 꺼낸다.
/// 타입이 다르면 [FormatException]. 실수는 받지 않는다 (설계서 §4.3).
library;

int readInt(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is int) return v;
  throw FormatException('"$key" 는 정수여야 한다: $v');
}

String readString(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is String) return v;
  throw FormatException('"$key" 는 문자열이어야 한다: $v');
}

List<Object?> readList(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is List<Object?>) return v;
  throw FormatException('"$key" 는 배열이어야 한다: $v');
}

Map<String, Object?> asMap(Object? v, String what) {
  if (v is Map<String, Object?>) return v;
  throw FormatException('$what 는 객체여야 한다: $v');
}

int asInt(Object? v, String what) {
  if (v is int) return v;
  throw FormatException('$what 는 정수여야 한다: $v');
}

String asString(Object? v, String what) {
  if (v is String) return v;
  throw FormatException('$what 는 문자열이어야 한다: $v');
}
