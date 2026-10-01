import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_store.dart';
import 'api_exception.dart';

class ApiClient {
  factory ApiClient({
    required String baseUrl,
    required TokenStore tokenStore,
    http.Client? httpClient,
  }) {
    return ApiClient._(
      baseUrl.replaceFirst(RegExp(r'/+$'), ''),
      tokenStore,
      httpClient ?? http.Client(),
    );
  }

  const ApiClient._(this._baseUrl, this._tokenStore, this._httpClient);

  final String _baseUrl;
  final TokenStore _tokenStore;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(String path, {bool authenticated = true}) {
    return _send('GET', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('PUT', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('PATCH', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authenticated = true,
  }) {
    return _send('DELETE', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _tokenStore.read();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalizedPath');
    final request = http.Request(method, uri)..headers.addAll(headers);

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    final payload = _decodeBody(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exceptionFor(response.statusCode, payload);
    }

    return payload;
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;

    return <String, dynamic>{'data': decoded};
  }

  ApiException _exceptionFor(int statusCode, Map<String, dynamic> payload) {
    final parsedErrors = <String, List<String>>{};
    final rawErrors = payload['errors'];

    if (rawErrors is Map) {
      for (final entry in rawErrors.entries) {
        final value = entry.value;
        if (value is List) {
          parsedErrors[entry.key.toString()] = value
              .map((item) => item.toString())
              .toList(growable: false);
        } else if (value != null) {
          parsedErrors[entry.key.toString()] = [value.toString()];
        }
      }
    }

    String? firstValidationMessage;
    for (final messages in parsedErrors.values) {
      if (messages.isNotEmpty) {
        firstValidationMessage = messages.first;
        break;
      }
    }

    return ApiException(
      statusCode: statusCode,
      message:
          firstValidationMessage ??
          payload['message']?.toString() ??
          'Something went wrong. Please try again.',
      errors: parsedErrors,
    );
  }
}
