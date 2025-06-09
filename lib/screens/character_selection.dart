import 'package:flutter/material.dart';
import 'chat_screen.dart';

class CharacterSelectionScreen extends StatelessWidget {
  const CharacterSelectionScreen({super.key});

  final List<Map<String, String>> characters = const [
    {
      "name": "Aria",
      "desc": "Misteriosa e dominante",
      "avatar": "assets/aria.png"
    },
    {
      "name": "Luna",
      "desc": "Carinhosa e doce",
      "avatar": "assets/luna.png"
    },
    {
      "name": "Maya",
      "desc": "Sedutora e brincalhona",
      "avatar": "assets/maya.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escolha seu personagem')),
      body: ListView.builder(
        itemCount: characters.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: Image.asset(characters[index]['avatar']!, width: 50),
              title: Text(characters[index]['name']!),
              subtitle: Text(characters[index]['desc']!),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(character: characters[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
