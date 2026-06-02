import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_router.dart';
import '../../../core/models/photo_asset.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/listing_photo.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/state/auth_controller.dart';
import '../../marketplace/state/marketplace_controller.dart';
import '../state/sell_controller.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController(text: 'Berlin');

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _locationController.text = 'Berlin';
  }

  Future<void> _continue(SellController sell) async {
    if (sell.step == 0) {
      sell.goToDetails();
      return;
    }
    if (sell.step == 1) {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return;
      }
      sell.goToReview();
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final profile = context.read<AuthController>().profile;
    if (profile == null) {
      return;
    }
    final published = await sell.publish(
      title: _titleController.text,
      priceText: _priceController.text,
      description: _descriptionController.text,
      location: _locationController.text,
      seller: profile,
    );
    if (!mounted || !published) {
      return;
    }
    final title = _titleController.text.trim();
    final marketplace = context.read<MarketplaceController>();
    _clearForm();
    context.go(AppRoutes.account);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          marketplace.hasPendingWrites
              ? '$title was saved locally and will publish when you refresh online.'
              : '$title is live for buyers.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sell = context.watch<SellController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        ResponsiveContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sell an item',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Capture a photo, add the details, and publish.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              StepProgress(currentStep: sell.step),
              const SizedBox(height: 22),
              if (sell.step == 0)
                PhotoStep(
                  sell: sell,
                  onTakePhoto: sell.takePhoto,
                  onChoosePhoto: sell.choosePhoto,
                ),
              if (sell.step == 1 || sell.step == 2)
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sell.step == 1)
                        DetailsStep(
                          titleController: _titleController,
                          priceController: _priceController,
                          descriptionController: _descriptionController,
                          locationController: _locationController,
                          sell: sell,
                        ),
                      if (sell.step == 2)
                        ReviewStep(
                          title: _titleController.text.trim(),
                          price: _priceController.text.trim(),
                          description: _descriptionController.text.trim(),
                          location: _locationController.text.trim(),
                          sell: sell,
                        ),
                    ],
                  ),
                ),
              if (sell.publishError != null) ...[
                const SizedBox(height: 16),
                ErrorBanner(message: sell.publishError!),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  if (sell.step > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: sell.isPublishing ? null : sell.goBack,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    ),
                  if (sell.step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (sell.isTakingPhoto || sell.isPublishing)
                          ? null
                          : () => _continue(sell),
                      icon: sell.isPublishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              sell.step == 2
                                  ? Icons.publish_outlined
                                  : Icons.arrow_forward,
                            ),
                      label: Text(
                        sell.step == 2 ? 'Publish listing' : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PhotoStep extends StatelessWidget {
  const PhotoStep({
    super.key,
    required this.sell,
    required this.onTakePhoto,
    required this.onChoosePhoto,
  });

  final SellController sell;
  final VoidCallback onTakePhoto;
  final VoidCallback onChoosePhoto;

  @override
  Widget build(BuildContext context) {
    final photo =
        sell.photo ??
        const PhotoAsset(iconKey: 'camera', colorValue: 0xFF8FD8F7);
    return DecoratedBox(
      decoration: panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: sell.isTakingPhoto
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : PhotoAssetView(photo: photo),
            ),
            if (sell.photoError != null) ...[
              const SizedBox(height: 12),
              Text(
                sell.photoError!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: sell.isTakingPhoto ? null : onTakePhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take photo'),
                ),
                OutlinedButton.icon(
                  onPressed: sell.isTakingPhoto ? null : onChoosePhoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose photo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsStep extends StatelessWidget {
  const DetailsStep({
    super.key,
    required this.titleController,
    required this.priceController,
    required this.descriptionController,
    required this.locationController,
    required this.sell,
  });

  final TextEditingController titleController;
  final TextEditingController priceController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final SellController sell;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 720;
            final categoryField = DropdownButtonFormField<String>(
              initialValue: sell.category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items:
                  const [
                        'Furniture',
                        'Electronics',
                        'Home',
                        'Sports',
                        'Clothing',
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: (value) => sell.updateCategory(value ?? 'Furniture'),
            );
            final conditionField = DropdownButtonFormField<String>(
              initialValue: sell.condition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                prefixIcon: Icon(Icons.verified_outlined),
              ),
              items: const ['New', 'Like new', 'Good']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => sell.updateCondition(value ?? 'Good'),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 4) {
                      return 'Use at least 4 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                if (twoColumns)
                  Row(
                    children: [
                      Expanded(child: categoryField),
                      const SizedBox(width: 14),
                      Expanded(child: conditionField),
                    ],
                  )
                else ...[
                  categoryField,
                  const SizedBox(height: 14),
                  conditionField,
                ],
                const SizedBox(height: 14),
                if (twoColumns)
                  Row(
                    children: [
                      Expanded(child: PriceField(controller: priceController)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: LocationField(controller: locationController),
                      ),
                    ],
                  )
                else ...[
                  PriceField(controller: priceController),
                  const SizedBox(height: 14),
                  LocationField(controller: locationController),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: descriptionController,
                  minLines: 4,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 12) {
                      return 'Add a few more details for buyers.';
                    }
                    return null;
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PriceField extends StatelessWidget {
  const PriceField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: const InputDecoration(
        labelText: 'Price',
        prefixIcon: Icon(Icons.euro),
      ),
      validator: (value) {
        final price = double.tryParse((value ?? '').trim());
        if (price == null || price <= 0) {
          return 'Enter a valid price.';
        }
        return null;
      },
    );
  }
}

class LocationField extends StatelessWidget {
  const LocationField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Pickup area',
        prefixIcon: Icon(Icons.place_outlined),
      ),
      validator: (value) {
        if ((value ?? '').trim().length < 2) {
          return 'Add a pickup area.';
        }
        return null;
      },
    );
  }
}

class ReviewStep extends StatelessWidget {
  const ReviewStep({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.location,
    required this.sell,
  });

  final String title;
  final String price;
  final String description;
  final String location;
  final SellController sell;

  @override
  Widget build(BuildContext context) {
    final photo =
        sell.photo ??
        const PhotoAsset(iconKey: 'camera', colorValue: 0xFF8FD8F7);
    return DecoratedBox(
      decoration: panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotoAssetView(photo: photo, height: 210),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatPrice(double.tryParse(price) ?? 0),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.brandOrange,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(icon: Icons.category_outlined, label: sell.category),
                StatusPill(
                  icon: Icons.verified_outlined,
                  label: sell.condition,
                ),
                StatusPill(icon: Icons.place_outlined, label: location),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.mutedInk,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Photo', 'Details', 'Review'];
    return DecoratedBox(
      decoration: panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              Expanded(
                child: Column(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= currentStep
                            ? AppColors.brandOrange
                            : const Color(0xFFEAF3F7),
                      ),
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Center(
                          child: Icon(
                            index < currentStep ? Icons.check : Icons.circle,
                            size: index < currentStep ? 18 : 8,
                            color: index <= currentStep
                                ? Colors.white
                                : AppColors.mutedInk,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: index <= currentStep
                            ? AppColors.ink
                            : AppColors.mutedInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < currentStep
                        ? AppColors.brandOrange
                        : AppColors.line,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
