import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, String> character;

  const ChatScreen({super.key, required this.character});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> messages = [];
  bool isLoading = false;
  bool introShown = false;
  int _score = 5;

  @override
  void initState() {
    super.initState();
    _loadIntro(); // Carrega a introdução automaticamente
  }

  Future<void> _loadIntro() async {
    try {
      setState(() => isLoading = true);

      final result = await apiService.sendMessage(
        "",
        _score,
        "romântico",
        personagem: widget.character['nome'] ?? "Jennifer",
        primeiraInteracao: true,
      );

      if (result['introducao'] != null && result['introducao']!.isNotEmpty) {
        messages.add({
          "role": "assistant",
          "content": result['introducao']!,
        });
      }

      if (result['sinopse'] != null && result['sinopse']!.isNotEmpty) {
        messages.add({
          "role": "system",
          "content": result['sinopse']!,
        });
      }

      if (result['response'] != null && result['response']!.isNotEmpty) {
        messages.add({
          "role": "assistant",
          "content": result['response']!,
        });
      }

      setState(() {
        introShown = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Erro ao carregar introdução: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": _controller.text});
      isLoading = true;
    });

    final result = await apiService.sendMessage(
      _controller.text,
      _score,
      "romântico",
      personagem: widget.character['nome'] ?? "Jennifer",
      primeiraInteracao: false,
    );

    if (result['response'] != null) {
      setState(() {
        messages.add({"role": "assistant", "content": result['response']!});
      });
    }

    _controller.clear();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.character['nome'] ?? "Personagem";

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat com $nome"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == "user";
                return ListTile(
                  title: Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.blueAccent.withOpacity(0.7)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['content'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: "Digite sua mensagem"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
