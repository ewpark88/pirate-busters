import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_busters/l10n/app_localizations.dart';

/// 자리표시자가 둘 이상인 문장은 인자 순서가 호출 순서와 같아야 한다.
/// 정의가 없으면 gen-l10n 이 이름 알파벳순으로 만들어 값이 뒤바뀐다
/// (docs/quality/2026-10-02-gap-analysis.md, 설계서 §14.2).
void main() {
  final ko = lookupAppLocalizations(const Locale('ko'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('전투 준비 코스트는 사용량 / 한도 순서로 나온다', () {
    expect(ko.prepCost(6, 15), '코스트 6 / 15');
    expect(en.prepCost(6, 15), 'Cost 6 / 15');
  });

  test('결과 화면 침수량은 내 것과 상대 것이 뒤바뀌지 않는다', () {
    final text = en.statFlood(12, 40);
    expect(text.indexOf('12'), lessThan(text.indexOf('40')));
  });

  test('결과 화면 피해와 부순 블록 수가 뒤바뀌지 않는다', () {
    final text = en.statDamage(11, 320);
    expect(text.indexOf('11'), lessThan(text.indexOf('320')));
  });

  test('항구 경험치는 현재 값 / 다음 레벨 값 순서로 나온다', () {
    final text = en.portXp('120', '300');
    expect(text.indexOf('120'), lessThan(text.indexOf('300')));
  });

  test('전투 준비 날씨는 파도 · 바람 순서로 나온다', () {
    final text = en.prepWeather(1, 5);
    expect(text.indexOf('1'), lessThan(text.indexOf('5')));
  });
}
