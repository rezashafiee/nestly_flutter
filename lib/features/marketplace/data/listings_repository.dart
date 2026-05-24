import '../../../core/models/listing.dart';
import '../../../core/models/photo_asset.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/api_client.dart';

class ListingsRepository {
  ListingsRepository({NestlyApiClient? apiClient})
    : _apiClient = apiClient ?? NestlyApiClient();

  final NestlyApiClient _apiClient;
  final List<Listing> _listings = [];

  List<Listing> get currentListings => List.unmodifiable(_listings);

  Future<List<Listing>> fetchListings({bool fail = false}) async {
    if (fail) {
      throw const ListingsException(
        'We could not load fresh listings. Check your connection and try again.',
      );
    }
    try {
      final response = await _apiClient.getJson('/api/listings');
      final listings = asJsonList(
        response,
      ).map((item) => Listing.fromJson(asJsonMap(item))).toList();
      _listings
        ..clear()
        ..addAll(listings);
      return currentListings;
    } on ApiException catch (error) {
      throw ListingsException(error.message);
    } catch (_) {
      throw const ListingsException('Listings are unavailable right now.');
    }
  }

  Future<Listing> publishListing({
    required SellListingInput input,
    required UserProfile seller,
  }) async {
    if (input.price > 50000) {
      throw const ListingsException(
        'That price looks unusually high. Please review it before publishing.',
      );
    }

    try {
      final response = await _apiClient.postJson('/api/listings', {
        'title': input.title,
        'category': input.category,
        'price': input.price,
        'condition': input.condition,
        'location': input.location,
        'description': input.description,
        'sellerName': seller.name,
        'sellerEmail': seller.email,
        'photo': input.photo.toJson(),
      });
      final listing = Listing.fromJson(asJsonMap(response));
      _listings.removeWhere((item) => item.id == listing.id);
      _listings.insert(0, listing);
      return listing;
    } on ApiException catch (error) {
      throw ListingsException(error.message);
    } catch (_) {
      throw const ListingsException('Listing could not be published.');
    }
  }
}

class SellListingInput {
  const SellListingInput({
    required this.title,
    required this.category,
    required this.price,
    required this.condition,
    required this.location,
    required this.description,
    required this.photo,
  });

  final String title;
  final String category;
  final double price;
  final String condition;
  final String location;
  final String description;
  final PhotoAsset photo;
}

class ListingsException implements Exception {
  const ListingsException(this.message);

  final String message;

  @override
  String toString() => message;
}

PhotoAsset defaultListingPhoto(String category) => switch (category) {
  'Electronics' => const PhotoAsset(
    iconKey: 'electronics',
    colorValue: 0xFFCDB4DB,
  ),
  'Home' => const PhotoAsset(iconKey: 'lamp', colorValue: 0xFFFFC6D9),
  'Sports' => const PhotoAsset(iconKey: 'bike', colorValue: 0xFFFFD6A5),
  'Clothing' => const PhotoAsset(iconKey: 'clothing', colorValue: 0xFFA0C4FF),
  _ => const PhotoAsset(iconKey: 'chair', colorValue: 0xFFB7E4C7),
};
