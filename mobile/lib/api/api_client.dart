import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'token_store.dart';

class ApiException implements Exception {
  final int? status;
  final String message;
  final dynamic details;

  ApiException(this.message, {this.status, this.details});

  @override
  String toString() => 'ApiException(status: $status, message: $message)';
}

class ApiClient {
  final String baseUrl;
  final TokenStore tokenStore;
  final HttpClient _http;

  ApiClient({required this.baseUrl, required this.tokenStore, HttpClient? http})
      : _http = http ?? HttpClient();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    Map<String, String>? qp;
    if (query != null && query.isNotEmpty) {
      qp = query.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      qp.removeWhere((k, v) => v.trim().isEmpty);
      if (qp.isEmpty) qp = null;
    }
    return Uri.parse(baseUrl).replace(path: normalized, queryParameters: qp);
  }

  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, dynamic>? query, bool auth = true}) async {
    final req = await _http.getUrl(_uri(path, query));
    await _addHeaders(req, auth: auth);
    final res = await req.close();
    return _readJson(res);
  }

  Future<Map<String, dynamic>> postJson(String path,
      {Object? body, bool auth = true}) async {
    final req = await _http.postUrl(_uri(path));
    await _addHeaders(req, auth: auth);
    if (body != null) {
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    return _readJson(res);
  }

  Future<Map<String, dynamic>> putJson(String path,
      {Object? body, bool auth = true}) async {
    final req = await _http.putUrl(_uri(path));
    await _addHeaders(req, auth: auth);
    if (body != null) {
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    return _readJson(res);
  }

  Future<Map<String, dynamic>> patchJson(String path,
      {Object? body, bool auth = true}) async {
    final req = await _http.openUrl('PATCH', _uri(path));
    await _addHeaders(req, auth: auth);
    if (body != null) {
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    return _readJson(res);
  }

  Future<ApiBinaryResponse> getBytes(String path,
      {Map<String, dynamic>? query, bool auth = true}) async {
    final req = await _http.getUrl(_uri(path, query));
    await _addHeaders(req, auth: auth);
    final res = await req.close();
    final bytes = await _readResponseBytes(res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Try to decode a JSON error payload if present.
      dynamic decoded;
      try {
        final raw = utf8.decode(bytes);
        decoded = raw.isEmpty ? null : jsonDecode(raw);
      } catch (_) {
        decoded = null;
      }
      final message = (decoded is Map && decoded['message'] is String)
          ? decoded['message'] as String
          : 'HTTP ${res.statusCode}';
      throw ApiException(message, status: res.statusCode, details: decoded);
    }

    final contentDisposition = res.headers.value('content-disposition');
    final filename = _tryParseFilename(contentDisposition);
    return ApiBinaryResponse(bytes: bytes, filename: filename);
  }

  static Future<Uint8List> _readResponseBytes(HttpClientResponse res) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in res) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<void> _addHeaders(HttpClientRequest req, {required bool auth}) async {
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

    if (!auth) return;
    final tokens = await tokenStore.read();
    if (tokens?.accessToken != null && tokens!.accessToken.isNotEmpty) {
      req.headers.set(
          HttpHeaders.authorizationHeader, 'Bearer ${tokens.accessToken}');
    }
  }

  Future<Map<String, dynamic>> _readJson(HttpClientResponse res) async {
    final raw = await res.transform(utf8.decoder).join();
    final dynamic decoded = raw.isEmpty ? null : jsonDecode(raw);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = (decoded is Map && decoded['message'] is String)
          ? decoded['message'] as String
          : 'HTTP ${res.statusCode}';
      throw ApiException(message, status: res.statusCode, details: decoded);
    }

    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return <String, dynamic>{'data': decoded};
  }

  static String? _tryParseFilename(String? contentDisposition) {
    if (contentDisposition == null) return null;
    // Examples:
    //   attachment; filename="file.pdf"
    //   attachment; filename=file.pdf
    //   attachment; filename*=UTF-8''file%20name.pdf
    final parts = contentDisposition.split(';').map((p) => p.trim());

    String? candidate;
    for (final p in parts) {
      final lower = p.toLowerCase();
      if (lower.startsWith('filename*=')) {
        candidate = p.substring(p.indexOf('=') + 1).trim();
        break;
      }
    }
    if (candidate == null) {
      for (final p in parts) {
        if (p.toLowerCase().startsWith('filename=')) {
          candidate = p.substring(p.indexOf('=') + 1).trim();
          break;
        }
      }
    }

    if (candidate == null || candidate.isEmpty) return null;

    // Strip optional encoding/language prefix: UTF-8''
    final encodedMarkerIndex = candidate.indexOf("''");
    if (encodedMarkerIndex != -1) {
      candidate = candidate.substring(encodedMarkerIndex + 2);
    }

    // Strip quotes.
    if (candidate.length >= 2 &&
        ((candidate.startsWith('"') && candidate.endsWith('"')) ||
            (candidate.startsWith("'") && candidate.endsWith("'")))) {
      candidate = candidate.substring(1, candidate.length - 1);
    }

    candidate = candidate.trim();
    if (candidate.isEmpty) return null;
    try {
      return Uri.decodeFull(candidate);
    } catch (_) {
      return candidate;
    }
  }
}

class ApiBinaryResponse {
  final Uint8List bytes;
  final String? filename;

  const ApiBinaryResponse({required this.bytes, this.filename});
}
