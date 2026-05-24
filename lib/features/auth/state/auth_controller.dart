import 'package:flutter/foundation.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/state/async_status.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AsyncStatus _status = AsyncStatus.idle;
  UserProfile? _profile;
  String? _errorMessage;

  AsyncStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _profile != null;
  bool get isBusy => _status == AsyncStatus.loading;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _profile = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      _status = AsyncStatus.success;
      _errorMessage = null;
    } on AuthException catch (error) {
      _status = AsyncStatus.failure;
      _errorMessage = error.message;
    } catch (_) {
      _status = AsyncStatus.failure;
      _errorMessage = 'Something went wrong while signing in.';
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _setLoading();
    try {
      _profile = await _repository.signInWithGoogle();
      _status = AsyncStatus.success;
      _errorMessage = null;
    } catch (_) {
      _status = AsyncStatus.failure;
      _errorMessage = 'Google sign-in is unavailable right now.';
    }
    notifyListeners();
  }

  void signOut() {
    _profile = null;
    _status = AsyncStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AsyncStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }
}
