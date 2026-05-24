import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class NestlyApiClient {
  NestlyApiClient({http.Client? httpClient, Uri? baseUri})
    : _httpClient = httpClient ?? http.Client(),
      _baseUri = baseUri ?? ApiConfig.baseUri;

  final http.Client _httpClient;
  final Uri _baseUri;

  Future<Object?> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    final response = await _httpClient.get(_uri(path, queryParameters));
    return _decodeResponse(response);
  }

  Future<Object?> postJson(String path, Map<String, Object?> body) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  void close() => _httpClient.close();

  Uri _uri(String path, [Map<String, String?> queryParameters = const {}]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final cleanQuery = {
      for (final entry in queryParameters.entries)
        if (entry.value != null && entry.value!.trim().isNotEmpty)
          entry.key: entry.value!.trim(),
    };
    return _baseUri
        .resolve(cleanPath)
        .replace(queryParameters: cleanQuery.isEmpty ? null : cleanQuery);
  }

  Object? _decodeResponse(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded is Map<String, Object?>
        ? decoded['message']?.toString()
        : null;
    throw ApiException(
      message ?? 'The backend returned ${response.statusCode}.',
      statusCode: response.statusCode,
    );
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

Map<String, Object?> asJsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw const ApiException('The backend returned an unexpected response.');
}

List<Object?> asJsonList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return value.cast<Object?>();
  }
  throw const ApiException('The backend returned an unexpected response.');
}
