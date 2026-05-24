import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.brandBlue,
        border: Border.all(color: Colors.white, width: size * 0.07),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlueDeep.withValues(alpha: 0.16),
            blurRadius: size * 0.24,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.home_rounded, color: Colors.white, size: size * 0.58),
            Positioned(
              right: size * 0.1,
              bottom: size * 0.1,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.brandOrange,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: size * 0.25, height: size * 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
