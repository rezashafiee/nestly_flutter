import '../../../core/network/api_client.dart';
import '../../../core/models/user_profile.dart';

class AuthRepository {
  AuthRepository({NestlyApiClient? apiClient})
    : _apiClient = apiClient ?? NestlyApiClient();

  final NestlyApiClient _apiClient;

  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.postJson('/api/auth/email', {
        'email': email,
        'password': password,
      });
      return UserProfile.fromJson(asJsonMap(response));
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      throw const AuthException('Something went wrong while signing in.');
    }
  }

  Future<UserProfile> signInWithGoogle() async {
    try {
      final response = await _apiClient.postJson('/api/auth/google', {
        'name': 'Google User',
        'email': 'google.user@nestly.app',
      });
      return UserProfile.fromJson(asJsonMap(response));
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      throw const AuthException('Google sign-in is unavailable right now.');
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
