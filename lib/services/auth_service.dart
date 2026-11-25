import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_response.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'token';
  static const _nombreKey = 'nombre';
  static const _emailKey = 'email';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<AuthResponse> register(String nombre, String email, String password) {
    return _authenticate('/auth/register', {
      'nombre': nombre,
      'email': email,
      'password': password,
    });
  }

  Future<AuthResponse> login(String email, String password) {
    return _authenticate('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _nombreKey);
    await _storage.delete(key: _emailKey);
  }

  Future<String?> nombreSesion() async {
    final stored = await _storage.read(key: _nombreKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }

    final token = await getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 401) {
      throw AuthException('La sesión expiró');
    }
    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final nombre = decoded['nombre'];
    final email = decoded['email'];
    if (email is String && email.isNotEmpty) {
      await _storage.write(key: _emailKey, value: email);
    }
    if (nombre is String && nombre.trim().isNotEmpty) {
      final value = nombre.trim();
      await _storage.write(key: _nombreKey, value: value);
      return value;
    }
    return null;
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthResponse> _authenticate(String path, Map<String, String> body) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(_errorMessage(response));
    }

    final auth = AuthResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await _storage.write(key: _tokenKey, value: auth.token);
    await _storage.write(key: _emailKey, value: auth.email);
    final nombre = auth.nombre?.trim();
    if (nombre != null && nombre.isNotEmpty) {
      await _storage.write(key: _nombreKey, value: nombre);
    }
    return auth;
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // El cuerpo no es JSON.
    }
    if (response.body.isNotEmpty) {
      return response.body;
    }
    return 'Error ${response.statusCode}';
  }
}
