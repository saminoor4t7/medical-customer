/// Models for the Panda AI assistant (backend `apps/ai_assistant`).
///
/// Chat endpoint returns:
/// ```json
/// {
///   "reply": "...",
///   "actions": [{"tool": "search_medicines", "args": {}, "result": {}}],
///   "conversation_id": 12
/// }
/// ```
library;

/// A medicine returned inside AI action results (search / symptom check /
/// medicine details). Unlike the catalog `Medicine`, this shape carries
/// pharmacy-specific price/stock and a plain-string brand.
class AIMedicine {
  const AIMedicine({
    required this.id,
    required this.name,
    this.genericName,
    this.strength,
    this.form,
    this.brand,
    this.requiresPrescription = false,
    this.description,
    this.price = 0,
    this.stock = 0,
    this.available = false,
    this.pharmacy,
  });

  final int id;
  final String name;
  final String? genericName;
  final String? strength;
  final String? form;
  final String? brand;
  final bool requiresPrescription;
  final String? description;
  final double price;
  final int stock;
  final bool available;
  final String? pharmacy;

  factory AIMedicine.fromJson(Map<String, dynamic> json) {
    return AIMedicine(
      id: _int(json['id']),
      name: json['name']?.toString() ?? 'Unknown Medicine',
      genericName: json['generic_name']?.toString(),
      strength: json['strength']?.toString(),
      form: json['form']?.toString(),
      brand: json['brand']?.toString(),
      requiresPrescription: json['requires_prescription'] as bool? ?? false,
      description: json['description']?.toString(),
      price: _number(json['price']),
      stock: _int(json['stock']),
      available: json['available'] as bool? ?? false,
      pharmacy: json['pharmacy']?.toString(),
    );
  }
}

/// One tool call the AI performed while answering (e.g. `search_medicines`).
class AIAction {
  const AIAction({
    required this.tool,
    this.args = const {},
    this.result = const {},
  });

  final String tool;
  final Map<String, dynamic> args;
  final Map<String, dynamic> result;

  factory AIAction.fromJson(Map<String, dynamic> json) {
    return AIAction(
      tool: json['tool']?.toString() ?? '',
      args: _map(json['args']),
      result: _map(json['result']),
    );
  }
}

/// Response of `POST /ai/chat/`.
class AIChatResult {
  const AIChatResult({
    required this.reply,
    this.actions = const [],
    this.conversationId,
  });

  final String reply;
  final List<AIAction> actions;
  final int? conversationId;

  factory AIChatResult.fromJson(Map<String, dynamic> json) {
    return AIChatResult(
      reply: json['reply']?.toString() ??
          json['response']?.toString() ??
          "I've processed your request.",
      actions: _actionList(json['actions']),
      conversationId: _intOrNull(json['conversation_id']),
    );
  }
}

/// A single message inside a conversation. Roles: `user`, `model`, `tool`.
/// [prescription] is a client-side attachment (in-chat Rx upload card) and
/// is never parsed from the API.
class AIChatMessage {
  const AIChatMessage({
    required this.role,
    required this.content,
    this.actions = const [],
    this.prescription,
  });

  final String role;
  final String content;
  final List<AIAction> actions;
  final Object? prescription;

  bool get isUser => role == 'user';

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    return AIChatMessage(
      role: json['role']?.toString() ?? 'model',
      content: json['content']?.toString() ?? '',
      actions: _actionList(json['action_data']),
    );
  }
}

/// Conversation entry in `GET /ai/assistant/conversations/`.
class AIConversation {
  const AIConversation({
    required this.id,
    this.title = 'New Chat',
    this.messageCount = 0,
    this.updatedAt,
  });

  final int id;
  final String title;
  final int messageCount;
  final DateTime? updatedAt;

  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      id: _int(json['id']),
      title: json['title']?.toString() ?? 'New Chat',
      messageCount: _int(json['message_count']),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

/// Conversation detail from `GET /ai/assistant/conversations/<id>/`.
class AIConversationDetail {
  const AIConversationDetail({
    required this.id,
    this.title = 'New Chat',
    this.messages = const [],
  });

  final int id;
  final String title;
  final List<AIChatMessage> messages;

  factory AIConversationDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    final messages = <AIChatMessage>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final msg = AIChatMessage.fromJson(Map<String, dynamic>.from(item));
          // Skip internal tool rows; only show user/model turns.
          if (msg.role == 'user' || msg.role == 'model') {
            messages.add(msg);
          }
        }
      }
    }
    return AIConversationDetail(
      id: _int(json['id']),
      title: json['title']?.toString() ?? 'New Chat',
      messages: messages,
    );
  }
}

// -- Shared helpers ---------------------------------------------------------

List<AIAction> _actionList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((m) => AIAction.fromJson(Map<String, dynamic>.from(m)))
      .toList();
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

int? _intOrNull(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double _number(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
