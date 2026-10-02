import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';

/// 빌드부터 개발 도구가 켜져 있는가 (ADR-053). 디버그 빌드이거나
/// `--dart-define=DEV_TOOLS=true` 로 빌드했을 때다.
const bool devToolsBuild = kDebugMode || bool.fromEnvironment('DEV_TOOLS');

/// 설정 화면에서 버튼이 아닌 곳('언어' 글자 등)을 이만큼 연달아 누르면 개발 도구를 켜고 끈다 (ADR-073).
const int devToolsTaps = 7;

/// 개발 도구(테스트 대전·해적 전원·더미배 연습)를 보일지 (ADR-053, ADR-073).
/// 개발 빌드면 늘 켜져 있고, 아니면 숨은 스위치로 켠 값을 기기에 남긴다.
final devToolsProvider = NotifierProvider<DevToolsNotifier, bool>(
  DevToolsNotifier.new,
);

class DevToolsNotifier extends Notifier<bool> {
  @override
  bool build() => devToolsBuild || ref.read(settingsStoreProvider).devTools;

  /// 숨은 스위치를 뒤집고 화면에 보일 새 값을 돌려준다. 개발 빌드에서는 늘 켜져 있다.
  Future<bool> toggle() async {
    final on = !ref.read(settingsStoreProvider).devTools;
    await ref.read(settingsStoreProvider).setDevTools(on: on);
    return state = devToolsBuild || on;
  }
}
