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
    final imageBytes = photo.imageBytes;
    return Container(
      decoration: BoxDecoration(
        color: Color(photo.colorValue).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = _shortestFiniteSide(constraints);
            final iconSize = shortestSide == null
                ? 64.0
                : (shortestSide * 0.44).clamp(24.0, 72.0);
            final showCategory =
                category != null &&
                constraints.maxWidth >= 150 &&
                constraints.maxHeight >= 110;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (imageBytes == null)
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      iconForPhoto(photo.iconKey),
                      color: AppColors.brandBlueDeep,
                      size: iconSize,
                    ),
                  )
                else
                  Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => Align(
                      alignment: Alignment.center,
                      child: Icon(
                        iconForPhoto(photo.iconKey),
                        color: AppColors.brandBlueDeep,
                        size: iconSize,
                      ),
                    ),
                  ),
                if (showCategory)
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
            );
          },
        ),
      ),
    );
  }
}

double? _shortestFiniteSide(BoxConstraints constraints) {
  final sides = [
    constraints.maxWidth,
    constraints.maxHeight,
  ].where((side) => side.isFinite && side > 0);
  if (sides.isEmpty) {
    return null;
  }
  return sides.reduce((value, side) => value < side ? value : side);
}

IconData iconForPhoto(String key) {
  return switch (key) {
    'camera' => Icons.add_a_photo_outlined,
    'gallery' => Icons.photo_library_outlined,
    'desk' => Icons.desk,
    'bike' => Icons.directions_bike,
    'lamp' => Icons.light,
    'electronics' => Icons.devices_other,
    'headphones' => Icons.headphones,
    'clothing' => Icons.checkroom,
    _ => Icons.chair,
  };
}
