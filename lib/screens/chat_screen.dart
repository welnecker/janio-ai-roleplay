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
  final ApiService apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> messages = [];
  bool isLoading = false;
  int _score = 5;
  String _modo = "romântico";
  bool _introShown = false;

  @override
  void initState() {
    super.initState();
    _loadIntro();
  }

  void _loadIntro() async {
    final personagem = widget.character['nome'] ?? "";
    final nomeUsuario = "Janio";

    try {
      final intro = await apiService.sendMessage(
        mensagem: "",
        score: _score,
        modo: _modo,
        personagem: personagem,
        primeiraInteracao: true,
      );

      final introTexto = intro['introducao'] ?? "";
      final sinopseTexto = intro['sinopse'] ?? "";

      if (sinopseTexto.isNotEmpty) {
        messages.add({"role": "system", "content": sinopseTexto});
      }
      if (introTexto.isNotEmpty) {
        messages.add({"role": "assistant", "content": introTexto});
      }

      setState(() => _introShown = true);
    } catch (e) {
      debugPrint("Erro ao carregar introdução: $e");
    }
  }

  void _sendMessage(String texto) async {
    if (texto.trim().isEmpty) return;

    final personagem = widget.character['nome'] ?? "";

    setState(() {
      isLoading = true;
      messages.add({"role": "user", "content": texto});
      _controller.clear();
    });

    try {
      final resposta = await apiService.sendMessage(
        mensagem: texto,
        score: _score,
        modo: _modo,
        personagem: personagem,
        primeiraInteracao: false,
      );

      setState(() {
        messages.add({"role": "assistant", "content": resposta['response'] ?? ""});
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
      appBar: AppBar(title: Text(widget.character['nome'])),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['content'] ?? ""),
                  ),
                );
              },
            ),
          ),
          if (isLoading) const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(hintText: "Digite sua mensagem..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
