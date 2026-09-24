import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tratamento.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  Future<List<Tratamento>> _getListaTratamentos(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl/$endpoint/'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Tratamento.fromJson(item)).toList();
    } else {
      throw Exception('Falha ao carregar $endpoint: ${response.statusCode}');
    }
  }

  Future<List<Tratamento>> getTratamentos() {
    return _getListaTratamentos('tratamentos');
  }

  Future<List<Tratamento>> getLembretes() async {
    final tratamentos = await getTratamentos();
    return tratamentos
        .where((tratamento) => tratamento.inicio.isNotEmpty)
        .toList();
  }

  Future<bool> addTratamento(Tratamento tratamento) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tratamentos/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(tratamento.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateTratamento(int id, Tratamento tratamento) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tratamentos/$id/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(tratamento.toJson()),
    );
    return response.statusCode == 200;
  }
}
