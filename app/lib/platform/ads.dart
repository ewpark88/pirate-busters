/// 보상형 광고 (설계서 §9). 전투 중에는 띄우지 않는다. AdMob 연결 전에는 [NoAds].
abstract interface class RewardedAds {
  /// 지금 광고를 보여줄 수 있는가(SDK 준비·광고 로드됨).
  bool get available;

  /// 광고를 보여주고 끝까지 봤으면 true.
  Future<bool> show(String placement);
}

/// 광고 자리 이름 (설계서 §9 표).
abstract final class AdPlacements {
  static const String doubleReward = 'double_reward';
}

class NoAds implements RewardedAds {
  const NoAds();

  @override
  bool get available => false;

  @override
  Future<bool> show(String placement) async => false;
}

/// 항상 성공하는 가짜(테스트).
class FakeAds implements RewardedAds {
  FakeAds({this.available = true, this.result = true});

  @override
  bool available;
  bool result;
  final List<String> shown = [];

  @override
  Future<bool> show(String placement) async {
    shown.add(placement);
    return result;
  }
}
