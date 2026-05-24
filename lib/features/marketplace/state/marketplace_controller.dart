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
  String _query = '';
  String _category = 'All';
  String _condition = 'Any';
  ListingSort _sort = ListingSort.newest;

  List<Listing> get listings => List.unmodifiable(_listings);
  AsyncStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String get category => _category;
  String get condition => _condition;
  ListingSort get sort => _sort;
  bool get isLoading => _status == AsyncStatus.loading;

  List<String> get categories => [
    'All',
    ...{for (final listing in _listings) listing.category},
  ];

  List<Listing> get filteredListings {
    final search = _query.trim().toLowerCase();
    final filtered = _listings.where((listing) {
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

  int get activeListings => _listings.where((listing) => listing.isMine).length;

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

  Future<void> refresh({bool fail = false}) async {
    _status = AsyncStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _listings = await _repository.fetchListings(fail: fail);
      _status = AsyncStatus.success;
    } on ListingsException catch (error) {
      _status = AsyncStatus.failure;
      _errorMessage = error.message;
    } catch (_) {
      _status = AsyncStatus.failure;
      _errorMessage = 'Listings are unavailable right now.';
    }
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
    notifyListeners();
    return listing;
  }
}
