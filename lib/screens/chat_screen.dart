import 'package:flutter/material.dart';
import 'package:janio_ai_roleplay/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String personagem;
  const ChatScreen({super.key, required this.personagem});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> mensagens = [];
  bool carregando = false;
  int fundoIndex = 1;
  int nivel = 0;
  int fillIndex = 0;

  String get imagemFundoUrl =>
      "https://raw.githubusercontent.com/welnecker/roleplay_imagens/main/${widget.personagem}_fundo$fundoIndex.jpeg";

  @override
  void initState() {
    super.initState();
    carregarMensagens();
  }

  Future<void> carregarMensagens() async {
    final lista = await apiService.getMensagens(widget.personagem);
    final intro = await apiService.getIntro(widget.personagem);
    setState(() {
      mensagens = [
        {"role": "system", "content": intro},
        ...lista.reversed
      ];
      fundoIndex = ((mensagens.where((m) => m['role'] == 'assistant').length) ~/ 10) + 1;
    });
  }

  Future<void> enviarMensagem() async {
    final texto = controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      mensagens.add({"role": "user", "content": texto});
      carregando = true;
      controller.clear();
    });

    final resposta = await apiService.sendMessage(
      mensagem: texto,
      personagem: widget.personagem,
    );

    setState(() {
      mensagens.add({"role": "assistant", "content": resposta['resposta']});
      fundoIndex = ((mensagens.where((m) => m['role'] == 'assistant').length) ~/ 10) + 1;
      nivel = resposta['nivel'] ?? 0;
      fillIndex = resposta['fill_index'] ?? 0;
      carregando = false;
    });
  }

  Future<void> regenerarResposta(String texto) async {
    setState(() {
      mensagens.removeLast();
      carregando = true;
    });

    final nova = await apiService.sendMessage(
      mensagem: texto,
      personagem: widget.personagem,
      regenerar: true,
    );

    setState(() {
      mensagens.add({
        "role": "assistant",
        "content": "${nova['resposta']} (regenerada)"
      });
      carregando = false;
    });
  }

  Widget _mensagemItem(int i) {
    final msg = mensagens[i];
    final role = msg['role'];
    final content = msg['content'];

    final isUltimaIA = role == 'assistant' &&
        i == mensagens.lastIndexWhere((m) => m['role'] == 'assistant');
    final userMsg = i > 0 ? mensagens[i - 1]['content'] : '';

    final alignment = role == 'user'
        ? Alignment.centerRight
        : role == 'system'
            ? Alignment.center
            : Alignment.centerLeft;

    final cor = role == 'user'
        ? Colors.blue.shade100
        : role == 'assistant'
            ? Colors.grey.shade200
            : Colors.orange.shade100;

    return Align(
      alignment: alignment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            if (isUltimaIA)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => regenerarResposta(userMsg),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Regenerar"),
                ),
              )
          ],
        ),
      ),
    );
  }

  void abrirImagemAtual() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(imagemFundoUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildNivelCoracoes() {
    return Row(
      children: [
        Text("$nivel.", style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        ...List.generate(5, (index) => Icon(
              index < fillIndex
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: Colors.pink,
              size: 18,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(widget.personagem)),
            _buildNivelCoracoes(),
          ],
        ),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Ver imagem atual',
            onPressed: abrirImagemAtual,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Ver introdução',
            onPressed: () async {
              final intro = await apiService.getIntro(widget.personagem);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Introdução"),
                  content: Text(intro),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Fechar"),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Image.network(
              imagemFundoUrl,
              key: ValueKey(fundoIndex),
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 16),
              Expanded(
                child: ListView.builder(
                  itemCount: mensagens.length,
                  itemBuilder: (_, i) => _mensagemItem(i),
                ),
              ),
              if (carregando)
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
                        controller: controller,
                        onSubmitted: (_) => enviarMensagem(),
                        decoration: const InputDecoration(
                          hintText: "Digite sua mensagem...",
                          filled: true,
                          fillColor: Colors.white70,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: enviarMensagem,
                      color: Colors.white,
                    )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
