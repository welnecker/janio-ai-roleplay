import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> character;

  const ChatScreen({super.key, required this.character});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiService apiService = ApiService();
  final List<Map<String, String>> messages = [];
  bool carregando = false;
  String introResumo = "";

  @override
  void initState() {
    super.initState();
    carregarIntro(); // ✅ Carrega apenas o resumo da introdução
  }

  Future<void> carregarIntro() async {
    final result = await apiService.getIntro(
      nome: "Janio",
      personagem: widget.character["nome"],
    );
    setState(() {
      introResumo = result["resumo"] ?? "";
      if (introResumo.isNotEmpty) {
        messages.insert(0, {
          "role": "system",
          "content": introResumo,
        });
      }
    });
  }

  Future<void> enviarMensagem() async {
    final mensagem = _controller.text.trim();
    if (mensagem.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": mensagem});
      carregando = true;
    });

    _controller.clear();

    final response = await apiService.sendMessage(
      mensagem: mensagem,
      score: 5,
      modo: "romântico",
      personagem: widget.character["nome"],
    );

    setState(() {
      messages.add({"role": "assistant", "content": response["response"] ?? ""});
      carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.character["nome"]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.purple[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg["content"] ?? ""),
                  ),
                );
              },
            ),
          ),
          if (carregando)
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
                    decoration: const InputDecoration(
                      hintText: "Digite sua mensagem...",
                    ),
                    onSubmitted: (_) => enviarMensagem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
