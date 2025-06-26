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

  int _score = 5; // nota inicial
  bool _primeiraInteracao = true;

  @override
  void initState() {
    super.initState();
    _carregarIntro();
  }

  Future<void> _carregarIntro() async {
    try {
      final intro = await apiService.getIntro(
        nome: "Donisete",
        personagem: widget.character['nome'] ?? "",
      );

      if (intro['resumo'] != null && intro['resumo'].toString().trim().isNotEmpty) {
        // Sinopse (há histórico)
        setState(() {
          messages.add({
            "role": "system",
            "content": intro['resumo'],
          });
          _primeiraInteracao = false;
        });
      } else {
        // Sem histórico: mostrar introdução
        final introducao = widget.character['introducao'] ?? "";
        if (introducao.trim().isNotEmpty) {
          setState(() {
            messages.add({
              "role": "system",
              "content": introducao,
            });
            _primeiraInteracao = true;
          });
        }
      }
    } catch (e) {
      print("Erro ao carregar introdução/sinopse: $e");
    }
  }

  void _enviarMensagem() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": texto});
      isLoading = true;
    });

    _controller.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    try {
      final resposta = await apiService.sendMessage(
        mensagem: texto,
        score: _score,
        modo: "romântico",
        personagem: widget.character['nome'] ?? "",
        primeiraInteracao: _primeiraInteracao,
      );

      setState(() {
        if (resposta['introducao'] != null && resposta['introducao'].toString().isNotEmpty && _primeiraInteracao) {
          messages.add({
            "role": "system",
            "content": resposta['introducao'],
          });
        }

        messages.add({
          "role": "assistant",
          "content": resposta['response'] ?? "Sem resposta",
        });
        isLoading = false;
        _primeiraInteracao = false;
      });
    } catch (e) {
      print("Erro ao enviar mensagem: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildMensagem(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg['content'] ?? ''),
      ),
    );
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
                return _buildMensagem(messages[index]);
              },
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Digite sua mensagem..."),
                    onSubmitted: (_) => _enviarMensagem(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
