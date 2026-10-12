import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/meta/progress.dart';
import 'package:pirate_busters/meta/ship_upgrades.dart';

/// 운영자 화면의 진행 조작 (ADR-099). 누를 때만 저장을 바꾸는 순수 함수들이다.
abstract final class OperatorActions {
  /// 한 번에 더하는 골드.
  static const int gold = 10000;

  /// 배 업그레이드를 모두 끝낸 상태: 마지막 확장 단계, 선형 최고 레벨,
  /// 모든 재질·모듈, 모든 돛대 최고 레벨 (설계서 §3.1·§3.3·§13.6).
  static final ShipUpgrades maxedShip = ShipUpgrades(
    stage: HullSpec.maxStage,
    hullLevel: HullSpec.maxLevel,
    materials: [for (final m in ShipUpgrades.materialGold.keys) m.name],
    modules: [for (final k in ShipUpgrades.moduleGold.keys) k.jsonName],
    mastLevels: {
      for (final k in ModuleKind.values)
        if (k.isMast) k.jsonName: BlockMaterial.maxRigLevel,
    },
  );

  static PlayerProgress maxShip(PlayerProgress p) =>
      p.copyWith(ship: maxedShip);

  static PlayerProgress addGold(PlayerProgress p) => p.addGold(gold);

  /// 플레이어 최고 레벨: 출전 코스트 한도가 가장 크다 (설계서 §4.5).
  static PlayerProgress maxLevel(PlayerProgress p) =>
      p.copyWith(level: PlayerProgress.maxLevel, xp: 0);

  /// [ids] 해적을 모두 보유로.
  static PlayerProgress allPirates(PlayerProgress p, Iterable<String> ids) =>
      ids.fold(p, (q, id) => q.addPirate(id));

  /// 처음 설치한 상태(프롤로그부터).
  static PlayerProgress reset(PlayerProgress _) => const PlayerProgress();
}
