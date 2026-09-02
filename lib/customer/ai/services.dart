import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_urls.dart';
import '../../core/session_recovery.dart';
import 'model.dart';

/// Client for the Panda AI assistant backend (`apps/ai_assistant`).
class AIService {
  AIService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// Send a chat message and get the AI reply with any tool actions.
  /// Gemini may chain several tool calls, so allow a generous timeout.
  Future<AIChatResult> sendMessage(
    String token, {
    required String message,
    int? conversationId,
  }) async {
    final response = await _client
        .post(
          Uri.parse(AppUrls.aiChat),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': message,
            'conversation_id': ?conversationId,
          }),
        )
        .timeout(const Duration(seconds: 90));

    _log('POST ${AppUrls.aiChat}', response.statusCode, response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw AIException(response.statusCode, response.body);
    }

    return AIChatResult.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  /// List the customer's past conversations (newest first).
  Future<List<AIConversation>> listConversations(String token) async {
    final response = await _client
        .get(
          Uri.parse(AppUrls.aiConversations),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 30));

    _log('GET ${AppUrls.aiConversations}', response.statusCode, response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw AIException(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body);
    // DRF pagination wraps the list in {count, results: [...]}; the list
    // endpoint may also return a bare array.
    final raw = decoded is Map ? decoded['results'] : decoded;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => AIConversation.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Fetch one conversation with its full message history.
  Future<AIConversationDetail> getConversation(String token, int id) async {
    final url = AppUrls.aiConversationDetail(id);
    final response = await _client
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 30));

    _log('GET $url', response.statusCode, response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw AIException(response.statusCode, response.body);
    }

    return AIConversationDetail.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  /// Delete a conversation.
  Future<void> deleteConversation(String token, int id) async {
    final url = AppUrls.aiConversationDetail(id);
    final response = await _client
        .delete(Uri.parse(url), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 30));

    _log('DELETE $url', response.statusCode, response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) handleUnauthorized();
      throw AIException(response.statusCode, response.body);
    }
  }

  void _log(String request, int statusCode, String body) {
    if (kDebugMode) {
      debugPrint('[AI] $request → $statusCode');
      debugPrint(
        '[AI] Body: ${body.length > 400 ? body.substring(0, 400) : body}',
      );
    }
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
