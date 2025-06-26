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
  String _modoSelecionado = "romântico";

  @override
  void initState() {
    super.initState();
    _loadIntro();
  }

  void _loadIntro() async {
    setState(() => isLoading = true);
    try {
      final intro = await apiService.sendMessage(
        mensagem: "[INICIO]",
        score: _score,
        modo: _modoSelecionado,
        personagem: widget.character['nome'] ?? "",
        primeiraInteracao: true,
      );

      if (intro['introducao'] != null && intro['introducao'].toString().isNotEmpty) {
        messages.add({"role": "assistant", "content": intro['introducao']});
      }

      if (intro['sinopse'] != null && intro['sinopse'].toString().isNotEmpty) {
        messages.insert(0, {"role": "system", "content": intro['sinopse']});
      }

    } catch (e) {
      debugPrint("Erro ao carregar introdução: $e");
    } finally {
      setState(() {
        isLoading = false;
        introShown = true;
      });
    }
  }

  void _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": userMessage});
      isLoading = true;
      _controller.clear();
    });

    try {
      final resposta = await apiService.sendMessage(
        mensagem: userMessage,
        score: _score,
        modo: _modoSelecionado,
        personagem: widget.character['nome'] ?? "",
      );

      if (resposta['response'] != null) {
        setState(() {
          messages.add({"role": "assistant", "content": resposta['response']});
        });
      }
    } catch (e) {
      debugPrint("Erro ao enviar mensagem: $e");
    } finally {
      setState(() => isLoading = false);
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.character['nome'] ?? "Personagem"),
      ),
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
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(msg['content'] ?? ""),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Digite sua mensagem..."),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
