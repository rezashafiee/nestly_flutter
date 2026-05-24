import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_router.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/listing_photo.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/state/auth_controller.dart';
import '../../chat/state/chat_controller.dart';
import '../state/listing_sort.dart';
import '../state/marketplace_controller.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<MarketplaceController>().updateQuery(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = context.read<MarketplaceController>();
      if (controller.listings.isEmpty) {
        unawaited(controller.refresh());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startChat(Listing listing) async {
    final profile = context.read<AuthController>().profile;
    if (profile == null) {
      return;
    }
    final chat = context.read<ChatController>();
    final started = await chat.startConversation(
      listing: listing,
      buyer: profile,
    );
    if (!mounted) {
      return;
    }
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chat.conversationError ?? 'Could not start chat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.go(AppRoutes.chat);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    final listings = controller.filteredListings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        ResponsiveContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browse marketplace',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${controller.listings.length} nearby listings ready for pickup.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.mutedInk,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.refresh(),
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Show offline state',
                    onPressed: controller.isLoading
                        ? null
                        : () => controller.refresh(fail: true),
                    icon: const Icon(Icons.cloud_off_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items, neighborhoods, categories',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in controller.categories)
                    FilterChip(
                      label: Text(category),
                      selected: controller.category == category,
                      onSelected: (_) => controller.updateCategory(category),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              MarketplaceFilters(controller: controller),
              const SizedBox(height: 22),
              if (controller.isLoading)
                const LoadingState(
                  title: 'Loading listings',
                  message: 'Finding the freshest items near you.',
                )
              else if (controller.errorMessage != null)
                ErrorState(
                  title: 'Listings unavailable',
                  message: controller.errorMessage!,
                  actionLabel: 'Retry',
                  onAction: controller.refresh,
                )
              else if (listings.isEmpty)
                EmptyState(
                  icon: Icons.search_off,
                  title: 'No matches found',
                  message: 'Try a broader search or remove a filter.',
                  actionLabel: 'Clear filters',
                  onAction: () {
                    _searchController.clear();
                    controller.clearFilters();
                  },
                )
              else
                MarketplaceGrid(listings: listings, onStartChat: _startChat),
            ],
          ),
        ),
      ],
    );
  }
}

class MarketplaceFilters extends StatelessWidget {
  const MarketplaceFilters({super.key, required this.controller});

  final MarketplaceController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final conditionDropdown = DropdownButtonFormField<String>(
          initialValue: controller.condition,
          decoration: const InputDecoration(
            labelText: 'Condition',
            prefixIcon: Icon(Icons.verified_outlined),
          ),
          items: const ['Any', 'New', 'Like new', 'Good']
              .map(
                (condition) =>
                    DropdownMenuItem(value: condition, child: Text(condition)),
              )
              .toList(),
          onChanged: (value) => controller.updateCondition(value ?? 'Any'),
        );

        final sortControl = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<ListingSort>(
            selected: {controller.sort},
            onSelectionChanged: (selection) {
              controller.updateSort(selection.first);
            },
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ListingSort.newest,
                icon: Icon(Icons.schedule),
                label: Text('Newest'),
              ),
              ButtonSegment(
                value: ListingSort.priceLow,
                icon: Icon(Icons.south),
                label: Text('Low'),
              ),
              ButtonSegment(
                value: ListingSort.priceHigh,
                icon: Icon(Icons.north),
                label: Text('High'),
              ),
              ButtonSegment(
                value: ListingSort.popular,
                icon: Icon(Icons.favorite_border),
                label: Text('Liked'),
              ),
            ],
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              conditionDropdown,
              const SizedBox(height: 12),
              sortControl,
            ],
          );
        }

        return Row(
          children: [
            SizedBox(width: 260, child: conditionDropdown),
            const SizedBox(width: 14),
            Expanded(child: sortControl),
          ],
        );
      },
    );
  }
}

class MarketplaceGrid extends StatelessWidget {
  const MarketplaceGrid({
    super.key,
    required this.listings,
    required this.onStartChat,
  });

  final List<Listing> listings;
  final Future<void> Function(Listing listing) onStartChat;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listings.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 1.25 : 0.82,
          ),
          itemBuilder: (context, index) {
            return ListingCard(
              listing: listings[index],
              onStartChat: () {
                unawaited(onStartChat(listings[index]));
              },
            );
          },
        );
      },
    );
  }
}

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onStartChat,
  });

  final Listing listing;
  final VoidCallback onStartChat;

  void _openDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: ResponsiveContent(
              maxWidth: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListingPhoto(listing: listing, height: 250),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(
                        icon: Icons.category_outlined,
                        label: listing.category,
                      ),
                      StatusPill(
                        icon: Icons.verified_outlined,
                        label: listing.condition,
                      ),
                      StatusPill(
                        icon: Icons.place_outlined,
                        label: listing.location,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    listing.title,
                    style: Theme.of(sheetContext).textTheme.headlineSmall
                        ?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatPrice(listing.price),
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    listing.description,
                    style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedInk,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SellerRow(listing: listing),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            onStartChat();
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Chat'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ListingPhoto(listing: listing)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatPrice(listing.price),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.brandOrange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  listing.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusPill(
                      icon: Icons.verified_outlined,
                      label: listing.condition,
                    ),
                    StatusPill(
                      icon: Icons.place_outlined,
                      label: listing.location,
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: SellerRow(listing: listing, compact: true)),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Chat with seller',
                      onPressed: onStartChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SellerRow extends StatelessWidget {
  const SellerRow({super.key, required this.listing, this.compact = false});

  final Listing listing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: compact ? 14 : 18,
          backgroundColor: AppColors.brandOrange.withValues(alpha: 0.18),
          child: Text(
            listing.sellerName.characters.first.toUpperCase(),
            style: TextStyle(
              color: AppColors.brandOrange,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                listing.sellerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!compact)
                Text(
                  'Usually replies quickly',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedInk),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
