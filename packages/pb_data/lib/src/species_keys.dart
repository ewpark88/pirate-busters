/// 해적 id → 아트 에셋 키 `render.species` (설계서 §4.3 키 표).
///
/// 에셋 키는 종족 이름이 아니라 그림·무기·공격 동작이 함께 쓰는 키다
/// (`characters/<species>/`, `weapons/<species>`, `anims.json` 의
/// `attacks.<species>`). 랍은 계열 키 `lob` 과 헷갈리지 않게 `lobster` 다.
const Map<String, String> speciesKeys = {
  'p01_octo': 'octo',
  'p02_starry': 'starry',
  'p03_crabs': 'crabs',
  'p04_uni': 'uni',
  'p05_volke': 'volke',
  'p06_pang': 'pang',
  'p07_hippo': 'hippo',
  'p08_bones': 'bones',
  'p09_lion': 'lion',
  'p10_volt': 'volt',
  'p11_finn': 'sword',
  'p12_nar': 'nar',
  'p13_walrus': 'walrus',
  'p14_saw': 'saw',
  'p15_moby': 'moby',
  'p16_suri': 'otter',
  'p17_pingu': 'pingu',
  'p18_sheldon': 'sheldon',
  'p19_dolphy': 'dolphy',
  'p20_orca': 'orca',
  'p21_puffy': 'puffer',
  'p22_jelly': 'jelly',
  'p23_bara': 'bara',
  'p24_moray': 'moray',
  'p25_kraki': 'kraki',
  'p26_polly': 'polly',
  'p27_wing': 'gull',
  'p28_pelly': 'pelly',
  'p29_alba': 'alba',
  'p30_manta': 'manta',
  'p31_sharky': 'shark',
  'p32_crabby': 'crabby',
  'p33_king': 'king',
  'p34_lob': 'lobster',
  'p35_davy': 'davy',
  'p36_tok': 'turtle',
  'p37_pumpum': 'pumpum',
  'p38_cook': 'cook',
  'p39_corey': 'corey',
  'p40_lamp': 'lamp',
};

/// [id] 해적의 `render.species` 가 [species] 일 때의 문제. 없으면 null.
///
/// 표에 있는 id 는 표의 키와 같아야 하고, 표에 없는 id(테스트·시즌 해적)도 키는
/// 표에 있는 것 중 하나여야 한다. 그림이 없는 키로는 전투 화면을 그릴 수 없다.
String? speciesProblem(String id, String species) {
  final expected = speciesKeys[id];
  if (expected != null) {
    return expected == species
        ? null
        : 'render.species 는 $expected 이어야 한다 (설계서 §4.3): $species';
  }
  return speciesKeys.containsValue(species)
      ? null
      : 'render.species 가 에셋 키 표에 없다 (설계서 §4.3): $species';
}
