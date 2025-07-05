import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://web-production-76f08.up.railway.app";

  /// ✅ Envia mensagem ao backend, com suporte a regeneração de resposta
  Future<Map<String, dynamic>> sendMessage({
    required String mensagem,
    required String personagem,
    bool regenerar = false, // ✅ Novo parâmetro com valor padrão
  }) async {
    final url = Uri.parse("$baseUrl/chat/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_input": mensagem,
          "personagem": personagem,
          "regenerar": regenerar, // ✅ Envia para o backend
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

  /// Carrega a introdução com resumo da personagem
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

  /// Recupera mensagens anteriores salvas na planilha
  Future<List<Map<String, String>>> getMensagens(String personagem) async {
    final url = Uri.parse('$baseUrl/mensagens/?personagem=$personagem');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return (data as List)
            .map<Map<String, String>>((item) => {
                  "role": item["role"]?.toString() ?? '',
                  "content": item["content"]?.toString() ?? '',
                })
            .toList();
      } else {
        print("Erro ao carregar mensagens: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Erro ao carregar mensagens: $e");
      return [];
    }
  }

  /// ✅ Apaga todas as memórias da personagem no ChromaDB
  Future<String> resetMemorias(String personagem) async {
    final url = Uri.parse('$baseUrl/memorias_clear/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"personagem": personagem}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["status"] ?? "Memórias apagadas.";
      } else {
        return "Erro ao apagar memórias: ${response.statusCode}";
      }
    } catch (e) {
      return "Erro ao apagar memórias: $e";
    }
  }
}
