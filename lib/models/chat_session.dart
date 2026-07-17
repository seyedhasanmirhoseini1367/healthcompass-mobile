class ChatSession {
  final String id;
  final String title;
  final String? createdAt;
  final String? updatedAt;
  final int messageCount;

  const ChatSession({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
    this.messageCount = 0,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? 'Chat').toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
        messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      );

  ChatSession copyWith({String? title}) => ChatSession(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messageCount: messageCount,
      );
}

/// One query/response pair from a session's history
/// (GET /assistant/sessions/:id/ → messages[]).
class ChatHistoryMessage {
  final String id;
  final String query;
  final String response;
  final String? createdAt;

  const ChatHistoryMessage({
    required this.id,
    required this.query,
    required this.response,
    this.createdAt,
  });

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) => ChatHistoryMessage(
        id: (json['id'] ?? '').toString(),
        query: (json['query'] ?? '').toString(),
        response: (json['response'] ?? '').toString(),
        createdAt: json['created_at']?.toString(),
      );
}
