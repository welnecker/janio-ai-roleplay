import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<Map<String, dynamic>> sendMessage(String message, int score) async {
    final url = Uri.parse("$baseUrl/chat/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_input": message,
        "score": score,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Erro da API: ${response.statusCode} - ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getIntro() async {
    final url = Uri.parse("$baseUrl/intro/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Erro ao obter introdução: ${response.statusCode} - ${response.body}");
    }
  }
}
