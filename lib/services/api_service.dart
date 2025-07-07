import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://web-production-76f08.up.railway.app";

  /// Envia mensagem ao backend com modo e estado
  Future<Map<String, dynamic>> sendMessage({
    required String mensagem,
    required String modo,
    required String personagem,
    required String estado,
  }) async {
    final url = Uri.parse("$baseUrl/chat/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_input": mensagem,
        "modo": modo,
        "personagem": personagem,
        "estado": estado,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Erro ao enviar mensagem: ${response.statusCode}");
    }
  }

  /// Busca lista de personagens no backend
  Future<List<Map<String, dynamic>>> getPersonagens() async {
    final url = Uri.parse("$baseUrl/personagens/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Erro ao buscar personagens: ${response.statusCode}');
    }
  }
}
