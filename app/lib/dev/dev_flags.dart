import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';

/// 설정 화면에서 버튼이 아닌 곳('언어' 글자 등)을 이만큼 연달아 누르면
/// 운영자 모드 버튼이 나타난다 (ADR-073, ADR-099).
const int devToolsTaps = 7;

/// 운영자 비밀번호의 SHA-256 (ADR-099). 원문은 저장소에 두지 않는다.
/// 기기 안에서만 비교하므로 테스트 빌드용 잠금이지 보안 장치는 아니다.
const String operatorPassHash =
    'ecf56a6238060c5305a857fe5c560c13d6f2015c5a47ea6de29b6eb05b016548';

/// 비교할 비밀번호 해시. 테스트는 원문을 쓰지 않으려고 다른 해시로 덮어쓴다.
final operatorPassHashProvider = Provider<String>((ref) => operatorPassHash);

/// [password] 의 SHA-256 이 [hash] 와 같은가.
bool matchesPassHash(String password, String hash) =>
    sha256.convert(utf8.encode(password)).toString() == hash;

/// 운영자 모드(개발 도구: 전 스테이지·해적 전원·배 0골드·모션 보기·테스트 대전,
/// ADR-053, ADR-073, ADR-099)가 켜져 있는가. 비밀번호로 켠 값을 기기에 남긴다.
/// 빌드 종류와 상관없이 저장값만 따른다(나가기 버튼이 늘 동작하게).
final devToolsProvider = NotifierProvider<DevToolsNotifier, bool>(
  DevToolsNotifier.new,
);

class DevToolsNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsStoreProvider).devTools;

  /// 비밀번호가 맞으면 운영자 모드를 켜고 true. 틀리면 그대로 두고 false.
  Future<bool> enter(String password) async {
    if (!matchesPassHash(password, ref.read(operatorPassHashProvider))) {
      return false;
    }
    await ref.read(settingsStoreProvider).setDevTools(on: true);
    state = true;
    return true;
  }

  /// 사용자 모드로 돌아간다.
  Future<void> exit() async {
    await ref.read(settingsStoreProvider).setDevTools(on: false);
    state = false;
  }
}

/// 숨은 스위치(7번 탭)로 설정 화면에 운영자 모드 버튼을 드러냈는가. 앱을 끄면 다시 숨는다.
final operatorRevealProvider = NotifierProvider<OperatorReveal, bool>(
  OperatorReveal.new,
);

class OperatorReveal extends Notifier<bool> {
  @override
  bool build() => false;

  void reveal() => state = true;
}
