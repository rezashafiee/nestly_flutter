import '../models/photo_asset.dart';

abstract final class PhotoAssets {
  static PhotoAsset forCategory(String category) {
    return switch (category) {
      'Electronics' => const PhotoAsset(
        iconKey: 'electronics',
        colorValue: 0xFFCDB4DB,
      ),
      'Home' => const PhotoAsset(iconKey: 'lamp', colorValue: 0xFFFFC6D9),
      'Sports' => const PhotoAsset(iconKey: 'bike', colorValue: 0xFFFFD6A5),
      'Clothing' => const PhotoAsset(
        iconKey: 'clothing',
        colorValue: 0xFFA0C4FF,
      ),
      _ => const PhotoAsset(iconKey: 'chair', colorValue: 0xFFB7E4C7),
    };
  }
}
