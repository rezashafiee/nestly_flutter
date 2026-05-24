import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/main.dart';

import 'fakes.dart';

void main() {
  testWidgets('Nestly shows auth validation and marketplace after sign in', (
    tester,
  ) async {
    await tester.pumpWidget(
      NestlyApp(
        authRepository: FakeAuthRepository(),
        listingsRepository: FakeListingsRepository(),
        chatRepository: FakeChatRepository(),
        photoRepository: FakePhotoRepository(),
      ),
    );

    expect(find.text('Nestly'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('emailSignInButton')));
    await tester.pump();

    expect(find.text('Please enter a valid email.'), findsOneWidget);
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('emailField')),
      'sara@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('passwordField')),
      'secure1',
    );
    await tester.tap(find.byKey(const ValueKey('emailSignInButton')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Browse marketplace'), findsOneWidget);
    expect(find.text('Vintage oak desk'), findsOneWidget);
    expect(find.text('City bike with basket'), findsOneWidget);
  });
}
