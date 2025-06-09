import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, String> character;
  const ChatScreen({super.key, required this.character});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<String> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ApiService apiService = ApiService();
  int score = 0;
  String emotionalState = "Distante";

  void sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add("Você: $text");
    });

    try {
      var response = await apiService.sendMessage(text, score);
      setState(() {
        messages.add("${widget.character['name']}: ${response['response']}");
        score = response['new_score'];
        emotionalState = response['state'];
      });
    } catch (e) {
      setState(() {
        messages.add("${widget.character['name']}: [Erro na IA: ${e.toString()}]");
      });
    }

    _controller.clear();
  }

  Widget buildQuickAction(String label) {
    return ElevatedButton(
      onPressed: () {
        _controller.text = label;
        sendMessage();
      },
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.character['name']} • Estado: $emotionalState"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: messages.map((msg) => ListTile(title: Text(msg))).toList(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildQuickAction("Elogiar"),
                buildQuickAction("Flertar"),
                buildQuickAction("Seduzir"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Digite sua mensagem..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
