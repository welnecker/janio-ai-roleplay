// lib/screens/character_selection_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, String>> personagens = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    carregarPersonagens();
  }

  Future<void> carregarPersonagens() async {
    try {
      final url = Uri.parse("${apiService.baseUrl}/personagens/");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(
            jsonDecode(utf8.decode(response.bodyBytes)));

        setState(() {
          personagens = data.map((p) => {
                "nome": p["nome"] ?? "",
                "descricao": p["descricao"] ?? "",
                "foto": p["foto"] ?? "",
              }).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Erro ao carregar personagens: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escolha um personagem")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount: personagens.length,
                  itemBuilder: (context, index) {
                    final personagem = personagens[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(personagem["foto"]!),
                      ),
                      title: Text(personagem["nome"]!),
                      subtitle: Text(personagem["descricao"]!),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(character: personagem),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
