import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> character;
  const ChatScreen({Key? key, required this.character}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> messages = [];
  String introResumo = '';

  @override
  void initState() {
    super.initState();
    _loadIntro();
    _loadPreviousMessages();
  }

  Future<void> _loadIntro() async {
    final resumo = await apiService.getIntro(widget.character["nome"]);
    if (resumo.isNotEmpty) {
      setState(() {
        introResumo = resumo;
        messages.insert(0, {
          "role": "system",
          "content": resumo,
        });
      });
    }
  }

  Future<void> _loadPreviousMessages() async {
    final previous = await apiService.getMensagens(widget.character["nome"]);
    if (previous.isNotEmpty) {
      setState(() {
        messages.insertAll(0, previous);
      });
    }
  }

  void _sendMessage(String mensagem) async {
    if (mensagem.trim().isEmpty) return;
    setState(() {
      messages.add({"role": "user", "content": mensagem});
    });
    _controller.clear();
    _scrollToBottom();

    final response = await apiService.sendMessage(
      mensagem: mensagem,
      personagem: widget.character["nome"],
    );

    if (response.containsKey("response")) {
      setState(() {
        messages.add({"role": "assistant", "content": response["response"]});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.character["nome"], style: GoogleFonts.roboto()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      message["content"] ?? '',
                      style: GoogleFonts.roboto(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
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
                    onSubmitted: _sendMessage,
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
