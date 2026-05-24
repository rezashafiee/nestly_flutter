import '../models/listing.dart';
import '../models/photo_asset.dart';
import 'photo_assets.dart';

List<Listing> seedListings() {
  final now = DateTime.now();
  return [
    Listing(
      id: 'listing-desk',
      title: 'Vintage oak desk',
      category: 'Furniture',
      price: 180,
      condition: 'Good',
      location: 'Prenzlauer Berg',
      description: 'Solid oak writing desk with three drawers and brass pulls.',
      sellerName: 'Maya',
      createdAt: now.subtract(const Duration(hours: 3)),
      photo: const PhotoAsset(iconKey: 'desk', colorValue: 0xFFB7E4C7),
      likes: 28,
    ),
    Listing(
      id: 'listing-bike',
      title: 'City bike with basket',
      category: 'Sports',
      price: 240,
      condition: 'Like new',
      location: 'Mitte',
      description:
          'Lightweight commuter bike, tuned this month, includes lock.',
      sellerName: 'Jonas',
      createdAt: now.subtract(const Duration(hours: 7)),
      photo: PhotoAssets.forCategory('Sports'),
      likes: 44,
    ),
    Listing(
      id: 'listing-lamp',
      title: 'Warm ceramic lamp',
      category: 'Home',
      price: 65,
      condition: 'New',
      location: 'Kreuzberg',
      description: 'Handmade lamp with dimmable bulb and linen shade.',
      sellerName: 'Elena',
      createdAt: now.subtract(const Duration(days: 1)),
      photo: PhotoAssets.forCategory('Home'),
      likes: 19,
    ),
    Listing(
      id: 'listing-headphones',
      title: 'Noise cancelling headphones',
      category: 'Electronics',
      price: 120,
      condition: 'Good',
      location: 'Friedrichshain',
      description: 'Comfortable over-ear headphones with case and cable.',
      sellerName: 'Amir',
      createdAt: now.subtract(const Duration(days: 2)),
      photo: PhotoAssets.forCategory('Electronics'),
      likes: 33,
    ),
  ];
}
