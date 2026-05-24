import '../../../core/models/photo_asset.dart';
import '../../../core/network/api_client.dart';

class PhotoRepository {
  PhotoRepository({NestlyApiClient? apiClient})
    : _apiClient = apiClient ?? NestlyApiClient();

  final NestlyApiClient _apiClient;

  Future<PhotoAsset> captureForCategory(String category) async {
    try {
      final response = await _apiClient.getJson(
        '/api/photos/default',
        queryParameters: {'category': category},
      );
      return PhotoAsset.fromJson(asJsonMap(response));
    } on ApiException catch (error) {
      throw PhotoException(error.message);
    } catch (_) {
      throw const PhotoException('Photo service is unavailable right now.');
    }
  }
}

class PhotoException implements Exception {
  const PhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}
