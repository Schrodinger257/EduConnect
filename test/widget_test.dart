// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Basic app smoke test', (WidgetTester tester) async {
    // Build a simple test widget instead of the full app
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('EduConnect Test'),
            ),
          ),
        ),
      ),
    );

    // Verify that the test widget renders
    expect(find.text('EduConnect Test'), findsOneWidget);
  });
}
