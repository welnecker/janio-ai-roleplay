import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://web-production-76f08.up.railway.app";

  /// Envia uma mensagem do usuário com nota, modo e controle de primeira interação
  Future<Map<String, dynamic>> sendMessage({
    required String mensagem,
    required int score,
    required String modo,
    required String personagem,
    bool primeiraInteracao = false,
  }) async {
    final url = Uri.parse("$baseUrl/chat/");
    try {
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
        // decodifica acentuação corretamente
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("❌ Erro no envio da mensagem: ${response.statusCode}");
        print("Body: ${response.body}");
        return {"response": "Erro ao enviar mensagem para o servidor."};
      }
    } catch (e) {
      print("❌ Erro de conexão em sendMessage: $e");
      return {"response": "Falha na conexão com o servidor."};
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
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("❌ Erro ao buscar intro: ${response.statusCode}");
        return {"resumo": ""};
      }
    } catch (e) {
      print("❌ Erro de conexão em getIntro: $e");
      return {"resumo": ""};
    }
  }
}
