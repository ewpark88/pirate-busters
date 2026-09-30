import 'package:pb_data/src/ammo_ladder.dart';
import 'package:pb_data/src/json_reader.dart';
import 'package:pb_sim/pb_sim.dart';

/// 등급 배율(‰): 일반 1.00 · 희귀 1.10 · 영웅 1.25 · 전설 1.45 · 신화 1.65 (설계서 §4.4).
/// 체력·블록 피해·해적 피해에 곱한다. 레벨 배율은 R4(MVP 는 Lv1).
const List<int> rarityPermille = [1000, 1100, 1250, 1450, 1650];

/// 해적 한 명의 데이터 정의 (설계서 §4.3). 글자는 문자열 키로만 가진다(§14.3).
class PirateDef {
  PirateDef._({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.loreKey,
    required this.family,
    required this.rarity,
    required this.hp,
    required this.cooldownTurns,
    required this.ammo,
    required this.spreadDeg,
    required this.ammoParam,
    required this.range,
    required this.radiusCells,
    required this.blockDmg,
    required this.pirateDmg,
    required this.growth,
    required this.species,
    required this.props,
    required this.teamColorPart,
  });

  /// 형식 오류는 [DataFormatError].
  factory PirateDef.fromJson(Object? json, {String path = 'pirate'}) {
    final r = JsonReader(json, path: path);
    final ammo = r.object('ammo');
    final projectile = r.objectOr('projectile');
    final onHit = r.objectOr('onHit');
    final render = r.object('render');
    final growth = r.objectOr('growth');
    final family = _parse(
      () => Family.byName(r.string('family')),
      '$path.family',
    );
    final rangeName = projectile.stringOrNull('range');
    final def = PirateDef._(
      id: r.string('id'),
      nameKey: r.string('nameKey'),
      descKey: r.string('descKey'),
      loreKey: r.string('loreKey'),
      family: family,
      rarity: _parse(() => Rarity.byName(r.string('rarity')), '$path.rarity'),
      hp: r.integer('hp'),
      cooldownTurns: r.integer('cooldownTurns'),
      ammo: _parse(
        () => AmmoType.byName(ammo.string('type')),
        '$path.ammo.type',
      ),
      spreadDeg: ammo.integerOr('spreadDeg', 0),
      ammoParam: ammo.integerOr('repairCells', ammo.integerOr('delayed', 0)),
      range: rangeName == null
          ? family.defaultRange
          : _parse(
              () => RangeGrade.byName(rangeName),
              '$path.projectile.range',
            ),
      radiusCells: onHit.integerOr('radiusCells', 0),
      blockDmg: onHit.integerOr('blockDmg', 0),
      pirateDmg: onHit.integerOr('pirateDmg', 0),
      // 성장 특성은 파싱만 한다. MVP 는 전부 Lv1 이다(개발 계획서 M5).
      growth: {for (final k in growth.keys) k: growth.string(k)},
      species: render.string('species'),
      props: render.has('props') ? render.stringList('props') : const [],
      teamColorPart: render.stringOrNull('teamColorPart') ?? '',
    );
    return def.._check(path);
  }

  static T _parse<T>(T Function() f, String path) {
    try {
      return f();
    } on FormatException catch (e) {
      throw DataFormatError(path, e.message);
    }
  }

  void _check(String path) {
    void need({required bool ok, required String what}) {
      if (!ok) throw DataFormatError(path, '$id: $what');
    }

    need(ok: hp > 0, what: '체력은 양수');
    need(
      ok: cooldownTurns >= 0 && cooldownTurns <= maxCooldownTurns,
      what: '쿨다운 0~2턴',
    );
    need(ok: radiusCells >= 0 && radiusCells <= 2, what: '폭발 반경 0~2칸 (§4.8)');
    need(ok: blockDmg >= 0 && pirateDmg >= 0, what: '피해는 0 이상');
  }

  final String id;
  final String nameKey;
  final String descKey;
  final String loreKey;
  final Family family;
  final Rarity rarity;
  final int hp;
  final int cooldownTurns;
  final AmmoType ammo;
  final int spreadDeg;
  final int ammoParam;
  final RangeGrade range;
  final int radiusCells;
  final int blockDmg;
  final int pirateDmg;
  final Map<String, String> growth;
  final String species;
  final List<String> props;
  final String teamColorPart;

  /// 화면에 보이는 글자의 키.
  List<String> get textKeys => [nameKey, descKey, loreKey];

  /// `pb_sim` 정수 정의로 바꾼다: 등급 배율을 곱하고 탄종 등급 수치를 사다리에서 찾는다.
  PirateSpec toSpec(AmmoLadder ladder) {
    final mul = rarityPermille[rarity.step];
    int scaled(int v) => v * mul ~/ 1000;
    final (value, value2) = ladder.valueOf(ammo, rarity);
    return PirateSpec(
      id: id,
      rarity: rarity,
      hp: scaled(hp),
      cooldownTurns: cooldownTurns,
      blockDamage: scaled(blockDmg),
      pirateDamage: scaled(pirateDmg),
      blastRadius: radiusCells,
      range: range,
      family: family,
      ammo: ammo,
      ammoValue: value,
      ammoValue2: value2,
      spreadMdeg: spreadDeg * 1000,
      ammoParam: ammoParam,
    );
  }
}
