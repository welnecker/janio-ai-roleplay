import 'package:flutter/material.dart';
import 'package:janio_ai_roleplay/screens/home_screen.dart';

void main() {
  runApp(const RoleplayApp());
}

class RoleplayApp extends StatelessWidget {
  const RoleplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Janio AI Roleplay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}