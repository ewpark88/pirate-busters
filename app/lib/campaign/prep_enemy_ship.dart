import 'package:flutter/material.dart';
import 'package:pb_sim/pb_sim.dart';
import 'package:pirate_busters/shipyard/blueprint_preview.dart';

/// 전투 준비의 상대 배 미리보기와 그 위 선장 대사 말풍선 (설계서 §13.3, §15.4).
/// 누르면 다음 대사로 넘긴다.
class PrepEnemyShip extends StatelessWidget {
  const PrepEnemyShip({
    required this.blueprint,
    required this.line,
    required this.tapHint,
    required this.onTap,
    super.key,
  });

  final Blueprint blueprint;

  /// 지금 대사(빈 글자면 말풍선 없음).
  final String line;
  final String tapHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Stack(
      children: [
        Positioned.fill(
          top: line.isEmpty ? 0 : 52,
          child: BlueprintPreview(blueprint: blueprint),
        ),
        if (line.isNotEmpty)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4E8CC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF14161C), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    line,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2A2116),
                    ),
                  ),
                  Text(
                    tapHint,
                    style: const TextStyle(
                      color: Color(0xFF7A6A50),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
