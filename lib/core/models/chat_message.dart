class ChatMessage {
  const ChatMessage({
    required this.authorName,
    required this.body,
    required this.sentAt,
    required this.fromCurrentUser,
  });

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    return ChatMessage(
      authorName: json['authorName']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      sentAt: DateTime.parse(json['sentAt'].toString()).toLocal(),
      fromCurrentUser: json['fromCurrentUser'] == true,
    );
  }

  final String authorName;
  final String body;
  final DateTime sentAt;
  final bool fromCurrentUser;
}
