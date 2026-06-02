import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nestly/core/models/chat_message.dart';
import 'package:nestly/core/models/conversation.dart';
import 'package:nestly/core/models/listing.dart';
import 'package:nestly/core/models/photo_asset.dart';
import 'package:nestly/core/models/user_profile.dart';
import 'package:nestly/core/network/api_client.dart';
import 'package:nestly/core/offline/offline_json_store.dart';
import 'package:nestly/features/chat/data/chat_repository.dart';
import 'package:nestly/features/marketplace/data/listings_repository.dart';

void main() {
  const baseUri = 'http://nestly.test';
  const buyer = UserProfile(name: 'Sara', email: 'sara@example.com');
  const photo = PhotoAsset(iconKey: 'chair', colorValue: 0xFFB7E4C7);

  NestlyApiClient clientFor(MockClient client) {
    return NestlyApiClient(httpClient: client, baseUri: Uri.parse(baseUri));
  }

  test(
    'listings repository falls back to cached listings when offline',
    () async {
      final store = OfflineJsonStore.inMemory();
      final onlineRepository = ListingsRepository(
        apiClient: clientFor(
          MockClient((request) async {
            expect(request.method, 'GET');
            return http.Response(
              jsonEncode([
                _listingJson(id: 'server-desk', title: 'Cached desk'),
              ]),
              200,
            );
          }),
        ),
        offlineStore: store,
      );

      await onlineRepository.fetchListings();

      final offlineRepository = ListingsRepository(
        apiClient: clientFor(
          MockClient((request) async {
            throw http.ClientException('offline', request.url);
          }),
        ),
        offlineStore: store,
      );

      final listings = await offlineRepository.fetchListings();

      expect(listings.single.title, 'Cached desk');
      expect(offlineRepository.isUsingOfflineData, isTrue);
      expect(offlineRepository.syncMessage, contains('saved listings'));
    },
  );

  test(
    'listings repository queues offline publish and syncs on refresh',
    () async {
      final store = OfflineJsonStore.inMemory();
      final offlineRepository = ListingsRepository(
        apiClient: clientFor(
          MockClient((request) async {
            throw http.ClientException('offline', request.url);
          }),
        ),
        offlineStore: store,
      );

      final localListing = await offlineRepository.publishListing(
        input: const SellListingInput(
          title: 'Cozy reading chair',
          category: 'Furniture',
          price: 95,
          condition: 'Good',
          location: 'Berlin',
          description: 'Comfortable chair with clean fabric.',
          photo: photo,
        ),
        seller: buyer,
      );

      expect(localListing.id, startsWith('local-listing-'));
      expect(localListing.isMine, isTrue);
      expect(offlineRepository.hasPendingWrites, isTrue);

      var publishCalls = 0;
      final syncedListing = _listingJson(
        id: 'server-chair',
        title: 'Cozy reading chair',
        isMine: true,
      );
      final onlineRepository = ListingsRepository(
        apiClient: clientFor(
          MockClient((request) async {
            if (request.method == 'POST') {
              publishCalls += 1;
              expect(request.url.path, '/api/listings');
              return http.Response(jsonEncode(syncedListing), 201);
            }
            if (request.method == 'GET') {
              return http.Response(jsonEncode([syncedListing]), 200);
            }
            return http.Response('Not found', 404);
          }),
        ),
        offlineStore: store,
      );

      final listings = await onlineRepository.fetchListings();

      expect(publishCalls, 1);
      expect(listings.single.id, 'server-chair');
      expect(onlineRepository.hasPendingWrites, isFalse);
      expect(onlineRepository.isUsingOfflineData, isFalse);
    },
  );

  test(
    'chat repository queues local chat and message before syncing',
    () async {
      final store = OfflineJsonStore.inMemory();
      final listing = Listing.fromJson(_listingJson());
      final offlineRepository = ChatRepository(
        apiClient: clientFor(
          MockClient((request) async {
            throw http.ClientException('offline', request.url);
          }),
        ),
        offlineStore: store,
      );

      final localConversation = await offlineRepository.startConversation(
        listing: listing,
        buyer: buyer,
      );
      await offlineRepository.sendMessage(
        conversationId: localConversation.id,
        author: buyer,
        body: 'Is this still available?',
      );

      expect(localConversation.id, startsWith('local-chat-'));
      expect(
        offlineRepository.conversations.single.messages.single.body,
        'Is this still available?',
      );
      expect(offlineRepository.hasPendingWrites, isTrue);

      final serverConversation = Conversation(
        id: 'server-chat',
        listing: listing,
        messages: const [],
      );
      final serverConversationWithMessage = serverConversation.copyWith(
        messages: [
          ChatMessage(
            authorName: buyer.name,
            body: 'Is this still available?',
            sentAt: DateTime(2026, 1, 2, 12),
            fromCurrentUser: true,
          ),
        ],
      );
      final postPaths = <String>[];
      final onlineRepository = ChatRepository(
        apiClient: clientFor(
          MockClient((request) async {
            if (request.method == 'POST') {
              postPaths.add(request.url.path);
            }
            if (request.method == 'POST' &&
                request.url.path == '/api/conversations') {
              return http.Response(
                jsonEncode(serverConversation.toJson()),
                201,
              );
            }
            if (request.method == 'POST' &&
                request.url.path == '/api/conversations/server-chat/messages') {
              return http.Response(
                jsonEncode(serverConversationWithMessage.toJson()),
                201,
              );
            }
            if (request.method == 'GET' &&
                request.url.path == '/api/conversations') {
              return http.Response(
                jsonEncode([serverConversationWithMessage.toJson()]),
                200,
              );
            }
            return http.Response(jsonEncode({'message': 'Not found'}), 404);
          }),
        ),
        offlineStore: store,
      );

      final conversations = await onlineRepository.fetchConversations(
        buyer: buyer,
      );

      expect(postPaths, [
        '/api/conversations',
        '/api/conversations/server-chat/messages',
      ]);
      expect(conversations.single.id, 'server-chat');
      expect(
        conversations.single.messages.single.body,
        'Is this still available?',
      );
      expect(onlineRepository.hasPendingWrites, isFalse);
    },
  );
}

Map<String, Object?> _listingJson({
  String id = 'listing-desk',
  String title = 'Vintage oak desk',
  bool isMine = false,
}) {
  return {
    'id': id,
    'title': title,
    'category': 'Furniture',
    'price': 180,
    'condition': 'Good',
    'location': 'Berlin',
    'description': 'Solid oak writing desk with three drawers.',
    'sellerName': 'Maya',
    'createdAt': DateTime(2026, 1, 1, 12).toUtc().toIso8601String(),
    'photo': {'iconKey': 'desk', 'colorValue': 0xFFB7E4C7},
    'likes': 28,
    'isMine': isMine,
  };
}
