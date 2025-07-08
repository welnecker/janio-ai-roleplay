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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escolha o personagem")),
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
