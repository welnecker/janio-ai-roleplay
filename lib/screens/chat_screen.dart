import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> character;

  const ChatScreen({super.key, required this.character});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> messages = [];
  bool loading = false;
  bool primeiraInteracao = true;

  @override
  void initState() {
    super.initState();
    iniciarConversa();
  }

  Future<void> iniciarConversa() async {
    setState(() => loading = true);

    final response = await apiService.sendMessage(
      mensagem: "Iniciar conversa",
      score: 5,
      modo: "romântico",
      personagem: widget.character["nome"],
      primeiraInteracao: true,
    );

    if (response["sinopse"] != null && response["sinopse"].toString().isNotEmpty) {
      messages.add({"role": "narrador", "content": response["sinopse"]});
    }

    setState(() {
      loading = false;
      primeiraInteracao = false;
    });
  }

  Future<void> enviarMensagem() async {
    final mensagem = _controller.text.trim();
    if (mensagem.isEmpty) return;

    setState(() {
      loading = true;
      messages.add({"role": "user", "content": mensagem});
      _controller.clear();
    });

    final response = await apiService.sendMessage(
      mensagem: mensagem,
      score: 5,
      modo: "romântico",
      personagem: widget.character["nome"],
      primeiraInteracao: false,
    );

    setState(() {
      messages.add({"role": "assistant", "content": response["response"]});
      loading = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.character["nome"]),
            Text(
              widget.character["descricao"],
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";
                final isIA = msg["role"] == "assistant";
                final isNarrador = msg["role"] == "narrador";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : isNarrador
                          ? Alignment.center
                          : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue[100]
                          : isNarrador
                              ? Colors.amber[50]
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["content"]!,
                      style: TextStyle(
                        fontStyle: isNarrador ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Digite sua mensagem...",
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: loading ? null : enviarMensagem,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
