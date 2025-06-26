import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // ✅ necessário para utf8.decode

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> personagens = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarPersonagens();
  }

  Future<void> carregarPersonagens() async {
    final url = Uri.parse("https://web-production-76f08.up.railway.app/personagens/");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes); // ✅ Decodificação correta
        final List dados = jsonDecode(decoded);
        final convertidos = dados.map<Map<String, String>>(
          (e) => e.map((k, v) => MapEntry(k.toString(), v.toString())),
        ).toList();

        setState(() {
          personagens = convertidos;
          carregando = false;
        });
      } else {
        setState(() => carregando = false);
        print("Erro: status ${response.statusCode}");
      }
    } catch (e) {
      print("Erro ao carregar personagens: $e");
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (personagens.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Nenhum personagem encontrado.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha seu personagem'),
      ),
      body: ListView.builder(
        itemCount: personagens.length,
        itemBuilder: (context, index) {
          final personagem = personagens[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(personagem['foto'] ?? ""),
              ),
              title: Text(personagem['nome'] ?? ""),
              subtitle: Text(personagem['descricao'] ?? ""),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(character: {
                      "nome": personagem['nome'] ?? "",
                      "descricao": personagem['descricao'] ?? "",
                    }),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
