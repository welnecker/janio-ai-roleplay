import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  int _score = 5;
  String _modo = "romântico";
  bool _introCarregada = false;

  @override
  void initState() {
    super.initState();
    _carregarIntro();
  }

  Future<void> _carregarIntro() async {
    try {
      final intro = await apiService.sendMessage(
        mensagem: "",
        score: _score,
        modo: _modo,
        personagem: widget.character['nome'] ?? "",
        primeiraInteracao: true,
      );

      if (intro['introducao'] != null && intro['introducao'].toString().isNotEmpty) {
        setState(() {
          messages.add({"role": "assistant", "content": intro['introducao']});
          if (intro['sinopse'] != null && intro['sinopse'].toString().isNotEmpty) {
            messages.insert(0, {"role": "system", "content": intro['sinopse']});
          }
          _introCarregada = true;
        });
      }
    } catch (e) {
      print("Erro ao carregar introdução: $e");
    }
  }

  Future<void> _enviarMensagem() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      isLoading = true;
      messages.add({"role": "user", "content": _controller.text.trim()});
    });
    final userInput = _controller.text.trim();
    _controller.clear();

    try {
      final resposta = await apiService.sendMessage(
        mensagem: userInput,
        score: _score,
        modo: _modo,
        personagem: widget.character['nome'] ?? "",
      );
      setState(() {
        messages.add({"role": "assistant", "content": resposta['response']});
        isLoading = false;
      });
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 150,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() => isLoading = false);
      print("Erro ao enviar mensagem: $e");
    }
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    final isSystem = msg['role'] == 'system';
    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : isSystem
              ? Alignment.center
              : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue[100]
              : isSystem
                  ? Colors.grey[300]
                  : Colors.pink[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg['content'] ?? ""),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.character['nome'] ?? "Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Digite sua mensagem...",
                    ),
                    onSubmitted: (_) => _enviarMensagem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: isLoading ? null : _enviarMensagem,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
