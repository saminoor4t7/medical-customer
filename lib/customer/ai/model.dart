import '../catalog/model.dart';

class AIMessage {
  const AIMessage({
    required this.role,
    required this.content,
    this.medicines = const [],
    this.intent,
    this.confidence,
  });
  final String role; // 'user' or 'assistant'
  final String content;
  final List<Medicine> medicines;
  final String? intent;
  final double? confidence;
}

class AIChatSession {
  const AIChatSession({
    required this.id,
    this.language,
    this.messageCount = 0,
  });

  final int id;
  final String? language;
  final int messageCount;

  factory AIChatSession.fromJson(Map<String, dynamic> json) {
    return AIChatSession(
      id: _int(json['id']),
      language: json['language']?.toString(),
      messageCount: _int(json['message_count']),
    );
  }
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
