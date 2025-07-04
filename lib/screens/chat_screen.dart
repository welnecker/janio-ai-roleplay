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
    _loadInitialMemory();
  }

  Future<void> _loadInitialMemory() async {
    final introText = await apiService.getIntro(widget.character["nome"]);
    if (introText.isNotEmpty) {
      introMessage = {"role": "system", "content": introText};
      messages.add(introMessage!);
    }

    final previous = await apiService.getMensagens(widget.character["nome"]);
    setState(() {
      messages.addAll(previous.map((msg) => {
        "role": msg["role"] ?? 'assistant',
        "content": msg["content"] ?? ''
      }));
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    _controller.clear();
    setState(() {
      messages.add({"role": "user", "content": text});
      isLoading = true;
    });

    final response = await apiService.sendMessage(
      mensagem: text,
      personagem: widget.character["nome"],
    );

    final aiText = response['resposta'] ?? 'Erro na resposta';
    setState(() {
      messages.add({"role": "assistant", "content": aiText});
      isLoading = false;
    });
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message["role"] == "user";
    final isSystem = message["role"] == "system";
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isSystem
        ? Colors.grey[300]
        : isUser
            ? Colors.blue[100]
            : Colors.green[100];

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message["content"] ?? ''),
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
            onPressed: () async {
              setState(() {
                messages.clear();
              });
              await _loadInitialMemory();
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
