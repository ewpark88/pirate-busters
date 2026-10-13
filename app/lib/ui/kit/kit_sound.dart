import 'package:flutter/widgets.dart';

/// 키트 버튼 누름 소리 (설계서 §10.3 ‘버튼 누름(메타 화면 포함)’, A55).
///
/// 앱 루트가 효과음 설정에 맞춰 [click] 을 넣고, `Pressable`(키트 버튼·카드)이 누를 때
/// 부른다. 효과음을 끄면 [click] 이 null 이다. 테스트처럼 위에 없으면 조용하다.
class KitSound extends InheritedWidget {
  const KitSound({required this.click, required super.child, super.key});

  /// 누름 소리를 낸다. 없으면 소리를 내지 않는다.
  final VoidCallback? click;

  /// [context] 위의 누름 소리를 낸다.
  static void clickOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<KitSound>()?.click?.call();

  @override
  bool updateShouldNotify(KitSound oldWidget) => false;
}
