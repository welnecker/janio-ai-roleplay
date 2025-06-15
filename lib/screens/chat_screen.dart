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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    carregarIntroducao(); // chamada inicial
  }

  Future<void> carregarIntroducao() async {
    try {
      final intro = await apiService.getIntro();
      setState(() {
        messages.add("${widget.character['name']}: ${intro['response']}");
        score = intro['new_score'];
        emotionalState = intro['state'];
      });
    } catch (e) {
      setState(() {
        messages.add("${widget.character['name']}: [Erro ao carregar intro: ${e.toString()}]");
      });
    }
  }

  void sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add("Você: $text");
      isLoading = true;
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
        messages.add("${widget.character['name']}: [Erro: ${e.toString()}]");
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }

    _controller.clear();
  }

  Widget buildQuickAction(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          _controller.text = label;
          sendMessage();
        },
        child: Text(label),
      ),
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
    padding: const EdgeInsets.all(8.0),
    children: messages.map((msg) {
      final partes = msg.split('\n\n'); // separa parágrafos duplos

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: msg.startsWith("Você:") ? Colors.grey[200] : Colors.purple[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: partes.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(p.trim()),
          )).toList(),
        ),
      );
    }).toList(),
  ),
),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("⏳ Pensando..."),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                    decoration: const InputDecoration(
                      hintText: "Digite sua mensagem...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
