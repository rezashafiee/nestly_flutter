import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/core/models/photo_asset.dart';
import 'package:nestly/core/widgets/listing_photo.dart';

void main() {
  const photo = PhotoAsset(iconKey: 'chair', colorValue: 0xFFB7E4C7);

  testWidgets('photo asset view scales icons and hides tiny badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 58,
            height: 58,
            child: PhotoAssetView(photo: photo, category: 'Furniture'),
          ),
        ),
      ),
    );

    expect(find.text('Furniture'), findsNothing);
    final compactIcon = tester.widget<Icon>(find.byIcon(Icons.chair));
    expect(compactIcon.size, closeTo(25.52, 0.01));

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 120,
            child: PhotoAssetView(photo: photo, category: 'Furniture'),
          ),
        ),
      ),
    );

    expect(find.text('Furniture'), findsOneWidget);
    final largeIcon = tester.widget<Icon>(find.byIcon(Icons.chair));
    expect(largeIcon.size, closeTo(52.8, 0.01));
  });
}
