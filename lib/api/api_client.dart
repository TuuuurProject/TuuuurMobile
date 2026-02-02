import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth/token_provider.dart';

/// Standardized success/error response.
class ApiResponse<T> {
  final bool ok;
  final T? data;
  final int? statusCode;
  final String? message;
  final Object? raw;

  const ApiResponse._({
    required this.ok,
    this.data,
    this.statusCode,
    this.message,
    this.raw,
  });

  factory ApiResponse.ok(T data, {int? statusCode}) =>
      ApiResponse._(ok: true, data: data, statusCode: statusCode);

  factory ApiResponse.err({String? message, int? statusCode, Object? raw}) =>
      ApiResponse._(ok: false, message: message, statusCode: statusCode, raw: raw);
}

/// HTTP JSON client with readable error extraction.
class ApiClient {
  final http.Client _http;
  final String _base;
  final TokenProvider? _tokenProvider;

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    TokenProvider? tokenProvider,
  })  : _http = httpClient ?? http.Client(),
        _base = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
        _tokenProvider = tokenProvider;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_base$normalized').replace(queryParameters: query);
  }

  Future<Map<String, String>> _prepareHeaders({
    Map<String, String>? headers,
    bool auth = false,
  }) async {
    final result = <String, String>{...?headers};

    if (auth && _tokenProvider != null) {
      await _tokenProvider.refreshIfNeeded();

      final token = _tokenProvider.accessToken;
      if (token != null && token.isNotEmpty) {
        result['Authorization'] = 'Bearer $token';
      }
    }

    return result;
  }

  Future<ApiResponse<Map<String, dynamic>>> _executeRequest(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool auth = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final allHeaders = await _prepareHeaders(headers: headers, auth: auth);

      final requestHeaders = <String, String>{
        'Accept': 'application/json',
        'Accept-Language': 'fr-FR',
        ...allHeaders,
      };

      String? bodyStr;
      if (body != null) {
        requestHeaders['Content-Type'] = 'application/json';
        bodyStr = body is String ? body : jsonEncode(body);
      }

      final http.Response res;
      switch (method.toUpperCase()) {
        case 'GET':
          res = await _http.get(_uri(path), headers: requestHeaders).timeout(timeout);
          break;
        case 'POST':
          res = await _http.post(_uri(path), headers: requestHeaders, body: bodyStr).timeout(timeout);
          break;
        case 'PUT':
          res = await _http.put(_uri(path), headers: requestHeaders, body: bodyStr).timeout(timeout);
          break;
        case 'DELETE':
          res = await _http.delete(_uri(path), headers: requestHeaders).timeout(timeout);
          break;
        default:
          throw ArgumentError('Méthode HTTP non supportée: $method');
      }

      bodyStr = utf8.decode(res.bodyBytes);
      
      final decoded = _parseBody(bodyStr);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResponse.ok(decoded, statusCode: res.statusCode);
      }
      return ApiResponse.err(
        statusCode: res.statusCode,
        message: _humanizeError(decoded, res.statusCode) ?? 'Erreur ${res.statusCode}.',
        raw: _rawForErr(decoded),
      );
    } catch (e) {
      return ApiResponse.err(message: 'Impossible de contacter le serveur : $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getJson(
    String path, {
    Map<String, String>? headers,
    bool auth = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _executeRequest('GET', path, headers: headers, auth: auth, timeout: timeout);
  }

  Future<ApiResponse<Map<String, dynamic>>> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool auth = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _executeRequest('POST', path, body: body, headers: headers, auth: auth, timeout: timeout);
  }

  Future<ApiResponse<Map<String, dynamic>>> putJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool auth = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _executeRequest('PUT', path, body: body, headers: headers, auth: auth, timeout: timeout);
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String path, {
    Map<String, String>? headers,
    bool auth = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _executeRequest('DELETE', path, headers: headers, auth: auth, timeout: timeout);
  }

  void dispose() {
    _http.close();
  }

  static Map<String, dynamic> _parseBody(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    try {
      final v = jsonDecode(body);
      if (v is Map<String, dynamic>) return v;
      return {'data': v};
    } catch (_) {
      return {'raw': body};
    }
  }

  static Object _rawForErr(Map<String, dynamic> decoded) {
    final d = decoded['data'];
    return d ?? decoded;
  }

  static String? _humanizeError(Map<String, dynamic> data, int status) {
    if (data['title'] != null || data['detail'] != null) {
      final t = (data['title'] ?? '').toString();
      final d = (data['detail'] ?? '').toString();
      final msg = [t, d].where((s) => s.isNotEmpty).join(' — ');
      if (msg.isNotEmpty) return msg;
    }

    final candidates = [
      data['errors'],
      data['error'],
      data['items'],
      data['data'],
    ];

    for (final c in candidates) {
      if (c is List && c.isNotEmpty) {
        final first = c.first;
        if (first is Map) {
          final desc = (first['description'] ??
                  first['detail'] ??
                  first['message'])
              ?.toString();
          if (desc != null && desc.isNotEmpty) return desc;

          final code = (first['code'] ?? first['title'] ?? first['type'])
              ?.toString();
          if (code != null && code.isNotEmpty) return code;
        } else {
          return first.toString();
        }
      }
    }

    if (data['message'] is String) return data['message'] as String;
    if (status == 409) return 'Conflit : compte existant.';
    if (status == 400 || status == 422) return 'Requête invalide.';
    return null;
  }
}
