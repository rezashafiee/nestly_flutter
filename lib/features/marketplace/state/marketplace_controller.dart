import 'package:flutter/foundation.dart';

import '../../../core/models/listing.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/state/async_status.dart';
import '../data/listings_repository.dart';
import 'listing_sort.dart';

class MarketplaceController extends ChangeNotifier {
  MarketplaceController(this._repository)
    : _listings = _repository.currentListings;

  final ListingsRepository _repository;

  List<Listing> _listings;
  AsyncStatus _status = AsyncStatus.idle;
  String? _errorMessage;
  String? _syncMessage;
  String _query = '';
  String _category = 'All';
  String _condition = 'Any';
  ListingSort _sort = ListingSort.newest;
  bool _isRefreshing = false;
  bool _isUsingOfflineData = false;
  bool _hasPendingWrites = false;

  List<Listing> get listings => List.unmodifiable(_listings);
  AsyncStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get syncMessage => _syncMessage;
  String get query => _query;
  String get category => _category;
  String get condition => _condition;
  ListingSort get sort => _sort;
  bool get isLoading => _status == AsyncStatus.loading && _listings.isEmpty;
  bool get isRefreshing => _isRefreshing;
  bool get isUsingOfflineData => _isUsingOfflineData;
  bool get hasPendingWrites => _hasPendingWrites;
  List<Listing> get browseListings =>
      _listings.where((listing) => !listing.isMine).toList(growable: false);
  List<Listing> get ownListings =>
      _listings.where((listing) => listing.isMine).toList(growable: false);

  List<String> get categories => [
    'All',
    ...{for (final listing in browseListings) listing.category},
  ];

  List<Listing> get filteredListings {
    final search = _query.trim().toLowerCase();
    final filtered = browseListings.where((listing) {
      final matchesSearch =
          search.isEmpty ||
          listing.title.toLowerCase().contains(search) ||
          listing.description.toLowerCase().contains(search) ||
          listing.location.toLowerCase().contains(search) ||
          listing.category.toLowerCase().contains(search);
      final matchesCategory =
          _category == 'All' || listing.category == _category;
      final matchesCondition =
          _condition == 'Any' || listing.condition == _condition;
      return matchesSearch && matchesCategory && matchesCondition;
    }).toList();

    switch (_sort) {
      case ListingSort.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ListingSort.priceLow:
        filtered.sort((a, b) => a.price.compareTo(b.price));
      case ListingSort.priceHigh:
        filtered.sort((a, b) => b.price.compareTo(a.price));
      case ListingSort.popular:
        filtered.sort((a, b) => b.likes.compareTo(a.likes));
    }

    return filtered;
  }

  int get activeListings => ownListings.length;

  void updateQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void updateCategory(String category) {
    _category = category;
    notifyListeners();
  }

  void updateCondition(String condition) {
    _condition = condition;
    notifyListeners();
  }

  void updateSort(ListingSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _category = 'All';
    _condition = 'Any';
    notifyListeners();
  }

  Future<void> refresh({UserProfile? viewer, bool fail = false}) async {
    _isRefreshing = true;
    _status = _listings.isEmpty ? AsyncStatus.loading : AsyncStatus.success;
    _errorMessage = null;
    notifyListeners();

    final restored = await _repository.restoreListings(viewer: viewer);
    if (restored.isNotEmpty && _listings.isEmpty) {
      _listings = restored;
      _status = AsyncStatus.success;
      _applyRepositoryState();
      notifyListeners();
    }

    try {
      _listings = await _repository.fetchListings(viewer: viewer, fail: fail);
      _status = AsyncStatus.success;
      _errorMessage = null;
    } on ListingsException catch (error) {
      _status = AsyncStatus.failure;
      _errorMessage = error.message;
    } catch (_) {
      _status = AsyncStatus.failure;
      _errorMessage = 'Listings are unavailable right now.';
    }
    _isRefreshing = false;
    _applyRepositoryState();
    notifyListeners();
  }

  Future<Listing> publishListing({
    required SellListingInput input,
    required UserProfile seller,
  }) async {
    final listing = await _repository.publishListing(
      input: input,
      seller: seller,
    );
    _listings = _repository.currentListings;
    _applyRepositoryState();
    notifyListeners();
    return listing;
  }

  void _applyRepositoryState() {
    _isUsingOfflineData = _repository.isUsingOfflineData;
    _hasPendingWrites = _repository.hasPendingWrites;
    _syncMessage = _repository.syncMessage;
  }
}
