import 'package:flutter/material.dart';
import 'package:janio_ai_roleplay/screens/chat_screen.dart';
import 'package:janio_ai_roleplay/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  String personagemSelecionado = '';
  List<Map<String, dynamic>> personagens = [];
  String plataformaSelecionada = 'openai'; // Default

  @override
  void initState() {
    super.initState();
    carregarPersonagens();
  }

  Future<void> carregarPersonagens() async {
    final lista = await apiService.getPersonagens();
    setState(() {
      personagens = lista;
    });
  }

  void abrirChat(String personagem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          personagem: personagem,
          plataforma: plataformaSelecionada, // ← Envia plataforma selecionada
        ),
      ),
    );
  }

  Widget _buildDropdownPlataforma() {
    return DropdownButton<String>(
      value: plataformaSelecionada,
      dropdownColor: Colors.black87,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      underline: const SizedBox(),
      items: [
        DropdownMenuItem(value: 'openai', child: Text('OpenAI', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'openrouter', child: Text('OpenRouter', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'local', child: Text('Local', style: TextStyle(color: Colors.white))),
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
      appBar: AppBar(
        title: const Text("Escolha o personagem"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildDropdownPlataforma(),
          ),
        ],
      ),
      body: personagens.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: personagens.length,
              itemBuilder: (_, i) {
                final p = personagens[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(p['foto']),
                    backgroundColor: Colors.grey.shade300,
                  ),
                  title: Text(p['nome']),
                  subtitle: Text(p['descricao'] ?? ''),
                  onTap: () => abrirChat(p['nome']),
                );
              },
            ),
    );
  }
}
