import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultCharacter = {
  "name": "Jennifer",
  "description": "Uma mulher frustrada, sensual, intensa e protetora. Desperta de madrugada e encontra você acordado.",
  "avatar": "https://cdn-icons-png.flaticon.com/512/2922/2922561.png"  // ou altere para um avatar customizado
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
          child: const Text(" Jennifer"),
        ),
      ),
    );
  }
}
