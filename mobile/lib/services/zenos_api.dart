import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/mail_message.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ZenosApi {
  ZenosApi({
    http.Client? client,
    FlutterSecureStorage? storage,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'ZENOS_API_URL',
             defaultValue: 'https://zenos-mail.vercel.app',
           );

  static const _tokenKey = 'zenos_session_token';
  static const _requestTimeout = Duration(seconds: 20);

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String baseUrl;
  String? _token;

  Future<bool> restoreSession() async {
    _token = await _storage.read(key: _tokenKey);
    if (_token == null || _token!.isEmpty) return false;
    try {
      await _request('GET', '/api/session');
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) await logout(localOnly: true);
      return false;
    }
  }

  Future<void> login(String password) async {
    final result = await _request(
      'POST',
      '/api/login',
      authenticated: false,
      body: {'password': password, 'client': 'android'},
    );
    final token = result['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException('Server tidak mengembalikan sesi Android.');
    }
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> logout({bool localOnly = false}) async {
    if (!localOnly) {
      try {
        await _request('POST', '/api/logout');
      } catch (_) {}
    }
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<List<MailMessage>> messages({
    String query = '',
    String domain = '',
    String direction = 'inbound',
  }) async {
    final params = <String, String>{
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (domain.trim().isNotEmpty && domain != 'all') 'domain': domain,
      'direction': direction,
      'limit': '100',
    };
    final uri = Uri.parse('$baseUrl/api/mail').replace(queryParameters: params);
    final result = await _requestUri('GET', uri);
    final data = result['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MailMessage.fromJson)
        .toList();
  }

  Future<MailMessage> message(String id) async {
    final result = await _request(
      'GET',
      '/api/mail/${Uri.encodeComponent(id)}',
    );
    final data = result['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Format email dari server tidak valid.');
    }
    return MailMessage.fromJson(data);
  }

  Future<void> markRead(String id) async {
    await _request('PATCH', '/api/mail/${Uri.encodeComponent(id)}');
  }

  Future<String> send({
    required String from,
    required List<String> to,
    required String subject,
    required String text,
  }) async {
    final result = await _request(
      'POST',
      '/api/send',
      body: {
        'sender_email': from,
        'sender_name': 'Zenos Mail',
        'to': to,
        'subject': subject,
        'text': text,
      },
    );
    return result['id']?.toString() ?? '';
  }

  Future<void> registerDevice(String token) async {
    await _request('POST', '/api/devices', body: {'token': token});
  }

  Future<void> unregisterDevice(String token) async {
    await _request('DELETE', '/api/devices', body: {'token': token});
  }

  Future<int> syncArchive() async {
    final result = await _request('POST', '/api/mail/sync');
    return int.tryParse(result['archived']?.toString() ?? '') ?? 0;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _requestUri(
      method,
      Uri.parse('$baseUrl$path'),
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> _requestUri(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
    };
    late http.Response response;
    switch (method) {
      case 'GET':
        response = await _client
            .get(uri, headers: headers)
            .timeout(_requestTimeout);
      case 'POST':
        response = await _client
            .post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(_requestTimeout);
      case 'PATCH':
        response = await _client
            .patch(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(_requestTimeout);
      case 'DELETE':
        response = await _client
            .delete(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(_requestTimeout);
      default:
        throw ApiException('Metode API tidak didukung: $method');
    }

    final decoded = jsonDecode(response.body.isEmpty ? '{}' : response.body);
    final result = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] == false) {
      throw ApiException(
        result['error']?.toString() ?? 'Permintaan ke server gagal.',
        statusCode: response.statusCode,
      );
    }
    return result;
  }
}
