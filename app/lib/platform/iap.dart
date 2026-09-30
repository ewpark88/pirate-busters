/// 인앱 결제 (설계서 §9). MVP 는 광고 제거 하나다. 스토어 연결 전에는 [NoIap].
abstract interface class Iap {
  bool get available;

  /// 광고 제거를 샀는가(복원 포함).
  bool get adsRemoved;

  /// 광고 제거 구매. 성공하면 true.
  Future<bool> buyRemoveAds();
}

class NoIap implements Iap {
  const NoIap();

  @override
  bool get available => false;

  @override
  bool get adsRemoved => false;

  @override
  Future<bool> buyRemoveAds() async => false;
}

/// 메모리 가짜(테스트).
class FakeIap implements Iap {
  FakeIap({this.available = true, this.adsRemoved = false});

  @override
  bool available;

  @override
  bool adsRemoved;

  @override
  Future<bool> buyRemoveAds() async => adsRemoved = true;
}
