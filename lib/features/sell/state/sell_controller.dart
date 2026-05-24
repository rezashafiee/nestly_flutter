import 'package:flutter/foundation.dart';

import '../../../core/models/photo_asset.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/state/async_status.dart';
import '../../marketplace/data/listings_repository.dart';
import '../../marketplace/state/marketplace_controller.dart';
import '../data/photo_repository.dart';

class SellController extends ChangeNotifier {
  SellController(this._photoRepository, this._marketplaceController);

  final PhotoRepository _photoRepository;
  final MarketplaceController _marketplaceController;

  int _step = 0;
  AsyncStatus _photoStatus = AsyncStatus.idle;
  AsyncStatus _publishStatus = AsyncStatus.idle;
  PhotoAsset? _photo;
  String? _photoError;
  String? _publishError;
  String _category = 'Furniture';
  String _condition = 'Good';

  int get step => _step;
  AsyncStatus get photoStatus => _photoStatus;
  AsyncStatus get publishStatus => _publishStatus;
  PhotoAsset? get photo => _photo;
  String? get photoError => _photoError;
  String? get publishError => _publishError;
  String get category => _category;
  String get condition => _condition;
  bool get isTakingPhoto => _photoStatus == AsyncStatus.loading;
  bool get isPublishing => _publishStatus == AsyncStatus.loading;

  void updateCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void updateCondition(String value) {
    _condition = value;
    notifyListeners();
  }

  Future<void> takePhoto() async {
    _photoStatus = AsyncStatus.loading;
    _photoError = null;
    notifyListeners();
    try {
      _photo = await _photoRepository.captureForCategory(_category);
      _photoStatus = AsyncStatus.success;
    } on PhotoException catch (error) {
      _photoStatus = AsyncStatus.failure;
      _photoError = error.message;
    } catch (_) {
      _photoStatus = AsyncStatus.failure;
      _photoError = 'Photo service is unavailable right now.';
    }
    notifyListeners();
  }

  bool goToDetails() {
    _publishError = null;
    if (_photo == null) {
      _photoError = 'Add a photo before continuing.';
      notifyListeners();
      return false;
    }
    _step = 1;
    notifyListeners();
    return true;
  }

  void goToReview() {
    _publishError = null;
    _step = 2;
    notifyListeners();
  }

  void goBack() {
    if (_step == 0 || isPublishing) {
      return;
    }
    _step -= 1;
    notifyListeners();
  }

  Future<bool> publish({
    required String title,
    required String priceText,
    required String description,
    required String location,
    required UserProfile seller,
  }) async {
    final price = double.tryParse(priceText.trim());
    if (_photo == null || price == null) {
      _step = _photo == null ? 0 : 1;
      _photoError = _photo == null ? 'Add a photo before publishing.' : null;
      notifyListeners();
      return false;
    }

    _publishStatus = AsyncStatus.loading;
    _publishError = null;
    notifyListeners();
    try {
      await _marketplaceController.publishListing(
        input: SellListingInput(
          title: title.trim(),
          category: _category,
          price: price,
          condition: _condition,
          location: location.trim(),
          description: description.trim(),
          photo: _photo!,
        ),
        seller: seller,
      );
      reset();
      return true;
    } on ListingsException catch (error) {
      _publishStatus = AsyncStatus.failure;
      _publishError = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _publishStatus = AsyncStatus.failure;
      _publishError = 'Listing could not be published.';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _step = 0;
    _photoStatus = AsyncStatus.idle;
    _publishStatus = AsyncStatus.idle;
    _photo = null;
    _photoError = null;
    _publishError = null;
    _category = 'Furniture';
    _condition = 'Good';
    notifyListeners();
  }
}
