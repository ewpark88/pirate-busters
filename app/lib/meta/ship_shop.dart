import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';

/// 배 해금 사기 (설계서 §13.6 "배 업그레이드는 모두 골드", 금액: BALANCE.md A3.2).
/// 순수 함수만 둔다. 살 수 없으면 null 을 돌려준다. `free` 는 개발 도구 테스트용:
/// 골드를 쓰지 않는다.
abstract final class ShipShop {
  /// 재질을 연다.
  static PlayerProgress? unlockMaterial(
    PlayerProgress p,
    BlockMaterial m, {
    bool free = false,
  }) {
    final gold = ShipUpgrades.materialGold[m];
    if (gold == null || p.ship.hasMaterial(m)) return null;
    return _pay(
      p,
      free ? 0 : gold,
      p.ship.copyWith(materials: [...p.ship.materials, m.name]),
    );
  }

  /// 모듈을 연다. 선장실·돛대는 처음부터 쓰므로 열 것이 없다 (ADR-111).
  static PlayerProgress? unlockModule(
    PlayerProgress p,
    ModuleKind k, {
    bool free = false,
  }) => null;

  static PlayerProgress? _pay(PlayerProgress p, int gold, ShipUpgrades next) {
    if (p.gold < gold) return null;
    return p.copyWith(gold: p.gold - gold, ship: next);
  }
}
