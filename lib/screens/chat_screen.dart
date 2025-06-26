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
  bool primeiraInteracao = true; // ✅ controla se deve exibir introdução

  @override
  void initState() {
    super.initState();
    carregarIntro();
  }

  /// Carrega o resumo das últimas interações (sinopse)
  Future<void> carregarIntro() async {
    try {
      final result = await apiService.getIntro(
        nome: "Janio",
        personagem: widget.character["nome"],
      );
      print("Resumo recebido: ${result['resumo']}");

      final resumo = result["resumo"]?.trim() ?? "";

      if (resumo.isNotEmpty) {
        setState(() {
          introResumo = resumo;
          // ✅ sinopse adicionada como primeira mensagem
          messages.add({"role": "assistant", "content": introResumo});
          primeiraInteracao = false; // ✅ ignora introdução se já teve resumo
        });
      }
    } catch (e) {
      print("Erro ao carregar resumo: $e");
    }
  }

  /// Envia mensagem e trata introdução
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
      primeiraInteracao: primeiraInteracao,
    );

    // ✅ Exibe introdução se for a primeira interação e NÃO houve sinopse
    if (primeiraInteracao &&
        introResumo.isEmpty &&
        (response["introducao"] ?? "").toString().isNotEmpty) {
      print("🟡 Exibindo introdução...");
      setState(() {
        messages.add({"role": "assistant", "content": response["introducao"]});
      });
    }

    setState(() {
      messages.add({"role": "assistant", "content": response["response"]});
      loading = false;
      primeiraInteracao = false; // ✅ impede novas introduções
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Estilo personalizado para falas, pensamentos e narração
  List<TextSpan> _formatarResumo(String texto) {
    return texto.split('\n').map((linha) {
      final trimmed = linha.trim();
      final isThought = trimmed.startsWith("*") && trimmed.endsWith("*");
      final isSpeech = trimmed.startsWith('"') && trimmed.endsWith('"');
      return TextSpan(
        text: linha + '\n',
        style: TextStyle(
          fontStyle: isThought ? FontStyle.italic : FontStyle.normal,
          color: isSpeech
              ? Colors.purple[300]
              : Colors.white.withOpacity(isThought ? 0.85 : 1),
        ),
      );
    }).toList();
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";

                // ✅ Exibe a sinopse como primeira mensagem se disponível
                final isResumo = msg["content"] == introResumo && index == 0;

                if (isResumo) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14),
                        children: _formatarResumo(introResumo),
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg["content"] ?? ""),
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
                  onSubmitted: (_) => enviarMensagem(),
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
    );
  }
}
