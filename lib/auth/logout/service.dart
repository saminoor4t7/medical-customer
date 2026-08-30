import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import 'model.dart';

class LogoutService {
  LogoutService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LogoutResult> logout(LogoutRequest request, String accessToken) async {
    final response = await _client
        .post(
          Uri.parse(AppUrls.logout),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic>? data;
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    }
    return LogoutResult(statusCode: response.statusCode, data: data);
  }
}
