import '../../../core/network/api_client.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/offline/offline_json_store.dart';

class AuthRepository {
  AuthRepository({NestlyApiClient? apiClient, OfflineJsonStore? offlineStore})
    : _apiClient = apiClient ?? NestlyApiClient(),
      _offlineStore = offlineStore ?? OfflineJsonStore();

  static const _profileKey = 'auth.profile';

  final NestlyApiClient _apiClient;
  final OfflineJsonStore _offlineStore;

  Future<UserProfile?> restoreProfile() async {
    final json = await _offlineStore.readMap(_profileKey);
    if (json == null) {
      return null;
    }
    return UserProfile.fromJson(json);
  }

  Future<void> forgetProfile() async {
    await _offlineStore.remove(_profileKey);
  }

  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    try {
      final response = await _apiClient.postJson('/api/auth/email', {
        'email': cleanEmail,
        'password': password,
      });
      final profile = UserProfile.fromJson(asJsonMap(response));
      await _cacheProfile(profile);
      return profile;
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      final cached = await restoreProfile();
      if (cached != null &&
          cached.email.toLowerCase() == cleanEmail.toLowerCase()) {
        return cached;
      }
      final offlineProfile = UserProfile(
        name: _nameFromEmail(cleanEmail),
        email: cleanEmail,
      );
      await _cacheProfile(offlineProfile);
      return offlineProfile;
    }
  }

  Future<UserProfile> signInWithGoogle() async {
    try {
      final response = await _apiClient.postJson('/api/auth/google', {
        'name': 'Google User',
        'email': 'google.user@nestly.app',
      });
      final profile = UserProfile.fromJson(asJsonMap(response));
      await _cacheProfile(profile);
      return profile;
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      final cached = await restoreProfile();
      if (cached != null) {
        return cached;
      }
      const offlineProfile = UserProfile(
        name: 'Google User',
        email: 'google.user@nestly.app',
      );
      await _cacheProfile(offlineProfile);
      return offlineProfile;
    }
  }

  Future<void> _cacheProfile(UserProfile profile) async {
    await _offlineStore.writeMap(_profileKey, profile.toJson());
  }

  String _nameFromEmail(String email) {
    final name = email.split('@').first.replaceAll('.', ' ').trim();
    if (name.isEmpty) {
      return 'Nestly User';
    }
    return name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
