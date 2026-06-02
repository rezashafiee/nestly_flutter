import '../../../core/data/seed_listings.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/photo_asset.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_json_store.dart';

class ListingsRepository {
  ListingsRepository({
    NestlyApiClient? apiClient,
    OfflineJsonStore? offlineStore,
  }) : _apiClient = apiClient ?? NestlyApiClient(),
       _offlineStore = offlineStore ?? OfflineJsonStore();

  static const _listingsKey = 'marketplace.listings';
  static const _pendingListingsKey = 'marketplace.pendingListings';

  final NestlyApiClient _apiClient;
  final OfflineJsonStore _offlineStore;
  final List<Listing> _listings = [];
  bool _isUsingOfflineData = false;
  bool _hasPendingWrites = false;
  String? _syncMessage;

  List<Listing> get currentListings => List.unmodifiable(_listings);
  bool get isUsingOfflineData => _isUsingOfflineData;
  bool get hasPendingWrites => _hasPendingWrites;
  String? get syncMessage => _syncMessage;

  Future<List<Listing>> restoreListings() async {
    final cached = await _readCachedListings();
    if (cached.isEmpty) {
      await _refreshPendingState();
      return currentListings;
    }
    _replaceAll(cached);
    _isUsingOfflineData = true;
    await _refreshPendingState();
    _syncMessage = _hasPendingWrites
        ? 'Showing saved listings. Local changes will sync when you refresh.'
        : 'Showing saved listings while fresh data loads.';
    return currentListings;
  }

  Future<List<Listing>> fetchListings({bool fail = false}) async {
    if (_listings.isEmpty) {
      await restoreListings();
    }
    try {
      if (fail) {
        throw const _OfflineSyncException();
      }
      await _syncPendingListings();
      final response = await _apiClient.getJson('/api/listings');
      final listings = asJsonList(
        response,
      ).map((item) => Listing.fromJson(asJsonMap(item))).toList();
      _replaceAll(await _mergePendingLocalListings(listings));
      await _writeCachedListings(_listings);
      _isUsingOfflineData = false;
      await _refreshPendingState();
      _syncMessage = _hasPendingWrites
          ? 'Some listings are saved locally and will sync on the next refresh.'
          : null;
      return currentListings;
    } catch (_) {
      return _fallbackListings();
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
      _replaceListing(listing);
      await _writeCachedListings(_listings);
      _isUsingOfflineData = false;
      await _refreshPendingState();
      _syncMessage = null;
      return listing;
    } on ApiException catch (error) {
      throw ListingsException(error.message);
    } catch (_) {
      final listing = _localListing(input: input, seller: seller);
      _replaceListing(listing);
      await _queuePendingListing(
        listing: listing,
        input: input,
        seller: seller,
      );
      await _writeCachedListings(_listings);
      _isUsingOfflineData = true;
      _syncMessage =
          'Listing saved locally. It will publish when you refresh online.';
      return listing;
    }
  }

  Future<List<Listing>> _fallbackListings() async {
    final cached = await _readCachedListings();
    if (cached.isNotEmpty) {
      _replaceAll(cached);
      _syncMessage = 'Showing saved listings until fresh data is available.';
    } else {
      _replaceAll(seedListings());
      await _writeCachedListings(_listings);
      _syncMessage =
          'Showing starter listings until a connection is available.';
    }
    _isUsingOfflineData = true;
    await _refreshPendingState();
    if (_hasPendingWrites) {
      _syncMessage =
          'Showing saved listings. Local changes will sync when you refresh.';
    }
    return currentListings;
  }

  Future<List<Listing>> _readCachedListings() async {
    return _decodeListings(await _offlineStore.readList(_listingsKey));
  }

  List<Listing> _decodeListings(List<Object?> raw) {
    final listings = <Listing>[];
    for (final item in raw) {
      try {
        listings.add(Listing.fromJson(asJsonMap(item)));
      } catch (_) {
        // Ignore malformed cached listings.
      }
    }
    return listings;
  }

  Future<void> _writeCachedListings(List<Listing> listings) async {
    await _offlineStore.writeList(
      _listingsKey,
      listings.map((listing) => listing.toJson()).toList(),
    );
  }

  Future<void> _queuePendingListing({
    required Listing listing,
    required SellListingInput input,
    required UserProfile seller,
  }) async {
    final pending = await _readPendingListings();
    pending.add({
      'localId': listing.id,
      'listing': listing.toJson(),
      'request': _publishRequest(input: input, seller: seller),
    });
    await _writePendingListings(pending);
    _hasPendingWrites = true;
  }

  Future<void> _syncPendingListings() async {
    final pending = await _readPendingListings();
    if (pending.isEmpty) {
      _hasPendingWrites = false;
      return;
    }

    final remaining = <Map<String, Object?>>[];
    for (final item in pending) {
      try {
        final request = asJsonMap(item['request']);
        final response = await _apiClient.postJson('/api/listings', request);
        final listing = Listing.fromJson(asJsonMap(response));
        _replaceListing(listing, previousId: item['localId']?.toString());
      } catch (_) {
        remaining.add(item);
      }
    }
    await _writePendingListings(remaining);
    _hasPendingWrites = remaining.isNotEmpty;
  }

  Future<List<Map<String, Object?>>> _readPendingListings() async {
    final raw = await _offlineStore.readList(_pendingListingsKey);
    final pending = <Map<String, Object?>>[];
    for (final item in raw) {
      try {
        pending.add(asJsonMap(item));
      } catch (_) {
        // Ignore malformed pending records.
      }
    }
    return pending;
  }

  Future<void> _writePendingListings(List<Map<String, Object?>> pending) async {
    await _offlineStore.writeList(_pendingListingsKey, pending);
  }

  Future<void> _refreshPendingState() async {
    _hasPendingWrites = (await _readPendingListings()).isNotEmpty;
  }

  Future<List<Listing>> _mergePendingLocalListings(List<Listing> fresh) async {
    final pending = await _readPendingListings();
    final locals = <Listing>[];
    for (final item in pending) {
      try {
        locals.add(Listing.fromJson(asJsonMap(item['listing'])));
      } catch (_) {
        // Ignore malformed pending records.
      }
    }
    return [
      ...locals,
      ...fresh.where(
        (listing) => !locals.any((local) => local.id == listing.id),
      ),
    ];
  }

  void _replaceAll(List<Listing> listings) {
    _listings
      ..clear()
      ..addAll(listings);
  }

  void _replaceListing(Listing listing, {String? previousId}) {
    _listings.removeWhere(
      (item) =>
          item.id == listing.id ||
          (previousId != null && item.id == previousId),
    );
    _listings.insert(0, listing);
  }

  Listing _localListing({
    required SellListingInput input,
    required UserProfile seller,
  }) {
    return Listing(
      id: 'local-listing-${DateTime.now().microsecondsSinceEpoch}',
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
  }

  Map<String, Object?> _publishRequest({
    required SellListingInput input,
    required UserProfile seller,
  }) {
    return {
      'title': input.title,
      'category': input.category,
      'price': input.price,
      'condition': input.condition,
      'location': input.location,
      'description': input.description,
      'sellerName': seller.name,
      'sellerEmail': seller.email,
      'photo': input.photo.toJson(),
    };
  }
}

class _OfflineSyncException implements Exception {
  const _OfflineSyncException();
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
