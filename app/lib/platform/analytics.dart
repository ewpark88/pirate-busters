/// 분석 이벤트 (개발 계획서 M7). 실제 Firebase Analytics 연결은 `google-services.json` 이
/// 들어온 뒤 구현체를 바꿔 끼운다. 이벤트 이름과 파라미터는 여기서만 정한다.
abstract interface class Analytics {
  void log(String name, [Map<String, Object> params = const {}]);

  /// 화면 진입(항구·캠페인·조선소 등).
  void screen(String name);
}

/// 계획서 M7 이벤트 이름.
abstract final class Events {
  static const String matchStart = 'match_start';
  static const String matchEnd = 'match_end';
  static const String turnEnd = 'turn_end';
  static const String firstMatchComplete = 'first_match_complete';
  static const String stageClear = 'stage_clear';
  static const String adRewardView = 'ad_reward_view';
  static const String iapPurchase = 'iap_purchase';
  static const String shipyardSave = 'shipyard_save';
}

/// 아무것도 하지 않는다(기본).
class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void log(String name, [Map<String, Object> params = const {}]) {}

  @override
  void screen(String name) {}
}

/// 기록만 한다(테스트).
class MemoryAnalytics implements Analytics {
  final List<({String name, Map<String, Object> params})> events = [];

  @override
  void log(String name, [Map<String, Object> params = const {}]) =>
      events.add((name: name, params: Map.of(params)));

  @override
  void screen(String name) => log('screen_$name');

  List<String> get names => [for (final e in events) e.name];
}
