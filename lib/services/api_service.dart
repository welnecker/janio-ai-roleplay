import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://web-production-76f08.up.railway.app";

  Future<Map<String, dynamic>> sendMessage({
    required String mensagem,
    required String personagem,
    bool regenerar = false,
  }) async {
    final url = Uri.parse("$baseUrl/chat/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_input": mensagem,
          "personagem": personagem,
          "regenerar": regenerar,
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

  /// ✅ Semear memórias principais da aba "personagens"
  Future<String> semeiaMemoriasPrincipais(String personagem) async {
    final url = Uri.parse('$baseUrl/memorias_seed/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"personagem": personagem}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["status"] ?? "Memórias principais semeadas.";
      } else {
        return "Erro ao semear memórias principais: ${response.statusCode}";
      }
    } catch (e) {
      return "Erro ao semear memórias principais: $e";
    }
  }

  /// ✅ Semear memórias fixas da aba "memorias_fixas"
  Future<String> semeiaMemoriasFixas(String personagem) async {
    final url = Uri.parse('$baseUrl/memorias_seed_fixas/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"personagem": personagem}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["status"] ?? "Memórias fixas semeadas.";
      } else {
        return "Erro ao semear memórias fixas: ${response.statusCode}";
      }
    } catch (e) {
      return "Erro ao semear memórias fixas: $e";
    }
  }

  /// ✅ Nova função: semear memória inicial da aba personagem ou da primeira linha system
  Future<Map<String, dynamic>> semeiaMemoriaInicial(String personagem) async {
    final url = Uri.parse('$baseUrl/memoria_inicial/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"personagem": personagem}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("Erro ao semear memória inicial: ${response.statusCode}");
        return {"mensagem_inicial": ""};
      }
    } catch (e) {
      print("Erro ao semear memória inicial: $e");
      return {"mensagem_inicial": ""};
    }
  }
}
