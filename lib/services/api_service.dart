import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://web-production-76f08.up.railway.app";

  Future<Map<String, dynamic>> sendMessage({
    required String mensagem,
    required String personagem,
  }) async {
    final url = Uri.parse("$baseUrl/chat/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_input": mensagem,
          "personagem": personagem,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("Erro no envio da mensagem: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      print("Erro ao enviar mensagem: $e");
      return {};
    }
  }

  Future<String> getResumo(String personagem) async {
    final url = Uri.parse('$baseUrl/resumo/?personagem=$personagem');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['resumo'] ?? '';
      } else {
        print("Erro ao carregar resumo: ${response.statusCode}");
        return '';
      }
    } catch (e) {
      print("Erro ao carregar resumo: $e");
      return '';
    }
  }

  Future<List<Map<String, String>>> getMensagens(String personagem) async {
  final url = Uri.parse('$baseUrl/mensagens/?personagem=$personagem');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data as List).map<Map<String, String>>((item) => {
        "role": item["role"] ?? '',
        "content": item["content"] ?? '',
      }).toList();
    } else {
      print("Erro ao carregar mensagens: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    print("Erro ao carregar mensagens: $e");
    return [];
  }
}
