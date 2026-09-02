import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import '../../core/session_recovery.dart';

class AIService {
  AIService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// Send a chat message to the AI agent.
  /// Returns the full response (session_id + AI reply + matched medicines).
  Future<Map<String, dynamic>> sendMessage(
    String token, {
    required String message,
    int? sessionId,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    final uri = Uri.parse(AppUrls.aiChat);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['message'] = message;

    if (sessionId != null) {
      request.fields['session_id'] = sessionId.toString();
    }

    if (imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFilename ?? 'prescription.jpg',
        ),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (kDebugMode) {
      debugPrint('[AI] POST ${AppUrls.aiChat} → ${response.statusCode}');
      debugPrint('[AI] Response: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw AIException(response.statusCode, response.body);
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body) as Map,
    );
  }

  /// Semantic medicine search (no chat session).
  Future<Map<String, dynamic>> searchMedicines(
    String token, {
    required String query,
    int topK = 5,
  }) async {
    final response = await _client.post(
      Uri.parse(AppUrls.aiSearch),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'query': query, 'top_k': topK}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw AIException(response.statusCode, response.body);
    }
    return Map<String, dynamic>.from(
      jsonDecode(response.body) as Map,
    );
  }
}

class AIException implements Exception {
  const AIException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() =>
      'AI API error ($statusCode): ${body.trim().isEmpty ? "No response." : body.trim()}';
}
