import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Réponse standardisée succès/erreur.
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

/// Client HTTP JSON + extraction d'erreurs lisibles.
class ApiClient {
  final http.Client _http;
  final String _base;

  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _base = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_base$normalized').replace(queryParameters: query);
  }

  Future<ApiResponse<Map<String, dynamic>>> getJson(
    String path, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final res = await _http
          .get(
            _uri(path),
            headers: {
              'Accept': 'application/json',
              'Accept-Language': 'fr-FR',
              ...?headers,
            },
          )
          .timeout(timeout);

      final decoded = _parseBody(res.body);
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

  Future<ApiResponse<Map<String, dynamic>>> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final res = await _http
          .post(
            _uri(path),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Accept-Language': 'fr-FR',
              ...?headers,
            },
            body: body is String ? body : jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(timeout);

      final decoded = _parseBody(res.body);
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

  Future<ApiResponse<Map<String, dynamic>>> putJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final res = await _http
          .put(
            _uri(path),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Accept-Language': 'fr-FR',
              ...?headers,
            },
            body: body is String ? body : jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(timeout);

      final decoded = _parseBody(res.body);
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

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String path, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final res = await _http
          .delete(
            _uri(path),
            headers: {
              'Accept': 'application/json',
              'Accept-Language': 'fr-FR',
              ...?headers,
            },
          )
          .timeout(timeout);

      final decoded = _parseBody(res.body);
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

  void dispose() {
    _http.close();
  }

  // --- helpers internes ---

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

final ApiClient apiClient = ApiClient();
