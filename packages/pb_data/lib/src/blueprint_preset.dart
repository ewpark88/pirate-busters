import 'package:pb_data/src/json_reader.dart';
import 'package:pb_sim/pb_sim.dart';

/// 추천 설계도 하나 (설계서 §3.4: 밸런스·철갑·고속). 글자는 문자열 키로만 가진다.
class BlueprintPreset {
  const BlueprintPreset({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.blueprint,
  });

  /// 설계 규칙 위반·형식 오류는 [DataFormatError].
  factory BlueprintPreset.fromJson(Object? json, {required String path}) {
    final r = JsonReader(json, path: path);
    final raw = r.raw('blueprint');
    if (raw is! Map<String, Object?>) {
      throw DataFormatError('$path.blueprint', '객체여야 한다');
    }
    final String? problem;
    try {
      problem = Blueprint.problemOfJson(raw);
    } on FormatException catch (e) {
      throw DataFormatError('$path.blueprint', e.message);
    }
    if (problem != null) throw DataFormatError('$path.blueprint', problem);
    return BlueprintPreset(
      id: r.string('id'),
      nameKey: r.string('nameKey'),
      descKey: r.string('descKey'),
      blueprint: Blueprint.fromJson(raw),
    );
  }

  final String id;
  final String nameKey;
  final String descKey;
  final Blueprint blueprint;

  /// 확장 단계 (설계서 §3.1). 같은 [id] 가 단계마다 하나씩 있다.
  int get stage => blueprint.hull.stage;

  List<String> get textKeys => [nameKey, descKey];
}

/// `blueprints.json` 의 `presets` 목록을 읽는다. 같은 id·단계가 겹치면 [DataFormatError].
List<BlueprintPreset> parsePresets(Object? json) {
  final root = JsonReader(json, path: 'blueprints.json');
  final out = <BlueprintPreset>[];
  for (final (i, raw) in root.list('presets').indexed) {
    final p = BlueprintPreset.fromJson(raw, path: 'presets[$i]');
    if (out.any((o) => o.id == p.id && o.stage == p.stage)) {
      throw DataFormatError(
        'presets[$i].id',
        '설계도 id·단계가 겹친다: ${p.id} ${p.stage}',
      );
    }
    out.add(p);
  }
  return List.unmodifiable(out);
}
