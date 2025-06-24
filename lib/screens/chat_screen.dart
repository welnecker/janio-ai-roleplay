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
  String introResumo = "";

  @override
  void initState() {
    super.initState();
    carregarIntro();
  }

  Future<void> carregarIntro() async {
    final result = await apiService.getIntro(
      nome: "Janio",
      personagem: widget.character["nome"],
    );
    setState(() {
      introResumo = result["resumo"];
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
      body: SafeArea(
  child: Column(
    children: [
      Expanded(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: messages.length + 1, // +1 para a sinopse
          itemBuilder: (context, index) {
            if (index == 0 && introResumo.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  introResumo,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.justify,
                ),
              );
            }

            final msg = messages[index - 1];
            final isUser = msg["role"] == "user";

            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUser ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isUser
                    ? Text(
                        msg["content"]!,
                        textAlign: TextAlign.left,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: msg["content"]!
                            .split('\n\n')
                            .map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    p.trim(),
                                    textAlign: TextAlign.justify,
                                    style: const TextStyle(height: 1.5),
                                  ),
                                ))
                            .toList(),
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
),
