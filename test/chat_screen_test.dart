import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/core/models/chat_message.dart';
import 'package:nestly/core/models/conversation.dart';
import 'package:nestly/core/models/listing.dart';
import 'package:nestly/core/models/photo_asset.dart';
import 'package:nestly/core/theme/app_theme.dart';
import 'package:nestly/features/chat/presentation/chat_screen.dart';

void main() {
  testWidgets('chat message bubbles keep vertical spacing', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    final conversation = Conversation(
      id: 'chat-1',
      listing: Listing(
        id: 'listing-1',
        title: 'Walnut side table',
        category: 'Furniture',
        price: 80,
        condition: 'Good',
        location: 'Berlin',
        description: 'Compact side table with a lower shelf.',
        sellerName: 'Mila',
        createdAt: DateTime(2026),
        photo: const PhotoAsset(iconKey: 'chair', colorValue: 0xFF8FD8F7),
        likes: 3,
      ),
      messages: [
        ChatMessage(
          authorName: 'Mila',
          body: 'Still available.',
          sentAt: DateTime(2026, 1, 1, 9),
          fromCurrentUser: false,
        ),
        ChatMessage(
          authorName: 'Sara',
          body: 'Great, can I pick it up today?',
          sentAt: DateTime(2026, 1, 1, 9, 5),
          fromCurrentUser: true,
        ),
        ChatMessage(
          authorName: 'Sara',
          body: 'Evening works best.',
          sentAt: DateTime(2026, 1, 1, 9, 6),
          fromCurrentUser: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildNestlyTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ChatDetail(
              conversation: conversation,
              controller: controller,
              sendError: null,
              sending: false,
              onSend: () {},
            ),
          ),
        ),
      ),
    );

    final first = tester.getRect(
      find.byKey(const ValueKey('chatMessageBubble_0')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey('chatMessageBubble_1')),
    );
    final third = tester.getRect(
      find.byKey(const ValueKey('chatMessageBubble_2')),
    );

    expect(second.top - first.bottom, greaterThanOrEqualTo(12));
    expect(third.top - second.bottom, greaterThanOrEqualTo(8));
  });
}
