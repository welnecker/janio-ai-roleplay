import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultCharacter = {
      "name": "Dina",
      "description": "Uma jovem mulher carismática, misteriosa e sedutora.",
      "avatar":
          "https://cdn-icons-png.flaticon.com/512/2922/2922561.png" // opcional
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Escolha um personagem"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(character: defaultCharacter),
              ),
            );
          },
          child: const Text("Iniciar conversa com Dina"),
        ),
      ),
    );
  }
}
