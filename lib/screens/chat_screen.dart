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

  int _score = 5; // nota padrão

  final List<String> _modos = ["cotidiano", "sexy"];
  String _modoSelecionado = "cotidiano";

  final List<String> _modelos = ["gpt", "lmstudio"];
  String _modeloSelecionado = "gpt";

  @override
  void initState() {
    super.initState();
    _loadIntro();
  }

  void _loadIntro() async {
    try {
      final result = await apiService.getIntro(widget.character['name'] ?? 'Janio');
      setState(() {
        messages.add({"role": "system", "content": result['resumo'] ?? ''});
        introShown = true;
      });
    } catch (e) {
      debugPrint("Erro ao carregar introdução: $e");
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || isLoading) return;

    setState(() {
      messages.add({"role": "user", "content": text});
      isLoading = true;
      _controller.clear();
    });

    try {
      // Agora enviando o modelo escolhido também!
      final result = await apiService.sendMessage(
        text, _score, _modoSelecionado, _modeloSelecionado
      );
      setState(() {
        messages.add({"role": "assistant", "content": result["response"] ?? ''});
        isLoading = false;
        _score = result["new_score"] ?? 5;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Erro ao enviar mensagem: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Text(widget.character['name'] ?? "Chat"),
  actions: [
    IconButton(
      icon: const Icon(Icons.home),
      tooltip: "Voltar ao início",
      onPressed: () {
        Navigator.pop(context);
      },
    ),
    // Este bloco impede o overflow:
    Container(
      margin: const EdgeInsets.only(right: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text("Nota: "),
            DropdownButton<int>(
              value: _score,
              underline: Container(),
              onChanged: (value) {
                if (value != null) setState(() => _score = value);
              },
              items: List.generate(
                11,
                (i) => DropdownMenuItem(value: i, child: Text(i.toString())),
              ),
            ),
            const SizedBox(width: 20),
            const Text("Modo: "),
            DropdownButton<String>(
              value: _modoSelecionado,
              underline: Container(),
              onChanged: (value) {
                if (value != null) setState(() => _modoSelecionado = value);
              },
              items: _modos.map((modo) => DropdownMenuItem(
                value: modo,
                child: Text(
                  modo[0].toUpperCase() + modo.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    ),
  ],
),

      body: Column(
        children: [
          Expanded(
  child: ListView.builder(
    controller: _scrollController,
    itemCount: messages.length,
    itemBuilder: (_, index) {
      final msg = messages[index];
      final role = msg['role'];
      final isUser = role == 'user';
      final isSystem = role == 'system';
      final isJennifer = role == 'assistant';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Align(
          alignment: isSystem
              ? Alignment.center
              : isUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: isSystem
                  ? Colors.grey[300]
                  : isUser
                      ? Colors.purple[100]
                      : Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(
              isJennifer ? "Jennifer: ${msg['content']}" : msg['content'] ?? '',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      );
    },
  ),
),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Digite sua mensagem...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(_controller.text),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
