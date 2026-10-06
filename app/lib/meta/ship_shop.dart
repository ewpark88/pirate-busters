import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';

/// 배 업그레이드 사기 (설계서 §13.6 "배 업그레이드는 모두 골드", 금액: BALANCE.md
/// A13.6·A3.2). 순수 함수만 둔다. 살 수 없으면 null 을 돌려준다. `free` 는 개발 도구
/// 테스트용: 골드를 쓰지 않고 열림 조건도 보지 않는다.
abstract final class ShipShop {
  /// 다음 확장 단계와 그 골드. 다 자랐으면 null.
  static (int, int)? nextStage(ShipUpgrades s) {
    final next = s.stage + 1;
    if (next > HullSpec.maxStage) return null;
    return (next, ShipUpgrades.stageGold[next]!);
  }

  /// 다음 확장 단계를 짓는다. [opened] 는 스테이지로 열린 가장 큰 단계.
  static PlayerProgress? buildStage(
    PlayerProgress p, {
    required int opened,
    bool free = false,
  }) {
    final next = nextStage(p.ship);
    if (next == null) return null;
    final (stage, gold) = next;
    if (!free && stage > opened) return null;
    return _pay(p, free ? 0 : gold, p.ship.copyWith(stage: stage));
  }

  /// 선형 레벨을 하나 올린다.
  static PlayerProgress? levelHull(PlayerProgress p, {bool free = false}) {
    final to = p.ship.hullLevel + 1;
    if (to > HullSpec.maxLevel) return null;
    return _pay(
      p,
      free ? 0 : ShipUpgrades.hullLevelGold(to),
      p.ship.copyWith(hullLevel: to),
    );
  }

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

  /// 모듈·돛대 종류를 연다.
  static PlayerProgress? unlockModule(
    PlayerProgress p,
    ModuleKind k, {
    bool free = false,
  }) {
    final gold = ShipUpgrades.moduleGold[k];
    if (gold == null || p.ship.hasModule(k)) return null;
    return _pay(
      p,
      free ? 0 : gold,
      p.ship.copyWith(modules: [...p.ship.modules, k.jsonName]),
    );
  }

  /// 연 돛대 종류의 레벨을 하나 올린다.
  static PlayerProgress? levelMast(
    PlayerProgress p,
    ModuleKind k, {
    bool free = false,
  }) {
    if (!k.isMast || !p.ship.hasModule(k)) return null;
    final to = p.ship.mastLevel(k) + 1;
    final gold = ShipUpgrades.mastLevelGold[to];
    if (gold == null) return null;
    return _pay(
      p,
      free ? 0 : gold,
      p.ship.copyWith(mastLevels: {...p.ship.mastLevels, k.jsonName: to}),
    );
  }

  static PlayerProgress? _pay(PlayerProgress p, int gold, ShipUpgrades next) {
    if (p.gold < gold) return null;
    return p.copyWith(gold: p.gold - gold, ship: next);
  }

  /// 저장한 설계도 JSON 을 단계 [stage] 로 키운다(설계서 §3.1): 블록·선실·모듈을 가운데에
  /// 맞춰 옮기고 새 칸은 비운다. 이미 그 단계 이상이면 그대로.
  static Map<String, Object?> grow(Map<String, Object?> json, int stage) {
    final from = json['stage'] is int
        ? json['stage']! as int
        : HullSpec.maxStage;
    if (from >= stage) return json;
    final old = HullSpec.byId('sloop', stage: from);
    final dx = (HullSpec.byId('sloop', stage: stage).width - old.width) ~/ 2;
    List<Object?> moved(Object? list) => [
      if (list is List<Object?>)
        for (final raw in list)
          if (raw is List<Object?> && raw.isNotEmpty && raw[0] is int)
            [(raw[0]! as int) + dx, ...raw.skip(1)]
          else
            raw,
    ];
    return {
      ...json,
      'stage': stage,
      'cells': moved(json['cells']),
      'cabins': moved(json['cabins']),
      'modules': moved(json['modules']),
    };
  }
}
