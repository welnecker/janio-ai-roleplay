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
  String modoSelecionado = 'Normal';
  String estadoSelecionado = 'Neutro';
  String personagemSelecionado = '';
  List<Map<String, dynamic>> personagens = [];

  final List<String> modos = ['Normal', 'Romântico', 'Atrevido', 'Misterioso'];
  final List<String> estados = ['Neutro', 'Feliz', 'Triste', 'Raivoso', 'Excitado'];

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
          modo: modoSelecionado,
          estado: estadoSelecionado,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escolha o personagem")),
      body: Column(
        children: [
          // Menus suspensos
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Modo
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: modoSelecionado,
                    items: modos.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => modoSelecionado = value);
                    },
                    decoration: const InputDecoration(labelText: "Modo"),
                  ),
                ),
                const SizedBox(width: 8),
                // Estado
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: estadoSelecionado,
                    items: estados.map((e) {
                      return DropdownMenuItem(value: e, child: Text(e));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => estadoSelecionado = value);
                    },
                    decoration: const InputDecoration(labelText: "Estado"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Lista de personagens
          Expanded(
            child: personagens.isEmpty
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
          ),
        ],
      ),
    );
  }
}
