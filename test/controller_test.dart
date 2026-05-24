import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/core/data/photo_assets.dart';
import 'package:nestly/core/models/user_profile.dart';
import 'package:nestly/features/chat/state/chat_controller.dart';
import 'package:nestly/features/marketplace/data/listings_repository.dart';
import 'package:nestly/features/marketplace/state/marketplace_controller.dart';

import 'fakes.dart';

void main() {
  test(
    'marketplace controller filters listings and publishes new items',
    () async {
      final controller = MarketplaceController(FakeListingsRepository());
      await controller.refresh();

      controller.updateQuery('bike');
      expect(controller.filteredListings.single.title, 'City bike with basket');

      final listing = await controller.publishListing(
        input: SellListingInput(
          title: 'Cozy reading chair',
          category: 'Furniture',
          price: 95,
          condition: 'Good',
          location: 'Berlin',
          description: 'Comfortable chair with clean fabric.',
          photo: PhotoAssets.forCategory('Furniture'),
        ),
        seller: const UserProfile(name: 'Sara', email: 'sara@example.com'),
      );

      expect(listing.isMine, isTrue);
      expect(controller.listings.first.title, 'Cozy reading chair');
    },
  );

  test('chat controller starts conversations and sends messages', () async {
    final marketplace = MarketplaceController(FakeListingsRepository());
    await marketplace.refresh();
    final chat = ChatController(FakeChatRepository());
    final buyer = const UserProfile(name: 'Sara', email: 'sara@example.com');
    final listing = marketplace.listings.first;

    final started = await chat.startConversation(
      listing: listing,
      buyer: buyer,
    );
    expect(started, isTrue);
    expect(chat.conversations, hasLength(1));
    expect(chat.activeConversation?.listing.id, listing.id);

    await chat.sendMessage(author: buyer, body: 'Is this still available?');

    expect(chat.sendError, isNull);
    expect(
      chat.activeConversation?.messages.last.body,
      'Is this still available?',
    );
  });
}
