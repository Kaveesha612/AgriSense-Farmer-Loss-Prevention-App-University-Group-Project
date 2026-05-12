class ChatMessage {
  final String id;
  final String userMessage;
  final String botResponse;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.userMessage,
    required this.botResponse,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final timestampValue = json['timestamp'];
    DateTime parsedTimestamp;

    if (timestampValue is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    } else if (timestampValue is String) {
      parsedTimestamp = DateTime.tryParse(timestampValue) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now();
    }

    return ChatMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userMessage: json['message']?.toString() ?? '',
      botResponse: json['response']?.toString() ?? '',
      timestamp: parsedTimestamp,
    );
  }

  String get summary {
    if (botResponse.isNotEmpty) {
      return botResponse.length > 80 ? '${botResponse.substring(0, 80)}…' : botResponse;
    }
    return userMessage.length > 80 ? '${userMessage.substring(0, 80)}…' : userMessage;
  }
}
