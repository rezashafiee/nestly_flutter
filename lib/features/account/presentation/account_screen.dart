import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/listing_photo.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/state/auth_controller.dart';
import '../../chat/state/chat_controller.dart';
import '../../marketplace/state/marketplace_controller.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final marketplace = context.watch<MarketplaceController>();
    final chat = context.watch<ChatController>();
    final profile = auth.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        ResponsiveContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: panelDecoration(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BrandMark(size: 64),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.name ?? 'Guest',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                Text(
                                  profile?.email ?? 'guest@nestly.app',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.mutedInk),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          MetricTile(
                            icon: Icons.storefront_outlined,
                            label: 'Listings',
                            value: '${marketplace.activeListings}',
                          ),
                          MetricTile(
                            icon: Icons.chat_bubble_outline,
                            label: 'Chats',
                            value: '${chat.conversations.length}',
                          ),
                          const MetricTile(
                            icon: Icons.verified_user_outlined,
                            label: 'Trust',
                            value: 'New',
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        onPressed: auth.signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              MyListingsSection(listings: marketplace.ownListings),
            ],
          ),
        ),
      ],
    );
  }
}

class MyListingsSection extends StatelessWidget {
  const MyListingsSection({super.key, required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'My listings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            StatusPill(
              icon: Icons.storefront_outlined,
              label: '${listings.length} active',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (listings.isEmpty)
          DecoratedBox(
            decoration: panelDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.brandBlueDeep,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your published items will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: listings.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return MyListingTile(listing: listings[index]);
              },
            ),
          ),
      ],
    );
  }
}

class MyListingTile extends StatelessWidget {
  const MyListingTile({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: double.infinity,
                child: ListingPhoto(listing: listing),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatPrice(listing.price),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.brandOrange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: SizedBox(
        width: 150,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.brandBlueDeep),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
