// chat_screen.dart atualizado com indicador de nível (coração animado)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:janio_ai_roleplay/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String personagem;
  final String modo;
  final String estado;

  const ChatScreen({
    Key? key,
    required this.personagem,
    required this.modo,
    required this.estado,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ApiService apiService = ApiService();
  final List<Map<String, String>> mensagens = [];
  int contador = 0;
  int nivel = 0;
  String imagemFundoAtual = "";
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    carregarMensagens();
    carregarImagemFundo();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void carregarImagemFundo() {
    int indice = (contador ~/ 10) + 1;
    setState(() {
      imagemFundoAtual =
          'https://raw.githubusercontent.com/welnecker/roleplay_imagens/main/${widget.personagem}_fundo$indice.jpeg';
    });
  }

  Future<void> carregarMensagens() async {
    final msgs = await apiService.getMensagens(widget.personagem);
    setState(() {
      mensagens.addAll(msgs);
      contador = mensagens.where((m) => m['role'] == 'user').length;
      nivel = contador ~/ 5;
      carregarImagemFundo();
    });
  }

  Future<void> enviarMensagem(String texto) async {
    if (texto.trim().isEmpty) return;
    setState(() {
      mensagens.add({'role': 'user', 'content': texto});
      _controller.clear();
    });

    final resposta = await apiService.sendMessage(
      mensagem: texto,
      modo: widget.modo,
      personagem: widget.personagem,
      estado: widget.estado,
    );

    setState(() {
      mensagens.add({'role': 'assistant', 'content': resposta['resposta']});
      contador += 1;
      int novoNivel = resposta['nivel'] ?? (contador ~/ 5);
      if (novoNivel > nivel) {
        _animController.forward(from: 0.0);
      }
      nivel = novoNivel;
      if (contador % 10 == 0) carregarImagemFundo();
    });
  }

  Widget _buildMessage(Map<String, String> msg) {
    final role = msg['role'];
    final content = msg['content'] ?? '';
    final isUser = role == 'user';
    final isSystem = role == 'system';

    final color = isSystem
        ? Colors.white.withOpacity(0.5)
        : isUser
            ? Colors.blue.withOpacity(0.4)
            : Colors.green.withOpacity(0.4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        content,
        style: GoogleFonts.roboto(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.personagem),
        backgroundColor: Colors.black.withOpacity(0.2),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.pinkAccent, size: 28),
                  Positioned(
                    top: 2,
                    right: 0,
                    child: Text(
                      nivel.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: "Ver imagem de fundo",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => Scaffold(
                    backgroundColor: Colors.black,
                    body: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: InteractiveViewer(
                          child: Image.network(
                            imagemFundoAtual,
                            fit: BoxFit.contain,
                            errorBuilder: (context, _, __) => const Text(
                              'Erro ao carregar imagem',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Fundo sem blur
          Positioned.fill(
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/placeholder.jpg',
              image: imagemFundoAtual,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 500),
              imageErrorBuilder: (_, __, ___) =>
                  Container(color: Colors.black12),
            ),
          ),

          // Mensagens e input
          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: mensagens.length,
                  itemBuilder: (_, i) => _buildMessage(mensagens[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: "Digite sua mensagem...",
                          filled: true,
                          fillColor: Colors.white70,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => enviarMensagem(_controller.text),
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
