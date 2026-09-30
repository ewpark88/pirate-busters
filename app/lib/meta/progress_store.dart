import 'package:hive_ce/hive.dart';
import 'package:pirate_busters/meta/progress.dart';

/// 진행 저장소 (개발 계획서 M7, ADR-005 Hive CE). 설정·설계도 저장소와 같은 방식.
abstract interface class ProgressStore {
  PlayerProgress get progress;

  Future<void> save(PlayerProgress progress);
}

/// Hive CE 상자 하나(`progress`)에 JSON 한 줄로 둔다.
class HiveProgressStore implements ProgressStore {
  HiveProgressStore._(this._box);

  static const String boxName = 'progress';
  static const String _key = 'state';

  final Box<String> _box;

  /// 상자를 연다. `Hive.initFlutter` 뒤에 부른다.
  static Future<HiveProgressStore> open() async =>
      HiveProgressStore._(await Hive.openBox<String>(boxName));

  @override
  PlayerProgress get progress => PlayerProgress.parse(_box.get(_key));

  @override
  Future<void> save(PlayerProgress progress) =>
      _box.put(_key, progress.encode());
}

/// 메모리에만 두는 저장소. 테스트용.
class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([this.progress = const PlayerProgress()]);

  @override
  PlayerProgress progress;

  @override
  Future<void> save(PlayerProgress progress) async => this.progress = progress;
}
