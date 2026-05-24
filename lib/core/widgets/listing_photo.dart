import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../models/photo_asset.dart';
import '../theme/app_colors.dart';

class ListingPhoto extends StatelessWidget {
  const ListingPhoto({super.key, required this.listing, this.height});

  final Listing listing;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return PhotoAssetView(
      photo: listing.photo,
      category: listing.category,
      height: height,
    );
  }
}

class PhotoAssetView extends StatelessWidget {
  const PhotoAssetView({
    super.key,
    required this.photo,
    this.category,
    this.height,
  });

  final PhotoAsset photo;
  final String? category;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(photo.colorValue).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.center,
              child: Icon(
                iconForPhoto(photo.iconKey),
                color: AppColors.brandBlueDeep,
                size: 64,
              ),
            ),
            if (category != null)
              Positioned(
                left: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      category!,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

IconData iconForPhoto(String key) {
  return switch (key) {
    'camera' => Icons.add_a_photo_outlined,
    'desk' => Icons.desk,
    'bike' => Icons.directions_bike,
    'lamp' => Icons.light,
    'electronics' => Icons.devices_other,
    'headphones' => Icons.headphones,
    'clothing' => Icons.checkroom,
    _ => Icons.chair,
  };
}
