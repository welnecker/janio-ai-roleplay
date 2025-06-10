import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const RoleplayApp());
}

class RoleplayApp extends StatelessWidget {
  const RoleplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IA Roleplay',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
