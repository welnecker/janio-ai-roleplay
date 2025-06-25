import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://web-production-76f08.up.railway.app";

  /// Envia uma mensagem ao backend e recebe a resposta da IA
  Future<Map<String, dynamic>> sendMessage({
    required String mensagem,
    required int score,
    required String modo,
    required String personagem,
    bool primeiraInteracao = false,
  }) async {
    final url = Uri.parse("$baseUrl/chat/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_input": mensagem,
        "score": score,
        "modo": modo,
        "personagem": personagem,
        "primeira_interacao": primeiraInteracao,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      print("Erro ao enviar mensagem: ${response.statusCode}");
      return {
        "response": "Erro ao se comunicar com a IA.",
        "sinopse": "",
      };
    }
  }
}
