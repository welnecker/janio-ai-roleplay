import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Altere para o IP do seu backend local ou remoto:
  final String baseUrl = "http://127.0.0.1:8000";

  /// Obtém a lista de personagens
  Future<List<Map<String, dynamic>>> getPersonagens() async {
    final url = Uri.parse('$baseUrl/personagens/'); // <- barra final corrigida
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erro ao carregar personagens: ${response.statusCode} - ${response.body}");
    }
  }

  /// Obtém a introdução/sinopse do personagem
  Future<Map<String, dynamic>> getIntro(String personagem) async {
    final url = Uri.parse('$baseUrl/intro/?personagem=$personagem'); // <-- se existir esse endpoint
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erro ao carregar introdução: ${response.statusCode} - ${response.body}");
    }
  }

  /// Envia mensagem para o backend
  Future<Map<String, dynamic>> sendMessage(
    String message,
    int score,
    String modo,
    String modelo,
    {String personagem = "Jennifer"}
  ) async {
    final url = Uri.parse('$baseUrl/chat/');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_input": message,
        "score": score,
        "modo": modo,
        "modelo": modelo,
        "personagem": personagem,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erro ao enviar mensagem: ${response.statusCode} - ${response.body}");
    }
  }
}
