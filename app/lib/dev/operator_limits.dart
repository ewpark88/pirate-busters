import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pirate_busters/app/providers.dart';
import 'package:pirate_busters/dev/dev_flags.dart';
import 'package:pirate_busters/dev/test_battle.dart';

/// 출전 코스트 한도 (설계서 §4.5). 운영자 모드면 테스트 대전과 같이 한도 없이
/// 아무 조합이나 태운다 (ADR-099). 매치 시작 때 넘기는 값만 바뀌고 판정은 pb_sim 그대로다.
final costLimitProvider = Provider<int>(
  (ref) => ref.watch(devToolsProvider)
      ? TestBattle.costLimit
      : ref.watch(progressProvider).costLimit,
);
