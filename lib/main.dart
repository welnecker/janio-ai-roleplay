import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Certifique-se que o arquivo está em lib/screens/

void main() {
  runApp(const RoleplayApp());
}

class RoleplayApp extends StatelessWidget {
  const RoleplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Janio AI Roleplay',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
