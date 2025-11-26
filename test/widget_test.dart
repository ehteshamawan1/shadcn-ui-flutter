// SKA-DAN Flutter widget tests
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ska_dan_flutter/main.dart';
import 'package:ska_dan_flutter/services/database_service.dart';

void main() {
  // Setup test environment
  setUpAll(() async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    await DatabaseService().init();
  });

  testWidgets('SKA-DAN app loads and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SkaDanApp());
    await tester.pumpAndSettle();

    // Verify that login screen elements are present
    expect(find.text('SKA-DAN'), findsWidgets);
    expect(find.text('Indtast din 4-cifrede kode'), findsOneWidget);
    expect(find.text('Adgangskode'), findsOneWidget);
  });

  testWidgets('Login screen shows number pad', (WidgetTester tester) async {
    await tester.pumpWidget(const SkaDanApp());
    await tester.pumpAndSettle();

    // Verify number pad buttons exist
    for (int i = 0; i <= 9; i++) {
      expect(find.text(i.toString()), findsWidgets);
    }

    // Verify action buttons
    expect(find.text('Ryd'), findsOneWidget);
    expect(find.text('Log ind'), findsOneWidget);
  });
}
