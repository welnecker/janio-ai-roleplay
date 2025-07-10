import 'package:flutter/material.dart';
import 'package:janio_ai_roleplay/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String personagem;
  final String plataforma; // NOVO
  const ChatScreen({
    super.key,
    required this.personagem,
    this.plataforma = "openai", // Valor padrão
  });

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
  late String plataformaSelecionada;
  bool traduzirAtivo = true; // NOVO

  String get imagemFundoUrl =>
      "https://raw.githubusercontent.com/welnecker/roleplay_imagens/main/${widget.personagem}_fundo$fundoIndex.jpeg";

  @override
  void initState() {
    super.initState();
    plataformaSelecionada = widget.plataforma; // recebe da tela anterior
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
      plataforma: plataformaSelecionada,
      traduzir: traduzirAtivo,
    );

    setState(() {
      mensagens.add({"role": "assistant", "content": resposta['resposta']});
      fundoIndex = ((mensagens.where((m) => m['role'] == 'assistant').length) ~/ 10) + 1;
      nivel = int.tryParse(resposta['nivel'].toString()) ?? 0;
      fillIndex = int.tryParse(resposta['fill_index'].toString()) ?? (nivel % 5);
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
      plataforma: plataformaSelecionada,
      traduzir: traduzirAtivo,
    );

    setState(() {
      mensagens.add({
        "role": "assistant",
        "content": "${nova['resposta']} (regenerada)"
      });
      carregando = false;
    });
  }

  Future<void> limparMemorias() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmação"),
        content: Text("Deseja realmente apagar as memórias e histórico de ${widget.personagem}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Apagar")),
        ],
      ),
    );

    if (confirm == true) {
      final resultado = await apiService.resetMemorias(widget.personagem);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultado)));
        carregarMensagens();
      }
    }
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
    return Tooltip(
      message: "Nível de afinidade com ${widget.personagem}",
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Nível $nivel",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          const SizedBox(width: 6),
          ...List.generate(5, (index) => Icon(
                index < fillIndex ? Icons.favorite : Icons.favorite_border,
                color: index < fillIndex ? Colors.pinkAccent : Colors.grey.shade400,
                size: 18,
              )),
        ],
      ),
    );
  }

  Widget _buildPlataformaSelector() {
    return DropdownButton<String>(
      value: plataformaSelecionada,
      dropdownColor: Colors.black87,
      underline: const SizedBox(),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      items: [
        DropdownMenuItem(value: "openai", child: Text("OpenAI", style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: "openrouter", child: Text("OpenRouter", style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: "local", child: Text("Local", style: TextStyle(color: Colors.white))),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            plataformaSelecionada = value;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.personagem, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            _buildNivelCoracoes(),
          ],
        ),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(traduzirAtivo ? Icons.translate : Icons.g_translate),
            tooltip: traduzirAtivo ? 'Tradução ativada' : 'Tradução desativada',
            onPressed: () {
              setState(() {
                traduzirAtivo = !traduzirAtivo;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(traduzirAtivo ? "Tradução ativada" : "Tradução desativada")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Apagar memórias e histórico',
            onPressed: limparMemorias,
          ),
          _buildPlataformaSelector(),
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
