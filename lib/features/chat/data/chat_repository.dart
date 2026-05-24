import '../../../core/models/conversation.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/api_client.dart';

class ChatRepository {
  ChatRepository({NestlyApiClient? apiClient})
    : _apiClient = apiClient ?? NestlyApiClient();

  final NestlyApiClient _apiClient;
  final List<Conversation> _conversations = [];

  List<Conversation> get conversations => List.unmodifiable(_conversations);

  Future<List<Conversation>> fetchConversations({
    required UserProfile buyer,
  }) async {
    try {
      final response = await _apiClient.getJson(
        '/api/conversations',
        queryParameters: {'buyerEmail': buyer.email},
      );
      final conversations = asJsonList(
        response,
      ).map((item) => Conversation.fromJson(asJsonMap(item))).toList();
      _conversations
        ..clear()
        ..addAll(conversations);
      return this.conversations;
    } on ApiException catch (error) {
      throw ChatException(error.message);
    } catch (_) {
      throw const ChatException('Conversations are unavailable right now.');
    }
  }

  Future<Conversation> startConversation({
    required Listing listing,
    required UserProfile buyer,
  }) async {
    try {
      final response = await _apiClient.postJson('/api/conversations', {
        'listingId': listing.id,
        'buyerEmail': buyer.email,
        'buyerName': buyer.name,
      });
      final conversation = Conversation.fromJson(asJsonMap(response));
      _replaceConversation(conversation);
      return conversation;
    } on ApiException catch (error) {
      throw ChatException(error.message);
    } catch (_) {
      throw const ChatException('Conversation could not be started.');
    }
  }

  Future<Conversation> sendMessage({
    required String conversationId,
    required UserProfile author,
    required String body,
  }) async {
    try {
      final response = await _apiClient.postJson(
        '/api/conversations/$conversationId/messages',
        {'authorEmail': author.email, 'authorName': author.name, 'body': body},
      );
      final conversation = Conversation.fromJson(asJsonMap(response));
      _replaceConversation(conversation);
      return conversation;
    } on ApiException catch (error) {
      throw ChatException(error.message);
    } catch (_) {
      throw const ChatException('Message could not be sent.');
    }
  }

  void _replaceConversation(Conversation conversation) {
    final index = _conversations.indexWhere(
      (chat) => chat.id == conversation.id,
    );
    if (index == -1) {
      _conversations.insert(0, conversation);
      return;
    }
    _conversations[index] = conversation;
  }
}

class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}
