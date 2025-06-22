import 'dart:convert';
import 'package:http/http.dart' as http;

/// Classe para comunicação com o backend (FastAPI)
class ApiService {
  //final String baseUrl = "http://127.0.0.1:8000"; // altere se necessário
  final String baseUrl = "http://192.168.0.25:8000"; // O IP do seu PC

  /// Envia uma mensagem do usuário com nota de 0 a 10, modo selecionado e modelo (GPT ou LM Studio)
  Future<Map<String, dynamic>> sendMessage(
    String message,
    int score,
    String modo,
    String modelo, // <-- Novo parâmetro!
  ) async {
    final url = Uri.parse("$baseUrl/chat/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_input": message,
        "score": score,
        "modo": modo,
        "modelo": modelo, // <-- Adiciona aqui
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Erro da API: ${response.statusCode} - ${response.body}");
    }
  }

  /// Carrega a introdução inicial da personagem com nome personalizado
  Future<Map<String, dynamic>> getIntro(String nome) async {
    final url = Uri.parse("$baseUrl/intro/?nome=$nome");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Erro ao carregar introdução: ${response.statusCode} - ${response.body}");
    }
  }
}
