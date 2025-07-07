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
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool isLoading = false;
  bool memoriaInicialColada = false;

  String modoSelecionado = 'Normal';
  String estadoSelecionado = 'Neutro';

  final List<String> modosFala = ['Normal', 'Sedutor', 'Engraçado', 'Agressivo', 'Reflexivo'];
  final List<String> estadosEmocionais = ['Neutro', 'Excitado', 'Triste', 'Confiante', 'Irritado'];

  @override
  void initState() {
    super.initState();
    _semeiaMemorias();
    _loadInitialMemory();
  }

  Future<void> _semeiaMemorias() async {
    await apiService.semeiaMemoriasPrincipais(widget.character["nome"]);
    await apiService.semeiaMemoriasFixas(widget.character["nome"]);
  }

  Future<void> _loadInitialMemory() async {
    final memoriaResp = await apiService.semeiaMemoriaInicial(widget.character["nome"]);
    final mensagemInicial = memoriaResp["mensagem_inicial"];

    if (mensagemInicial != null &&
        mensagemInicial.toString().trim().isNotEmpty &&
        !memoriaInicialColada) {
      messages.add({"role": "assistant", "content": mensagemInicial});
      memoriaInicialColada = true;
    }

    final previous = await apiService.getMensagens(widget.character["nome"]);
    setState(() {
      messages.addAll(previous.map<Map<String, String>>((msg) => {
            "role": msg["role"] ?? 'assistant',
            "content": msg["content"] ?? ''
          }));
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage({bool regenerar = false}) async {
    String userText;

    if (regenerar) {
      final lastUser = messages.lastWhere((m) => m["role"] == "user", orElse: () => {});
      userText = lastUser["content"] ?? '';
      if (userText.isEmpty) return;

      setState(() => isLoading = true);

      final response = await apiService.sendMessage(
        mensagem: userText,
        personagem: widget.character["nome"],
        regenerar: true,
        modo: modoSelecionado,
        estado: estadoSelecionado,
      );

      final aiText = response['resposta'] ?? 'Erro na resposta';
      setState(() {
        messages.removeLast();
        messages.add({"role": "assistant", "content": aiText});
        isLoading = false;
        _scrollToBottom();
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
        modo: modoSelecionado,
        estado: estadoSelecionado,
      );

      final aiText = response['resposta'] ?? 'Erro na resposta';
      setState(() {
        messages.add({"role": "assistant", "content": aiText});
        isLoading = false;
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
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
                memoriaInicialColada = false;
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
                  memoriaInicialColada = false;
                });
                await _loadInitialMemory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: modoSelecionado,
                    items: modosFala.map((value) {
                      return DropdownMenuItem(value: value, child: Text("Modo: $value"));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => modoSelecionado = value!);
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButton<String>(
                    value: estadoSelecionado,
                    items: estadosEmocionais.map((value) {
                      return DropdownMenuItem(value: value, child: Text("Estado: $value"));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => estadoSelecionado = value!);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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
