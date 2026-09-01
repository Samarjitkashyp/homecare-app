// Basic smoke test: the app builds and shows the login screen without errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homecare_app/main.dart';

void main() {
  testWidgets('App builds and renders MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // First frame: providers load asynchronously; just verify the app shell.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
