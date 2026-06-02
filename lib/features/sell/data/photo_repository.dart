import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/photo_assets.dart';
import '../../../core/models/photo_asset.dart';

class PhotoRepository {
  PhotoRepository({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<PhotoAsset?> captureForCategory(String category) {
    return _pickPhoto(category: category, source: ImageSource.camera);
  }

  Future<PhotoAsset?> chooseForCategory(String category) {
    return _pickPhoto(category: category, source: ImageSource.gallery);
  }

  Future<PhotoAsset?> _pickPhoto({
    required String category,
    required ImageSource source,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (pickedFile == null) {
        return null;
      }
      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        throw const PhotoException('Selected photo could not be read.');
      }

      final fallback = PhotoAssets.forCategory(category);
      return PhotoAsset(
        iconKey: source == ImageSource.camera ? 'camera' : 'gallery',
        colorValue: fallback.colorValue,
        imageData: base64Encode(bytes),
      );
    } on PlatformException catch (error) {
      throw PhotoException(_platformMessage(source, error));
    } on PhotoException {
      rethrow;
    } catch (_) {
      throw PhotoException(_unavailableMessage(source));
    }
  }

  String _platformMessage(ImageSource source, PlatformException error) {
    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return _unavailableMessage(source);
  }

  String _unavailableMessage(ImageSource source) {
    return source == ImageSource.camera
        ? 'Camera is unavailable right now.'
        : 'Photo gallery is unavailable right now.';
  }
}

class PhotoException implements Exception {
  const PhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}
