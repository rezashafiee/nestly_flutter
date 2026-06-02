import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/conversation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/listing_photo.dart';
import '../../../core/widgets/states.dart';
import '../../auth/state/auth_controller.dart';
import '../state/chat_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final profile = context.read<AuthController>().profile;
      final chat = context.read<ChatController>();
      if (profile != null && chat.conversations.isEmpty) {
        unawaited(chat.refresh(buyer: profile));
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send(ChatController chat) async {
    final profile = context.read<AuthController>().profile;
    if (profile == null) {
      return;
    }
    final body = _messageController.text;
    await chat.sendMessage(author: profile, body: body);
    if (!mounted || chat.sendError != null) {
      return;
    }
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final profile = context.watch<AuthController>().profile;
    final syncBanner = chat.syncMessage == null
        ? null
        : InfoBanner(
            message: chat.syncMessage!,
            icon: chat.hasPendingWrites
                ? Icons.sync_problem_outlined
                : Icons.cloud_off_outlined,
          );
    if (chat.isLoadingConversations && chat.conversations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: const [
          ResponsiveContent(
            child: LoadingState(
              title: 'Loading chats',
              message: 'Finding your latest conversations.',
            ),
          ),
        ],
      );
    }
    if (chat.conversationError != null && chat.conversations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          ResponsiveContent(
            child: ErrorState(
              title: 'Chats unavailable',
              message: chat.conversationError!,
              actionLabel: 'Retry',
              onAction: profile == null
                  ? null
                  : () => unawaited(chat.refresh(buyer: profile)),
            ),
          ),
        ],
      );
    }
    if (chat.conversations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          ResponsiveContent(
            child: Column(
              children: [
                if (syncBanner != null) ...[
                  syncBanner,
                  const SizedBox(height: 16),
                ],
                const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No chats yet',
                  message:
                      'Open an item and start a conversation with the seller.',
                ),
              ],
            ),
          ),
        ],
      );
    }

    final selected = chat.activeConversation ?? chat.conversations.first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 780;
        final list = ConversationList(
          conversations: chat.conversations,
          selectedId: selected.id,
          onSelected: chat.selectConversation,
        );
        final detail = ChatDetail(
          conversation: selected,
          controller: _messageController,
          sendError: chat.sendError,
          sending: chat.isSending,
          onSend: () => _send(chat),
        );

        if (wide) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ResponsiveContent(
              maxWidth: 1120,
              child: Column(
                children: [
                  if (syncBanner != null) ...[
                    syncBanner,
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(width: 330, child: list),
                        const SizedBox(width: 16),
                        Expanded(child: detail),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (syncBanner != null) ...[
                syncBanner,
                const SizedBox(height: 12),
              ],
              SizedBox(height: 146, child: list),
              const SizedBox(height: 16),
              Expanded(child: detail),
            ],
          ),
        );
      },
    );
  }
}

class ConversationList extends StatelessWidget {
  const ConversationList({
    super.key,
    required this.conversations,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Conversation> conversations;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.of(context).size.width < 780;
    return DecoratedBox(
      decoration: panelDecoration(),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          final selected = conversation.id == selectedId;
          final preview = conversation.messages.isEmpty
              ? 'Chat saved locally'
              : conversation.messages.last.body;
          return SizedBox(
            width: horizontal ? 260 : null,
            child: Material(
              color: selected
                  ? AppColors.brandBlue.withValues(alpha: 0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSelected(conversation.id),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: ListingPhoto(listing: conversation.listing),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              conversation.listing.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.mutedInk),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 8, width: 8),
        itemCount: conversations.length,
      ),
    );
  }
}

class ChatDetail extends StatelessWidget {
  const ChatDetail({
    super.key,
    required this.conversation,
    required this.controller,
    required this.sendError,
    required this.sending,
    required this.onSend,
  });

  final Conversation conversation;
  final TextEditingController controller;
  final String? sendError;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: panelDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: ListingPhoto(listing: conversation.listing),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        '${conversation.listing.sellerName} · ${formatPrice(conversation.listing.price)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: conversation.messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    itemCount: conversation.messages.length,
                    itemBuilder: (context, index) {
                      final message = conversation.messages[index];
                      return Align(
                        alignment: message.fromCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: DecoratedBox(
                            key: ValueKey('chatMessageBubble_$index'),
                            decoration: BoxDecoration(
                              color: message.fromCurrentUser
                                  ? AppColors.brandBlueDeep
                                  : const Color(0xFFF0F5F8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Text(
                                message.body,
                                style: TextStyle(
                                  color: message.fromCurrentUser
                                      ? Colors.white
                                      : AppColors.ink,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      final current = conversation.messages[index];
                      final next = conversation.messages[index + 1];
                      final sameSender =
                          current.fromCurrentUser == next.fromCurrentUser;
                      return SizedBox(height: sameSender ? 8 : 12);
                    },
                  ),
          ),
          if (sendError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ErrorBanner(message: sendError!),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !sending,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Message seller',
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                    onSubmitted: (_) => sending ? null : onSend(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: 'Send',
                  onPressed: sending ? null : onSend,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
