// Basic Flutter widget test for Fitness Tracker app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget test', (WidgetTester tester) async {
    // Build a simple test widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Test App'),
        ),
      ),
    );

    // Verify that the test widget loads
    expect(find.text('Test App'), findsOneWidget);
  });
}
