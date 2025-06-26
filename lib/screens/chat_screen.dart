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

  int _score = 5; // nota padrão

  @override
  void initState() {
    super.initState();
    _loadIntro();
  }

  void _loadIntro() async {
    try {
      final intro = await apiService.sendMessage(
        mensagem: "início",
        score: _score,
        modo: "romântico",
        personagem: widget.character['nome']!,
        primeiraInteracao: true,
      );

      if (intro['introducao'] != null && intro['introducao'].toString().trim().isNotEmpty) {
        setState(() {
          messages.add({"role": "system", "content": intro['introducao']});
          introShown = true;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar introdução: $e");
    }
  }

  void _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": input});
      isLoading = true;
    });
    _controller.clear();

    try {
      final resposta = await apiService.sendMessage(
        mensagem: input,
        score: _score,
        modo: "romântico",
        personagem: widget.character['nome']!,
        primeiraInteracao: false,
      );

      setState(() {
        messages.add({"role": "assistant", "content": resposta['response'] ?? "[Erro na resposta]"});
        isLoading = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    } catch (e) {
      debugPrint("Erro ao enviar mensagem: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.character['nome'] ?? "Personagem")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                return ListTile(
                  title: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg['content'] ?? ""),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Digite sua mensagem..."),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
