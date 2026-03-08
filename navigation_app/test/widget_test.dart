// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hospital_nav_app/main.dart';

void main() {
  testWidgets('Proceed navigates to hospital search with popular list', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify we are on the welcome screen
    expect(find.text('Hospital Navigator'), findsOneWidget);
    expect(find.text('Proceed'), findsOneWidget);

    // Tap the Proceed button
    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    // Verify the search screen contents (dark tech themed UI)
    expect(find.byType(TextField), findsOneWidget); // search bar
    expect(find.text('Popular Hospitals'), findsOneWidget);
    expect(find.text('Find Hospital'), findsOneWidget); // header title

    // Select a popular hospital card (first one - Apollo Hospital)
    final apolloCard = find.text('Apollo Hospital');
    expect(apolloCard, findsOneWidget);
    await tester.tap(apolloCard);
    await tester.pump();

    // A SnackBar should appear indicating selection
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
