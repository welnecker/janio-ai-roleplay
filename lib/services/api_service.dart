import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://web-production-xxxxx.up.railway.app"; // Substitua pela sua URL real

  /// Envia uma mensagem do usuário com nota, modo e controle de primeira interação
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
      return jsonDecode(utf8.decode(response.bodyBytes)); // ✅ decodifica acentuação
    } else {
      throw Exception("Erro ao enviar mensagem: ${response.body}");
    }
  }

  /// Busca o resumo introdutório das últimas interações com o personagem
  Future<Map<String, dynamic>> getIntro({
    required String nome,
    required String personagem,
  }) async {
    final url = Uri.parse("$baseUrl/intro/?nome=$nome&personagem=$personagem");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)); // ✅ trata UTF-8 corretamente
      } else {
        print("Erro ao buscar intro: ${response.statusCode}");
        return {"resumo": ""};
      }
    } catch (e) {
      print("Erro de conexão em getIntro: $e");
      return {"resumo": ""};
    }
  }
}
