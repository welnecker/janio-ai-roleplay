import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://web-production-76f08.up.railway.app";

  /// Lista todos os personagens disponíveis
  Future<List<Map<String, dynamic>>> getPersonagens() async {
    final url = Uri.parse('$baseUrl/personagens/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final List<dynamic> data = jsonDecode(decoded);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Erro ao carregar personagens");
    }
  }

  /// Envia uma mensagem e recebe a resposta da IA
  Future<Map<String, dynamic>> sendMessage({
    required String mensagem,
    required int score,
    required String modo,
    required String personagem,
  }) async {
    final url = Uri.parse('$baseUrl/chat/');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_input": mensagem,
        "score": score,
        "modo": modo,
        "personagem": personagem,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      return jsonDecode(decoded);
    } else {
      throw Exception("Erro ao enviar mensagem");
    }
  }

  /// Carrega o resumo introdutório do personagem
  Future<Map<String, dynamic>> getIntro({
    required String nome,
    required String personagem,
  }) async {
    final url = Uri.parse('$baseUrl/intro/?nome=$nome&personagem=$personagem');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      return jsonDecode(decoded);
    } else {
      throw Exception("Erro ao carregar introdução");
    }
  }
}
