import 'package:flutter/foundation.dart';

/// 크래시 보고 (개발 계획서 M7 Crashlytics). SDK 연결 전에는 로그만 남긴다.
abstract interface class CrashReporter {
  void record(Object error, StackTrace? stack, {bool fatal = false});

  void log(String message);
}

class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  void record(Object error, StackTrace? stack, {bool fatal = false}) {
    if (kDebugMode) debugPrint('crash: $error\n$stack');
  }

  @override
  void log(String message) {}
}

/// 프레임워크·플랫폼 오류를 [reporter] 로 보낸다. 부트스트랩에서 한 번 부른다.
void installCrashReporter(CrashReporter reporter) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    reporter.record(details.exception, details.stack, fatal: true);
    previous?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.record(error, stack, fatal: true);
    return true;
  };
}
