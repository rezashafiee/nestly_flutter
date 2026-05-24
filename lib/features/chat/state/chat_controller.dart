import 'package:flutter/foundation.dart';

import '../../../core/models/conversation.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/state/async_status.dart';
import '../data/chat_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController(this._repository);

  final ChatRepository _repository;

  String? _activeConversationId;
  AsyncStatus _conversationStatus = AsyncStatus.idle;
  String? _conversationError;
  AsyncStatus _sendStatus = AsyncStatus.idle;
  String? _sendError;

  List<Conversation> get conversations => _repository.conversations;
  String? get activeConversationId => _activeConversationId;
  AsyncStatus get conversationStatus => _conversationStatus;
  String? get conversationError => _conversationError;
  AsyncStatus get sendStatus => _sendStatus;
  String? get sendError => _sendError;
  bool get isLoadingConversations => _conversationStatus == AsyncStatus.loading;
  bool get isSending => _sendStatus == AsyncStatus.loading;

  Conversation? get activeConversation {
    final id = _activeConversationId;
    if (id == null) {
      return conversations.isEmpty ? null : conversations.first;
    }
    for (final conversation in conversations) {
      if (conversation.id == id) {
        return conversation;
      }
    }
    return conversations.isEmpty ? null : conversations.first;
  }

  void selectConversation(String id) {
    _activeConversationId = id;
    _sendError = null;
    notifyListeners();
  }

  Future<void> refresh({required UserProfile buyer}) async {
    _conversationStatus = AsyncStatus.loading;
    _conversationError = null;
    notifyListeners();
    try {
      await _repository.fetchConversations(buyer: buyer);
      _activeConversationId ??= conversations.isEmpty
          ? null
          : conversations.first.id;
      _conversationStatus = AsyncStatus.success;
    } on ChatException catch (error) {
      _conversationStatus = AsyncStatus.failure;
      _conversationError = error.message;
    } catch (_) {
      _conversationStatus = AsyncStatus.failure;
      _conversationError = 'Conversations are unavailable right now.';
    }
    notifyListeners();
  }

  Future<bool> startConversation({
    required Listing listing,
    required UserProfile buyer,
  }) async {
    _conversationStatus = AsyncStatus.loading;
    _conversationError = null;
    _sendError = null;
    notifyListeners();
    try {
      final conversation = await _repository.startConversation(
        listing: listing,
        buyer: buyer,
      );
      _activeConversationId = conversation.id;
      _conversationStatus = AsyncStatus.success;
      notifyListeners();
      return true;
    } on ChatException catch (error) {
      _conversationStatus = AsyncStatus.failure;
      _conversationError = error.message;
    } catch (_) {
      _conversationStatus = AsyncStatus.failure;
      _conversationError = 'Conversation could not be started.';
    }
    notifyListeners();
    return false;
  }

  Future<void> sendMessage({
    required UserProfile author,
    required String body,
  }) async {
    final trimmed = body.trim();
    _sendError = null;
    if (trimmed.isEmpty) {
      _sendStatus = AsyncStatus.failure;
      _sendError = 'Type a message before sending.';
      notifyListeners();
      return;
    }
    final conversationId = activeConversation?.id;
    if (conversationId == null) {
      _sendStatus = AsyncStatus.failure;
      _sendError = 'Choose a conversation first.';
      notifyListeners();
      return;
    }

    _sendStatus = AsyncStatus.loading;
    notifyListeners();
    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        author: author,
        body: trimmed,
      );
      _sendStatus = AsyncStatus.success;
    } on ChatException catch (error) {
      _sendStatus = AsyncStatus.failure;
      _sendError = error.message;
    } catch (_) {
      _sendStatus = AsyncStatus.failure;
      _sendError = 'Message could not be sent.';
    }
    notifyListeners();
  }
}
