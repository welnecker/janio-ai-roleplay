import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String apiUrl = "http://127.0.0.1:8000/chat/"; // rodando local

  Future<Map<String, dynamic>> sendMessage(String userInput, int score) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_input": userInput, "score": score}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erro ao se comunicar com o backend IA.");
    }
  }
}
