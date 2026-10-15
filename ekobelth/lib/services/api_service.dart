import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tratamento.dart';
import '../models/remedio_estoque.dart';
import '../models/usuario.dart';
import 'sessao.dart';

/// Erro de autenticação com mensagem amigável para exibir na tela.
class AuthException implements Exception {
  final String mensagem;
  AuthException(this.mensagem);
  @override
  String toString() => mensagem;
}

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// Cliente HTTP único, reaproveitado por todas as instâncias de [ApiService].
  /// Mantém a conexão aberta (keep-alive) entre as chamadas, evitando abrir
  /// uma nova conexão TCP a cada requisição (mais rápido em aparelhos leves).
  static final http.Client _client = http.Client();

  /// Tempo máximo de espera das requisições de dados.
  static const Duration _timeout = Duration(seconds: 15);

  /// Monta a URL já incluindo o id do usuário logado (?usuario_id=),
  /// para o backend devolver apenas os dados dele.
  Uri _uri(String path) {
    final uri = Uri.parse('$baseUrl/$path');
    final id = Sessao.usuarioId;
    if (id == null) return uri;
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'usuario_id': '$id'},
    );
  }

  // ── Autenticação ──

  Future<Usuario> login(String email, String senha) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({'email': email.trim(), 'senha': senha}),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw AuthException('Servidor demorou para responder.');
    } catch (_) {
      throw AuthException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    if (response.statusCode == 401) {
      throw AuthException('Email ou senha inválidos.');
    }
    throw AuthException('Erro ao entrar (${response.statusCode}).');
  }

  Future<Usuario> registrar(String nome, String email, String senha) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/registrar'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'nome': nome, 'email': email.trim(), 'senha': senha}),
    ).timeout(_timeout);
    if (response.statusCode == 201) {
      return Usuario.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    if (response.statusCode == 409) {
      throw AuthException('Email já cadastrado.');
    }
    throw AuthException('Erro ao cadastrar (${response.statusCode}).');
  }

  // ── Tratamentos / Estoque ──

  Future<List<Tratamento>> _getListaTratamentos(String endpoint) async {
    final response = await _client.get(_uri('$endpoint/')).timeout(_timeout);
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Tratamento.fromJson(item)).toList();
    } else {
      throw Exception('Falha ao carregar $endpoint: ${response.statusCode}');
    }
  }

  Future<List<Tratamento>> getTratamentos() {
    return _getListaTratamentos('tratamentos');
  }

  Future<List<Tratamento>> getLembretes() {
    return _getListaTratamentos('lembretes');
  }

  Future<List<RemedioEstoque>> getEstoque() async {
    final response = await _client.get(_uri('estoque/')).timeout(_timeout);
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => RemedioEstoque.fromJson(item)).toList();
    } else {
      throw Exception('Falha ao carregar estoque: ${response.statusCode}');
    }
  }

  Future<bool> addTratamento(Tratamento tratamento) async {
    final response = await _client.post(
      _uri('tratamentos/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(tratamento.toJson()),
    ).timeout(_timeout);
    return response.statusCode == 201;
  }

  Future<bool> updateTratamento(int id, Tratamento tratamento) async {
    final response = await _client.put(
      _uri('tratamentos/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(tratamento.toJsonForUpdate()),
    ).timeout(_timeout);
    return response.statusCode == 200;
  }

  Future<bool> deleteTratamento(int id) async {
    final response = await _client.delete(
      _uri('tratamentos/$id'),
      headers: {"Content-Type": "application/json"},
    ).timeout(_timeout);
    return response.statusCode == 200;
  }

  Future<bool> addRemedioEstoque(Map<String, dynamic> remedioJson) async {
    final response = await _client.post(
      _uri('estoque/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(remedioJson),
    ).timeout(_timeout);
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> deleteRemedioEstoque(int id) async {
    final response = await _client.delete(
      _uri('estoque/$id'),
      headers: {"Content-Type": "application/json"},
    ).timeout(_timeout);
    return response.statusCode == 200 || response.statusCode == 204;
  }
}