import 'package:flutter/foundation.dart';

/// 개발 도구(테스트 대전 등)를 보일지 (ADR-053). 디버그 빌드이거나
/// `--dart-define=DEV_TOOLS=true` 로 빌드했을 때만 켜진다. 스토어 빌드에는 안 보인다.
const bool devTools = kDebugMode || bool.fromEnvironment('DEV_TOOLS');
