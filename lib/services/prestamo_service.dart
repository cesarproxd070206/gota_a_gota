import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/prestamo.dart';
import 'auth_service.dart';

class SessionExpiredException implements Exception {
  SessionExpiredException([this.message = 'Sesión expirada']);

  final String message;

  @override
  String toString() => message;
}

class PrestamoException implements Exception {
  PrestamoException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrestamoService {
  PrestamoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Prestamo>> listar() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/prestamos'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Prestamo.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Prestamo> crear(Prestamo prestamo) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/prestamos'),
      headers: await _headers(json: true),
      body: jsonEncode(_body(prestamo)),
    );
    _ensureSuccess(response);
    return Prestamo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Prestamo> actualizar(int id, Prestamo prestamo) async {
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/prestamos/$id'),
      headers: await _headers(json: true),
      body: jsonEncode(_body(prestamo)),
    );
    _ensureSuccess(response);
    return Prestamo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> eliminar(int id) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/prestamos/$id'),
      headers: await _headers(),
    );
    _ensureSuccess(response, allowEmpty: true);
  }

  Future<void> marcarPagado(int id) async {
    final actual = await _obtener(id);
    await actualizar(
      id,
      Prestamo(
        id: actual.id,
        cliente: actual.cliente,
        dni: actual.dni,
        monto: actual.monto,
        interes: actual.interes,
        fechaPrestamo: actual.fechaPrestamo,
        fechaVencimiento: actual.fechaVencimiento,
        pagado: true,
        totalACobrar: actual.totalACobrar,
      ),
    );
  }

  Future<Prestamo> _obtener(int id) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/prestamos/$id'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return Prestamo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw SessionExpiredException();
    }
    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _body(Prestamo prestamo) {
    return {
      'cliente': prestamo.cliente,
      'dni': prestamo.dni,
      'monto': prestamo.monto,
      'interes': prestamo.interes,
      'fechaVencimiento': prestamo.toJson()['fechaVencimiento'],
      'pagado': prestamo.pagado,
    };
  }

  void _ensureSuccess(http.Response response, {bool allowEmpty = false}) {
    if (response.statusCode == 401) {
      throw SessionExpiredException(_message(response));
    }
    final ok = response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204;
    if (!ok) {
      throw PrestamoException(_message(response));
    }
    if (!allowEmpty && response.statusCode != 204 && response.body.isEmpty) {
      throw PrestamoException('Respuesta vacía del servidor');
    }
  }

  String _message(http.Response response) {
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
