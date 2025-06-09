import 'package:flutter/material.dart';
import 'screens/character_selection.dart';

void main() {
  runApp(const RoleplayApp());
}

class RoleplayApp extends StatelessWidget {
  const RoleplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Janio AI Roleplay',
      theme: ThemeData.dark(),
      home: const CharacterSelectionScreen(),
    );
  }
}
