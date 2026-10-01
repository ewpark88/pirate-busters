import 'package:pb_ai/pb_ai.dart';
import 'package:pirate_busters/campaign/stage_spec.dart';
import 'package:pirate_busters/platform/remote_values.dart';

/// 원격 설정으로 스테이지 한 판의 값을 덮어쓴다 (설계서 §7.4 `campaign_*`, 개발 계획서
/// A9). 키는 `stage_<id>_aiLevel`(난이도 이름 글자)·`stage_<id>_waveLevel`(0~3)·
/// `stage_<id>_maxWind`(0~5)·`stage_<id>_starTurns`·`stage_<id>_rewardGold`.
/// 범위 밖이거나 모르는 값은 무시한다.
StageSpec applyRemoteStage(StageSpec stage, RemoteValues remote) {
  final prefix = 'stage_${stage.id}_';
  int? at(String name, {int min = 0, int max = 1 << 30}) {
    final v = remote.intOr('$prefix$name');
    return v == null || v < min || v > max ? null : v;
  }

  final levelName = remote.stringOr('${prefix}aiLevel');
  AiLevel? level;
  for (final l in AiLevel.values) {
    if (l.name == levelName) level = l;
  }
  return stage.copyWith(
    aiLevel: level,
    waveLevel: at('waveLevel', max: 3),
    maxWind: at('maxWind', max: 5),
    starTurns: at('starTurns', min: 1),
    rewardGold: at('rewardGold'),
  );
}
