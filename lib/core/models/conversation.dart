import 'chat_message.dart';
import 'listing.dart';

class Conversation {
  Conversation({
    required this.id,
    required this.listing,
    required List<ChatMessage> messages,
  }) : messages = List.unmodifiable(messages);

  final String id;
  final Listing listing;
  final List<ChatMessage> messages;

  factory Conversation.fromJson(Map<String, Object?> json) {
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
              .map((message) => ChatMessage.fromJson(_readMap(message)))
              .toList()
        : <ChatMessage>[];
    return Conversation(
      id: json['id']?.toString() ?? '',
      listing: Listing.fromJson(_readMap(json['listing'])),
      messages: messages,
    );
  }

  Conversation copyWith({List<ChatMessage>? messages}) {
    return Conversation(
      id: id,
      listing: listing,
      messages: messages ?? this.messages,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'listing': listing.toJson(),
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }
}

Map<String, Object?> _readMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return const {};
}
