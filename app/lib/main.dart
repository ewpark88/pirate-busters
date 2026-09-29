import 'package:flutter/material.dart';

void main() {
  runApp(const PirateBustersApp());
}

/// 앱 루트. M4 에서 Flame 전장으로 바꾼다.
class PirateBustersApp extends StatelessWidget {
  const PirateBustersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pirate Busters',
      home: Scaffold(body: Center(child: Text('Pirate Busters'))),
    );
  }
}
