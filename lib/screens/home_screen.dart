import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'jennifer_cover_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool started = false;

  final defaultCharacter = {
    "name": "Jennifer",
    "description": "Uma mulher frustrada, sensual, intensa e protetora. Desperta de madrugada e encontra você acordado.",
    "avatar": "https://cdn-icons-png.flaticon.com/512/2922/2922561.png",
  };

  @override
  Widget build(BuildContext context) {
    return started
        ? ChatScreen(character: defaultCharacter)
        : JenniferCoverScreen(
            onStart: () {
              setState(() => started = true);
            },
          );
  }
}
