import '../../../core/models/conversation.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_json_store.dart';

class ChatRepository {
  ChatRepository({NestlyApiClient? apiClient, OfflineJsonStore? offlineStore})
    : _apiClient = apiClient ?? NestlyApiClient(),
      _offlineStore = offlineStore ?? OfflineJsonStore();

  final NestlyApiClient _apiClient;
  final OfflineJsonStore _offlineStore;
  final List<Conversation> _conversations = [];
  bool _isUsingOfflineData = false;
  bool _hasPendingWrites = false;
  String? _syncMessage;

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  bool get isUsingOfflineData => _isUsingOfflineData;
  bool get hasPendingWrites => _hasPendingWrites;
  String? get syncMessage => _syncMessage;

  Future<List<Conversation>> restoreConversations({
    required UserProfile buyer,
  }) async {
    final cached = await _readCachedConversations(buyer);
    if (cached.isEmpty) {
      await _refreshPendingState(buyer);
      return conversations;
    }
    _replaceAll(cached);
    _isUsingOfflineData = true;
    await _refreshPendingState(buyer);
    _syncMessage = _hasPendingWrites
        ? 'Showing saved chats. Local messages will sync when you refresh.'
        : 'Showing saved chats while fresh data loads.';
    return conversations;
  }

  Future<List<Conversation>> fetchConversations({
    required UserProfile buyer,
  }) async {
    if (_conversations.isEmpty) {
      await restoreConversations(buyer: buyer);
    }
    try {
      await _syncPendingChat(buyer);
      final response = await _apiClient.getJson(
        '/api/conversations',
        queryParameters: {'buyerEmail': buyer.email},
      );
      final conversations = asJsonList(
        response,
      ).map((item) => Conversation.fromJson(asJsonMap(item))).toList();
      _replaceAll(await _mergePendingLocalConversations(buyer, conversations));
      await _writeCachedConversations(buyer, _conversations);
      _isUsingOfflineData = false;
      await _refreshPendingState(buyer);
      _syncMessage = _hasPendingWrites
          ? 'Some chat updates are saved locally and will sync on refresh.'
          : null;
      return this.conversations;
    } catch (_) {
      return _fallbackConversations(buyer);
    }
  }

  Future<Conversation> startConversation({
    required Listing listing,
    required UserProfile buyer,
  }) async {
    final existing = _conversations.where(
      (chat) => chat.listing.id == listing.id,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    try {
      final response = await _apiClient.postJson('/api/conversations', {
        'listingId': listing.id,
        'buyerEmail': buyer.email,
        'buyerName': buyer.name,
      });
      final conversation = Conversation.fromJson(asJsonMap(response));
      _replaceConversation(conversation);
      await _writeCachedConversations(buyer, _conversations);
      _isUsingOfflineData = false;
      await _refreshPendingState(buyer);
      _syncMessage = null;
      return conversation;
    } on ApiException catch (error) {
      throw ChatException(error.message);
    } catch (_) {
      final conversation = Conversation(
        id: _localConversationId(listing: listing, buyer: buyer),
        listing: listing,
        messages: const [],
      );
      _replaceConversation(conversation);
      await _queuePendingOperation(buyer, {
        'type': 'start',
        'localConversationId': conversation.id,
        'listing': listing.toJson(),
        'buyer': buyer.toJson(),
      });
      await _writeCachedConversations(buyer, _conversations);
      _isUsingOfflineData = true;
      _syncMessage =
          'Chat saved locally. It will start when you refresh online.';
      return conversation;
    }
  }

  Future<Conversation> sendMessage({
    required String conversationId,
    required UserProfile author,
    required String body,
  }) async {
    if (conversationId.startsWith('local-')) {
      return _saveLocalMessage(
        conversationId: conversationId,
        author: author,
        body: body,
      );
    }

    try {
      final response = await _apiClient.postJson(
        '/api/conversations/$conversationId/messages',
        {'authorEmail': author.email, 'authorName': author.name, 'body': body},
      );
      final conversation = Conversation.fromJson(asJsonMap(response));
      _replaceConversation(conversation);
      await _writeCachedConversations(author, _conversations);
      _isUsingOfflineData = false;
      await _refreshPendingState(author);
      _syncMessage = null;
      return conversation;
    } on ApiException catch (error) {
      throw ChatException(error.message);
    } catch (_) {
      return _saveLocalMessage(
        conversationId: conversationId,
        author: author,
        body: body,
      );
    }
  }

  Future<List<Conversation>> _fallbackConversations(UserProfile buyer) async {
    _replaceAll(await _readCachedConversations(buyer));
    _isUsingOfflineData = true;
    await _refreshPendingState(buyer);
    _syncMessage = _conversations.isEmpty
        ? 'No saved chats yet. New chats will be stored locally.'
        : 'Showing saved chats until fresh data is available.';
    if (_hasPendingWrites) {
      _syncMessage =
          'Showing saved chats. Local messages will sync when you refresh.';
    }
    return conversations;
  }

  Future<Conversation> _saveLocalMessage({
    required String conversationId,
    required UserProfile author,
    required String body,
  }) async {
    final index = _conversations.indexWhere(
      (chat) => chat.id == conversationId,
    );
    if (index == -1) {
      throw const ChatException('Choose a conversation first.');
    }
    final message = ChatMessage(
      authorName: author.name,
      body: body,
      sentAt: DateTime.now(),
      fromCurrentUser: true,
    );
    final conversation = _conversations[index].copyWith(
      messages: [..._conversations[index].messages, message],
    );
    _replaceConversation(conversation);
    await _queuePendingOperation(author, {
      'type': 'message',
      'conversationId': conversationId,
      'author': author.toJson(),
      'message': message.toJson(),
    });
    await _writeCachedConversations(author, _conversations);
    _isUsingOfflineData = true;
    _syncMessage =
        'Message saved locally. It will send when you refresh online.';
    return conversation;
  }

  Future<void> _syncPendingChat(UserProfile buyer) async {
    final pending = await _readPendingOperations(buyer);
    if (pending.isEmpty) {
      _hasPendingWrites = false;
      return;
    }

    final remaining = <Map<String, Object?>>[];
    final idMap = <String, String>{};
    for (var index = 0; index < pending.length; index += 1) {
      final operation = _remapOperation(pending[index], idMap);
      try {
        switch (operation['type']) {
          case 'start':
            final listing = Listing.fromJson(asJsonMap(operation['listing']));
            final operationBuyer = UserProfile.fromJson(
              asJsonMap(operation['buyer']),
            );
            final response = await _apiClient.postJson('/api/conversations', {
              'listingId': listing.id,
              'buyerEmail': operationBuyer.email,
              'buyerName': operationBuyer.name,
            });
            final serverConversation = Conversation.fromJson(
              asJsonMap(response),
            );
            final localId = operation['localConversationId']?.toString() ?? '';
            final localConversation = _findConversation(localId);
            final merged = localConversation == null
                ? serverConversation
                : serverConversation.copyWith(
                    messages: _mergeMessages(
                      serverConversation.messages,
                      localConversation.messages,
                    ),
                  );
            _replaceConversation(merged, previousId: localId);
            idMap[localId] = serverConversation.id;
            break;
          case 'message':
            final conversationId = operation['conversationId']?.toString();
            if (conversationId == null || conversationId.startsWith('local-')) {
              remaining.add(operation);
              remaining.addAll(
                pending
                    .skip(index + 1)
                    .map((item) => _remapOperation(item, idMap)),
              );
              index = pending.length;
              break;
            }
            final author = UserProfile.fromJson(asJsonMap(operation['author']));
            final message = ChatMessage.fromJson(
              asJsonMap(operation['message']),
            );
            final response = await _apiClient
                .postJson('/api/conversations/$conversationId/messages', {
                  'authorEmail': author.email,
                  'authorName': author.name,
                  'body': message.body,
                });
            _replaceConversation(Conversation.fromJson(asJsonMap(response)));
            break;
        }
      } catch (_) {
        remaining.add(operation);
        remaining.addAll(
          pending.skip(index + 1).map((item) => _remapOperation(item, idMap)),
        );
        break;
      }
    }
    await _writePendingOperations(buyer, remaining);
    _hasPendingWrites = remaining.isNotEmpty;
    await _writeCachedConversations(buyer, _conversations);
  }

  Future<List<Conversation>> _mergePendingLocalConversations(
    UserProfile buyer,
    List<Conversation> fresh,
  ) async {
    final pending = await _readPendingOperations(buyer);
    final localIds = {
      for (final operation in pending)
        if (operation['type'] == 'start')
          operation['localConversationId']?.toString(),
    }..remove(null);
    final locals = _conversations
        .where((conversation) => localIds.contains(conversation.id))
        .toList();
    return [
      ...locals,
      ...fresh.where(
        (conversation) => !locals.any((local) => local.id == conversation.id),
      ),
    ];
  }

  Future<List<Conversation>> _readCachedConversations(UserProfile buyer) async {
    final raw = await _offlineStore.readList(_conversationsKey(buyer));
    final conversations = <Conversation>[];
    for (final item in raw) {
      try {
        conversations.add(Conversation.fromJson(asJsonMap(item)));
      } catch (_) {
        // Ignore malformed cached conversations.
      }
    }
    return conversations;
  }

  Future<void> _writeCachedConversations(
    UserProfile buyer,
    List<Conversation> conversations,
  ) async {
    await _offlineStore.writeList(
      _conversationsKey(buyer),
      conversations.map((conversation) => conversation.toJson()).toList(),
    );
  }

  Future<List<Map<String, Object?>>> _readPendingOperations(
    UserProfile buyer,
  ) async {
    final raw = await _offlineStore.readList(_pendingKey(buyer));
    final operations = <Map<String, Object?>>[];
    for (final item in raw) {
      try {
        operations.add(asJsonMap(item));
      } catch (_) {
        // Ignore malformed pending records.
      }
    }
    return operations;
  }

  Future<void> _writePendingOperations(
    UserProfile buyer,
    List<Map<String, Object?>> operations,
  ) async {
    await _offlineStore.writeList(_pendingKey(buyer), operations);
  }

  Future<void> _queuePendingOperation(
    UserProfile buyer,
    Map<String, Object?> operation,
  ) async {
    final pending = await _readPendingOperations(buyer);
    pending.add(operation);
    await _writePendingOperations(buyer, pending);
    _hasPendingWrites = true;
  }

  Future<void> _refreshPendingState(UserProfile buyer) async {
    _hasPendingWrites = (await _readPendingOperations(buyer)).isNotEmpty;
  }

  void _replaceAll(List<Conversation> conversations) {
    _conversations
      ..clear()
      ..addAll(conversations);
  }

  void _replaceConversation(Conversation conversation, {String? previousId}) {
    _conversations.removeWhere(
      (chat) =>
          chat.id == conversation.id ||
          (previousId != null && chat.id == previousId),
    );
    _conversations.insert(0, conversation);
  }

  Conversation? _findConversation(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) {
        return conversation;
      }
    }
    return null;
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> remote,
    List<ChatMessage> local,
  ) {
    final merged = [...remote];
    for (final message in local) {
      final alreadyPresent = merged.any(
        (existing) =>
            existing.authorName == message.authorName &&
            existing.body == message.body &&
            existing.fromCurrentUser == message.fromCurrentUser,
      );
      if (!alreadyPresent) {
        merged.add(message);
      }
    }
    return merged;
  }

  Map<String, Object?> _remapOperation(
    Map<String, Object?> operation,
    Map<String, String> idMap,
  ) {
    if (operation['type'] != 'message') {
      return operation;
    }
    final conversationId = operation['conversationId']?.toString();
    final mappedId = idMap[conversationId];
    if (mappedId == null) {
      return operation;
    }
    return {...operation, 'conversationId': mappedId};
  }

  String _conversationsKey(UserProfile buyer) {
    return 'chat.conversations.${offlineKeyPart(buyer.email)}';
  }

  String _pendingKey(UserProfile buyer) {
    return 'chat.pending.${offlineKeyPart(buyer.email)}';
  }

  String _localConversationId({
    required Listing listing,
    required UserProfile buyer,
  }) {
    final buyerKey = offlineKeyPart(buyer.email);
    return 'local-chat-$buyerKey-${listing.id}-${DateTime.now().microsecondsSinceEpoch}';
  }
}

class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}
