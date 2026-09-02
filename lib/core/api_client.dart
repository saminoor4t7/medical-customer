import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'app_urls.dart';
import 'auth_session.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.accessToken, required this.refreshToken});

  String accessToken;
  String refreshToken;

  bool _isRefreshing = false;
  final List<_PendingRequest> _pending = [];

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

  Future<http.Response> get(String url) => _request('GET', url);
  Future<http.Response> post(String url, {Object? body}) =>
      _request('POST', url, body: body);
  Future<http.Response> patch(String url, {Object? body}) =>
      _request('PATCH', url, body: body);
  Future<http.Response> delete(String url, {Object? body}) =>
      _request('DELETE', url, body: body);

  Future<http.StreamedResponse> sendMultipart(http.MultipartRequest request) async {
    request.headers['Authorization'] = 'Bearer $accessToken';
    return request.send();
  }

  Future<http.Response> _request(
    String method,
    String url, {
    Object? body,
    bool retried = false,
  }) async {
    final request = http.Request(method, Uri.parse(url));
    request.headers.addAll(_headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 && !retried) {
      final refreshed = await _refresh();
      if (refreshed) {
        return _request(method, url, body: body, retried: true);
      }
      throw const AuthException('Session expired. Please login again.');
    }

    return response;
  }

  Future<bool> _refresh() async {
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _pending.add(_PendingRequest(completer));
      return completer.future;
    }

    _isRefreshing = true;
    try {
      final res = await http.post(
        Uri.parse(AppUrls.tokenRefresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        _flushPending(false);
        return false;
      }

      final data = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      final newAccess = data['access']?.toString();
      final newRefresh = data['refresh']?.toString();
      if (newAccess == null || newAccess.isEmpty) {
        _flushPending(false);
        return false;
      }

      accessToken = newAccess;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        refreshToken = newRefresh;
      }
      await AuthSession.save(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      _flushPending(true);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ApiClient] refresh failed: $e');
      _flushPending(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _flushPending(bool success) {
    for (final pending in _pending) {
      pending.completer.complete(success);
    }
    _pending.clear();
  }
}

class _PendingRequest {
  _PendingRequest(this.completer);
  final Completer<bool> completer;
}
