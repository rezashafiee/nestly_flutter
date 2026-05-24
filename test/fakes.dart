import 'package:nestly/core/data/photo_assets.dart';
import 'package:nestly/core/data/seed_listings.dart';
import 'package:nestly/core/models/chat_message.dart';
import 'package:nestly/core/models/conversation.dart';
import 'package:nestly/core/models/listing.dart';
import 'package:nestly/core/models/photo_asset.dart';
import 'package:nestly/core/models/user_profile.dart';
import 'package:nestly/features/auth/data/auth_repository.dart';
import 'package:nestly/features/chat/data/chat_repository.dart';
import 'package:nestly/features/marketplace/data/listings_repository.dart';
import 'package:nestly/features/sell/data/photo_repository.dart';

class FakeAuthRepository extends AuthRepository {
  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (email.toLowerCase().contains('locked')) {
      throw const AuthException(
        'This account is temporarily locked. Try another sign-in method.',
      );
    }
    return UserProfile(name: _nameFromEmail(email), email: email);
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    return const UserProfile(
      name: 'Google User',
      email: 'google.user@nestly.app',
    );
  }

  String _nameFromEmail(String email) {
    final name = email.split('@').first.replaceAll('.', ' ').trim();
    if (name.isEmpty) {
      return 'Nestly User';
    }
    return name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class FakeListingsRepository extends ListingsRepository {
  final List<Listing> _items = seedListings();

  @override
  List<Listing> get currentListings => List.unmodifiable(_items);

  @override
  Future<List<Listing>> fetchListings({bool fail = false}) async {
    if (fail) {
      throw const ListingsException(
        'We could not load fresh listings. Check your connection and try again.',
      );
    }
    return currentListings;
  }

  @override
  Future<Listing> publishListing({
    required SellListingInput input,
    required UserProfile seller,
  }) async {
    if (input.price > 50000) {
      throw const ListingsException(
        'That price looks unusually high. Please review it before publishing.',
      );
    }
    final listing = Listing(
      id: 'listing-${DateTime.now().microsecondsSinceEpoch}',
      title: input.title,
      category: input.category,
      price: input.price,
      condition: input.condition,
      location: input.location,
      description: input.description,
      sellerName: seller.name,
      createdAt: DateTime.now(),
      photo: input.photo,
      likes: 0,
      isMine: true,
    );
    _items.insert(0, listing);
    return listing;
  }
}

class FakeChatRepository extends ChatRepository {
  final List<Conversation> _items = [];

  @override
  List<Conversation> get conversations => List.unmodifiable(_items);

  @override
  Future<List<Conversation>> fetchConversations({
    required UserProfile buyer,
  }) async {
    return conversations;
  }

  @override
  Future<Conversation> startConversation({
    required Listing listing,
    required UserProfile buyer,
  }) async {
    final existing = _items.where((chat) => chat.listing.id == listing.id);
    if (existing.isNotEmpty) {
      return existing.first;
    }
    final conversation = Conversation(
      id: 'chat-${listing.id}',
      listing: listing,
      messages: [
        ChatMessage(
          authorName: listing.sellerName,
          body:
              'Hi, ${buyer.name}. Happy to answer questions about the ${listing.title}.',
          sentAt: DateTime.now().subtract(const Duration(minutes: 4)),
          fromCurrentUser: false,
        ),
      ],
    );
    _items.insert(0, conversation);
    return conversation;
  }

  @override
  Future<Conversation> sendMessage({
    required String conversationId,
    required UserProfile author,
    required String body,
  }) async {
    final index = _items.indexWhere((chat) => chat.id == conversationId);
    if (index == -1) {
      throw const ChatException('Choose a conversation first.');
    }
    final current = _items[index];
    final updated = current.copyWith(
      messages: [
        ...current.messages,
        ChatMessage(
          authorName: author.name,
          body: body,
          sentAt: DateTime.now(),
          fromCurrentUser: true,
        ),
      ],
    );
    _items[index] = updated;
    return updated;
  }
}

class FakePhotoRepository extends PhotoRepository {
  @override
  Future<PhotoAsset> captureForCategory(String category) async {
    return PhotoAssets.forCategory(category);
  }
}
