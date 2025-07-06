import 'package:flutter/material.dart';
import 'package:janio_ai_roleplay/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> character;
  const ChatScreen({super.key, required this.character});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  Map<String, String>? introMessage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _semeiaMemorias(); // ⬅️ Memórias principais e fixas semeadas automaticamente
    _loadInitialMemory();
  }

  Future<void> _semeiaMemorias() async {
    await apiService.semeiaMemoriasPrincipais(widget.character["nome"]);
    await apiService.semeiaMemoriasFixas(widget.character["nome"]);
  }

  Future<void> _loadInitialMemory() async {
    final introText = await apiService.getResumo(widget.character["nome"]);
    if (introText.isNotEmpty) {
      introMessage = {"role": "system", "content": introText};
      messages.add(introMessage!);
    }

    final previous = await apiService.getMensagens(widget.character["nome"]);
    setState(() {
      messages.addAll(previous.map<Map<String, String>>((msg) => {
        "role": msg["role"] ?? 'assistant',
        "content": msg["content"] ?? ''
      }).toList());
    });
  }

  Future<void> _sendMessage({bool regenerar = false}) async {
    String userText;

    if (regenerar) {
      final lastUser = messages.lastWhere((m) => m["role"] == "user", orElse: () => {});
      userText = lastUser["content"] ?? '';
      if (userText.isEmpty) return;

      setState(() {
        isLoading = true;
      });

      final response = await apiService.sendMessage(
        mensagem: userText,
        personagem: widget.character["nome"],
        regenerar: true,
      );

      final aiText = response['resposta'] ?? 'Erro na resposta';
      setState(() {
        messages.removeLast(); // remove última resposta da IA
        messages.add({"role": "assistant", "content": aiText});
        isLoading = false;
      });

    } else {
      userText = _controller.text;
      if (userText.isEmpty) return;
      _controller.clear();
      setState(() {
        messages.add({"role": "user", "content": userText});
        isLoading = true;
      });

      final response = await apiService.sendMessage(
        mensagem: userText,
        personagem: widget.character["nome"],
      );

      final aiText = response['resposta'] ?? 'Erro na resposta';
      setState(() {
        messages.add({"role": "assistant", "content": aiText});
        isLoading = false;
      });
    }
  }

  Widget _buildMessage(Map<String, String> message, int index) {
    final isUser = message["role"] == "user";
    final isSystem = message["role"] == "system";
    final isLastAssistant = message["role"] == "assistant" &&
        index == messages.lastIndexWhere((m) => m["role"] == "assistant");

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isSystem
        ? Colors.grey[300]
        : isUser
            ? Colors.blue[100]
            : Colors.green[100];

    return Align(
      alignment: alignment,
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(message["content"] ?? ''),
            ),
          ),
          if (isLastAssistant)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Regenerar resposta",
              onPressed: () => _sendMessage(regenerar: true),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.character["nome"]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Recarregar histórico",
            onPressed: () async {
              setState(() {
                messages.clear();
              });
              await _loadInitialMemory();
            },
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: "Resetar memórias",
            onPressed: () async {
              final result = await apiService.resetMemorias(widget.character["nome"]);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result)),
                );
                setState(() {
                  messages.clear();
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index], index);
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
                    decoration: const InputDecoration(
                      hintText: "Digite sua mensagem...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
